import json
from typing import List

from pydantic import BaseModel, BaseSettings, validator


class Settings(BaseSettings):
    """Global Config."""

    environment: str = "local"

    sentry_dsn: str = ""
    sentry_traces_sample_rate: float = 0.1


class BaseModelExtra(BaseModel):
    """BaseModel with extra fields."""

    class Config:
        """Config for BaseModel with extra fields."""

        extra = "allow"


class SNSMessage(BaseModel):
    """SNS Message."""

    status: int = 200
    subject: str
    data: dict = {}


class SNSError(SNSMessage):
    """SNS Error."""

    status: int = 500
    subject: str = "ERROR"
    detail: str
    error: str
    path: str


class ConversionCompleted(BaseModel):
    """Conversion Completed."""

    status: int = 200
    id: str
    input_file: str
    output_file: str
    path_elements: List[str]


class APIRequest(BaseModel):
    """BaseModel without extra fields."""

    class Config:
        """Config for BaseModel without extra fields."""

        extra = "forbid"


class APIResponse(APIRequest):
    """Represents an API response."""

    statusCode: int = 200
    body: str
    headers: dict = {}

    @validator("body", pre=True, always=True)
    def set_body_json(cls, value):
        """Set the timestamp to now if not provided."""
        if isinstance(value, str):
            value = {"message": value}
        return json.dumps(value, default=str)


class JobStatus(SNSMessage):
    """Job Status."""

    id: str
    output_file: str
    input_file: str
    path_elements: list
