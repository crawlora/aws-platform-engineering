import ast
import base64
import json
import subprocess
import sys
import urllib.parse
from pathlib import Path
from typing import List, Union

import boto3
import sentry_sdk
import tenacity
from pydantic import validate_arguments
from sentry_sdk.integrations.aws_lambda import AwsLambdaIntegration

root_folder = Path(__file__).parent.absolute()
sys.path.insert(0, root_folder.as_posix())


from errors import (
    MediaInfoException,
    NoEventBodyException,
    UnsupportedExtensionException,
    UnsupportedFileException,
)
from models import Settings, SNSError, SNSMessage

sentry = sentry_sdk.init(
    dsn=Settings().sentry_dsn,
    integrations=[
        AwsLambdaIntegration(),
    ],
    traces_sample_rate=Settings().sentry_traces_sample_rate,
    environment=Settings().environment,
)

mediainfo_retry = tenacity.retry(
    stop=tenacity.stop_after_attempt(5),
    wait=tenacity.wait_fixed(3),
    retry=tenacity.retry_if_exception_type(MediaInfoException),
    reraise=True,
)


@validate_arguments
def send_sns(topic: str, message: SNSMessage):
    """Send an SNS notification."""
    print(f"Sending SNS notification: {message.json()}")
    sns = boto3.client("sns")

    try:
        sns.publish(
            TargetArn=topic,
            Message=message.json(),
            Subject=message.subject,
        )
    except Exception as error:
        raise Exception(f"Error sending SNS notification: {str(error)}")


@validate_arguments
def send_exception(topic: str, log_group_name: str, err: str, path: Union[str, Path]):
    """Send an SNS notification with the error details."""
    message = SNSError(
        detail=f"https://console.aws.amazon.com/cloudwatch/home?region={boto3.Session().region_name}#logStream:group={log_group_name}",
        error=str(err),
        path=str(path),
    )
    send_sns(topic, message)


@validate_arguments
def get_json_from_s3(bucket: str, key: str) -> dict:
    print(f"Downloading file: {key}, from S3: {bucket}")
    s3 = boto3.client("s3")

    try:
        response = s3.get_object(Bucket=bucket, Key=key)
        obj = json.loads(response["Body"].read().decode("utf-8"))
    except Exception as err:
        raise Exception(
            f"Failed to download and validate the json file. Please check its contents and location. Error: {str(err)}"
        )

    return obj


@validate_arguments
def presign_url(bucket: str, key: str, expires_in=7200) -> str:
    """Generate a presigned URL to share an S3 object.

    :param bucket: string
    :param key: string
    :param expires_in: int
    :return: string

    """
    s3 = boto3.client("s3")
    url = s3.generate_presigned_url(
        ClientMethod="get_object",
        Params={"Bucket": bucket, "Key": key},
        ExpiresIn=expires_in,
        HttpMethod="GET",
    )
    return url


def decode_base_64_event_body(event: dict) -> dict:
    """Decode the base64 encoded event body."""
    if event.get("isBase64Encoded", False):
        event["body"] = base64.b64decode(event["body"]).decode("utf-8")


def assert_event_has_body(event: dict) -> bool:
    """Assert that the event has a body."""
    if "body" not in event:
        raise NoEventBodyException("event.body is not defined")
    return True


def preprocess_api_event(event: dict) -> dict:
    """Preprocess the API event."""
    print(f"REQUEST:: {event}")
    assert_event_has_body(event)
    decode_base_64_event_body(event)

    event["body"] = ast.literal_eval(event["body"])
    return event


def verify_path_is_valid(path: str, extensions: List[str] = None) -> bool:
    """Verify that the path is a file."""
    suffix = Path(path).suffix
    if not suffix:
        raise UnsupportedFileException(f"Invalid file path: {path}")
    if extensions:
        if not suffix.lower() in extensions:
            raise UnsupportedExtensionException(f"Invalid file extension: {path}")
    return True


def retrive_sources_from_s3(event: dict) -> tuple:
    """Retrieve the source bucket and key from the event."""
    path = Path(urllib.parse.unquote_plus(event["Records"][0]["s3"]["object"]["key"]))
    bucket = Path(
        urllib.parse.unquote_plus(event["Records"][0]["s3"]["bucket"]["name"])
    )
    return bucket, path


def s3_url_to_bucket_and_key(s3_url: str) -> tuple:
    """Convert an S3 URL to a bucket and key."""
    bucket = s3_url.replace("s3://", "").split("/")[0]
    key = s3_url.replace("s3://", "").replace(bucket, "").lstrip("/")
    return bucket, key


def convert_s3_event_to_sns_event(dict) -> dict:
    """Convert an S3 event to an SNS event."""
    return {
        "Records": [
            {
                "Sns": {
                    "Message": json.dumps(dict),
                },
            }
        ]
    }


def convert_sns_event_to_s3_event(dict) -> dict:
    """Convert an SNS event to an S3 event."""
    return json.loads(dict["Records"][0]["Sns"]["Message"])


@mediainfo_retry
def run_mediainfo(url: str) -> dict:
    """Run mediainfo on a file and return the output as a dict."""
    cmd = [
        "mediainfo",
        "--full",
        "--output=JSON",
        url,
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise MediaInfoException(f"mediainfo failed: {result.stderr}")
    return json.loads(str(result.stdout))


@validate_arguments
def get_media_info_from_s3_url(s3_url: str) -> Union[dict, None]:
    """Get media info from an S3 URL."""
    src_bucket, src_file = s3_url_to_bucket_and_key(s3_url)

    presigned_url = presign_url(str(src_bucket), str(src_file))

    print(f"PRE-SIGNED URL:: {presigned_url}")

    info = run_mediainfo(presigned_url)

    print(f"INFO:: {info}")

    if info["media"] is None:
        return None
    return info["media"]["track"][0]  # general information


@validate_arguments
def get_content_type_from_s3_url(s3_url: str) -> str:
    """Get content type from an S3 URL."""
    info = get_media_info_from_s3_url(s3_url)
    if info is None:
        return "binary/octet-stream"
    if info.get("FileExtension") == "svg":
        return "image/svg+xml"
    if info.get("FileExtension") == "webp":
        return "image/webp"
    return info["InternetMediaType"]


def copy(s3_url: str, target_bucket: str = None):
    """Sets the S3 Content type."""
    bucket, key = s3_url_to_bucket_and_key(s3_url)
    content_type = get_content_type_from_s3_url(s3_url)

    if target_bucket is None:
        # Does an inplace copy to set the content type
        target_bucket = bucket

    s3 = boto3.client("s3")
    s3.copy_object(
        Key=str(key),
        Bucket=target_bucket,
        CopySource={"Bucket": str(bucket), "Key": str(key)},
        ContentType=content_type,
        Metadata={"Content-Type": content_type},
        MetadataDirective="REPLACE",
    )


def delete_s3_object(s3_url: str):
    """Delete an object from S3."""
    bucket, key = s3_url_to_bucket_and_key(s3_url)
    s3 = boto3.client("s3")
    s3.delete_object(Bucket=bucket, Key=key)
