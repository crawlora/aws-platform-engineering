import sys
from pathlib import Path
from typing import List

import boto3
from botocore.exceptions import ClientError

root_folder = Path(__file__).parent.absolute()
sys.path.insert(0, root_folder.as_posix())

import utils
from errors import UnsupportedPayloadException, UnsupportedTypeException
from models import APIRequest, APIResponse
from models import Settings as BaseSettings
from pydantic import ValidationError, constr


class LambdaSettings(BaseSettings):
    """Lambda Settings."""

    bucket_name: str
    input_file_suffixes: List[str]


class Request(APIRequest):
    """API Request Payload."""

    path: constr(min_length=1, max_length=512)


def handler(event, context):
    """Lambda handler function initialize multipart upload."""
    print(event)
    lst = LambdaSettings()
    try:
        utils.preprocess_api_event(event)
        event = Request.parse_obj(event["body"])
        utils.verify_path_is_valid(event.path, extensions=lst.input_file_suffixes)
    except (
        UnsupportedPayloadException,
        UnsupportedTypeException,
        ValidationError,
    ) as err:
        print(f"Payload validation error: {err}")
        return APIResponse(statusCode=400, body=str(err)).dict()

    s3_client = boto3.client("s3")
    multipart_params = {
        "Bucket": lst.bucket_name,
        "Key": event.path,
    }
    try:
        multipart_upload = s3_client.create_multipart_upload(**multipart_params)

        return APIResponse(
            body={
                "file_id": multipart_upload["UploadId"],
                "path": multipart_upload["Key"],
            },
            headers={
                "Access-Control-Allow-Origin": "*",
            },
        ).dict()
    except (ClientError, Exception) as e:
        print(e)
        raise e  # Rethrowing the exception to be handled by AWS Lambda
