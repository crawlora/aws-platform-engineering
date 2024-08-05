import sys
from pathlib import Path
from typing import List

from pydantic import ValidationError, constr

root_folder = Path(__file__).parent.absolute()
sys.path.insert(0, root_folder.as_posix())

import utils
from errors import UnsupportedPayloadException, UnsupportedTypeException
from models import APIRequest, APIResponse
from models import Settings as BaseSettings


class LambdaSettings(BaseSettings):
    """Lambda Settings."""

    input_file_suffixes: List[str]


class Request(APIRequest):
    """API Request."""

    path: constr(min_length=1, max_length=512)


def handler(event, context):
    """Lambda handler function to get file infos."""

    print(f"REQUEST:: {event}")

    lst = LambdaSettings()

    try:
        utils.preprocess_api_event(event)
        event = Request.parse_obj(event["body"])

        if not event.path.startswith("s3://"):
            raise UnsupportedPayloadException(f"Not an S3 file path: {event.path}")
        utils.verify_path_is_valid(event.path, extensions=lst.input_file_suffixes)
    except (
        UnsupportedPayloadException,
        UnsupportedTypeException,
        ValidationError,
    ) as err:
        print(f"Payload validation error: {err}")
        return APIResponse(statusCode=400, body=str(err)).dict()

    try:
        info = utils.get_media_info_from_s3_url(event.path)

        if info is None:
            return APIResponse(
                statusCode=500, body="No media information found."
            ).dict()

        return APIResponse(
            body={
                "filename": info["FileName"],
                "file_extension": info["FileExtension"],
                "filname_extension": info["FileNameExtension"],
                "content-type": info["InternetMediaType"],
                "file_size": info["FileSize_String"],
                "duration_seconds": float(info["Duration"]),
                "format": info["Format"],
            },
            headers={
                "Access-Control-Allow-Origin": "*",
            },
        ).dict()

    except Exception as e:
        print(e)
        raise e
