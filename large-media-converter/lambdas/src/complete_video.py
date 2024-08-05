import os
import sys
from pathlib import Path

import boto3
from botocore.exceptions import ClientError
from PIL import Image

root_folder = Path(__file__).parent.absolute()
sys.path.insert(0, root_folder.as_posix())

import utils
from errors import ElementalConvertException
from models import JobStatus
from models import Settings as BaseSettings


class LambdaSettings(BaseSettings):
    """Lambda Settings."""

    mediaconvert_endpoint: str
    sns_topic_arn: str


def create_thumbnail_and_upload_to_s3(s3_url: str):
    """Create a thumbnail and upload to S3."""
    bucket, key = utils.s3_url_to_bucket_and_key(s3_url)
    conv_thumb_key = Path(key).with_suffix(
        ".0000000.jpg"
    )  # Default mediaconvert behavior
    final_thum_key = Path(key).with_suffix(".png")

    # download jpg from elemental
    s3 = boto3.client("s3")
    s3.download_file(bucket, conv_thumb_key.as_posix(), "/tmp/thumbnail.jpg")

    # convert jpg to png
    Image.open("/tmp/thumbnail.jpg").save("/tmp/thumbnail.png")

    s3.upload_file(
        "/tmp/thumbnail.png",
        bucket,
        str(final_thum_key),
        ExtraArgs={
            "ContentType": "image/png",
            "Metadata": {"Content-Type": "image/png"},
        },
    )
    print(f"Thumbnail uploaded to s3://{bucket}/{final_thum_key}")


def summarize_job_details(endpoint, data):
    try:
        mediaconvert_client = boto3.client("mediaconvert", endpoint_url=endpoint)
        job_data = mediaconvert_client.get_job(Id=data["detail"]["jobId"])
        input_file = job_data["Job"]["Settings"]["Inputs"][0]["FileInput"]
        path_elements = input_file.replace("s3://", "").split("/")

        job_details = {
            "Id": data["detail"]["jobId"],
            "Job": job_data["Job"],
            "InputFile": input_file,
            "PathElements": path_elements,
        }

        if "outputGroupDetails" in data["detail"]:
            job_details["OutputGroupDetails"] = data["detail"]["outputGroupDetails"]
            job_details["OutputFile"] = data["detail"]["outputGroupDetails"][0][
                "outputDetails"
            ][0]["outputFilePaths"][0]
        else:
            job_details["OutputFile"] = ""
        return job_details
    except ClientError as error:
        raise Exception(f"Error processing job details: {error}")


def send_sns(topic, status, data):
    try:
        msg = JobStatus(
            id=data["Id"],
            output_file=data["OutputFile"],
            input_file=data["InputFile"],
            path_elements=data["PathElements"],
            subject=status,
            data=data,
        )
        utils.send_sns(topic, msg)
    except ClientError as error:
        raise Exception(f"Error sending SNS notification: {error}")


def handler(event, context):
    """Lambda handler triggered by MediaConvert job status updates."""

    print(f"REQUEST:: {event}")
    lst = LambdaSettings()
    job_details = summarize_job_details(lst.mediaconvert_endpoint, event)
    _, src_file = utils.s3_url_to_bucket_and_key(job_details["InputFile"])
    log_group = context.log_group_name if context else "unknown"

    try:
        status = event["detail"]["status"]
        if status in ["INPUT_INFORMATION", "PROGRESSING"]:
            print(f"Ignoring status: {status}")
            return
        elif status == "COMPLETE":
            if job_details["OutputFile"] == "":
                raise ElementalConvertException(
                    f"Job completed without an output file: {job_details['Id']}"
                )
            utils.copy(job_details["OutputFile"])  # inplace to set content-type
            create_thumbnail_and_upload_to_s3(job_details["OutputFile"])
            send_sns(lst.sns_topic_arn, status, job_details)
        elif status in ["CANCELED", "ERROR"]:
            raise ElementalConvertException(
                f"https://console.aws.amazon.com/mediaconvert/home?region={os.environ.get('AWS_REGION')}#/jobs/summary/{event['detail']['jobId']}"
            )
        else:
            raise Exception("Unknown job status")
    except ElementalConvertException as err:
        utils.send_exception(lst.sns_topic_arn, log_group, str(err), path=src_file)
    except Exception as err:
        utils.send_exception(lst.sns_topic_arn, log_group, str(err), path=src_file)
        raise err
