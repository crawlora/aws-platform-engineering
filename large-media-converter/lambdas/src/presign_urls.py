import sys
from pathlib import Path
from typing import List

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError
from pydantic import ValidationError, conint, constr

root_folder = Path(__file__).parent.absolute()
sys.path.insert(0, root_folder.as_posix())

import utils
from errors import UnsupportedPayloadException, UnsupportedTypeException
from models import APIRequest, APIResponse
from models import Settings as BaseSettings


class LambdaSettings(BaseSettings):
    """Lambda Settings."""

    bucket_name: str
    input_file_suffixes: List[str]
    url_expires: int = 3600


class Request(APIRequest):
    """API Request."""

    path: constr(min_length=1, max_length=512)
    file_id: constr(min_length=1, max_length=1024)
    parts: conint(ge=1)


def make_pre_signed_urls(bucket_name: str, url_expiration: int, body: Request):
    s3 = boto3.client("s3", config=Config(s3={"use_accelerate_endpoint": True}))

    try:
        signed_urls = []

        for index in range(body.parts):
            params = {
                "Bucket": bucket_name,
                "Key": body.path,
                "UploadId": body.file_id,
                "PartNumber": index + 1,
            }
            signed_url = s3.generate_presigned_url(
                "upload_part", Params=params, ExpiresIn=int(url_expiration)
            )
            # Switching naming style for compatible with complete_multipart_upload
            signed_urls.append({"signedUrl": signed_url, "PartNumber": index + 1})

        return signed_urls
    except Exception as e:
        print(f"Error generating pre-signed URLs: {str(e)}")
        raise


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

    try:
        part_signed_url_list = make_pre_signed_urls(
            lst.bucket_name, lst.url_expires, event
        )

        return APIResponse(
            body={"parts": part_signed_url_list},
            headers={
                "Access-Control-Allow-Origin": "*",
            },
        ).dict()
    except (ClientError, Exception) as e:
        print(e)
        raise e
