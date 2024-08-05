import sys
from pathlib import Path
from typing import List

import boto3
from botocore.exceptions import ClientError
from pydantic import ValidationError, conlist, constr

root_folder = Path(__file__).parent.absolute()
sys.path.insert(0, root_folder.as_posix())

import utils
from errors import UnsupportedPayloadException, UnsupportedTypeException
from models import APIRequest, APIResponse, BaseModelExtra
from models import Settings as BaseSettings


class LambdaSettings(BaseSettings):
    """Lambda Settings."""

    bucket_name: str
    input_file_suffixes: List[str]


class Part(BaseModelExtra):
    """Part."""

    PartNumber: int
    ETag: str


class Request(APIRequest):
    """API Request."""

    path: constr(min_length=1, max_length=512)
    file_id: constr(min_length=1, max_length=1024)
    parts: conlist(Part, min_items=1)


def handler(event, context):
    """Lambda handler function finalize multipart upload."""
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

    # Sorting parts based on PartNumber
    sorted_parts = sorted(event.parts, key=lambda x: x.PartNumber)

    multipart_params = {
        "Bucket": lst.bucket_name,
        "Key": event.path,
        "UploadId": event.file_id,
        "MultipartUpload": {"Parts": [part.dict() for part in sorted_parts]},
    }

    try:
        s3 = boto3.client("s3")
        s3.complete_multipart_upload(**multipart_params)
        return APIResponse(
            body={"message": True},
            headers={
                "Access-Control-Allow-Origin": "*",
            },
        ).dict()
    except (ClientError, Exception) as e:
        print(e)
        raise e
