"""This lambda is only used by the AWS API Gateway to authorize requests."""

import sys
from pathlib import Path

root_folder = Path(__file__).parent.absolute()
sys.path.insert(0, root_folder.as_posix())

from errors import UnsupportedPayloadException
from models import APIResponse, BaseModelExtra
from models import Settings as BaseSettings
from pydantic import ValidationError


class LambdaSettings(BaseSettings):
    """Lambda Settings."""

    auth_token: str
    auth_header: str = "authorization"


class Request(BaseModelExtra):
    """API Request."""

    headers: dict


def handler(event, context):
    """Lambda handler function initialize multipart upload."""
    print(event)
    lst = LambdaSettings()
    try:
        event = Request.parse_obj(event)
    except (
        UnsupportedPayloadException,
        ValidationError,
    ) as err:
        print(f"Payload validation error: {err}")
        return APIResponse(statusCode=400, body=str(err)).dict()

    headers = {k.lower(): v for k, v in event.headers.items()}

    return {
        "isAuthorized": headers.get(lst.auth_header.lower(), None) == lst.auth_token,
        "context": {},
    }
