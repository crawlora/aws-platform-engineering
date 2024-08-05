import json
import subprocess
import sys
from pathlib import Path
from typing import List
from uuid import uuid4

import boto3
import tenacity
from pydantic import validate_arguments, validator

root_folder = Path(__file__).parent.absolute()
sys.path.insert(0, root_folder.as_posix())

import utils
from errors import FFProbeException, InputFormatException, UnsupportedExtensionException
from models import BaseModelExtra
from models import Settings as BaseSettings

ffprobe_retry = tenacity.retry(
    stop=tenacity.stop_after_attempt(5),
    wait=tenacity.wait_fixed(3),
    retry=tenacity.retry_if_exception_type(FFProbeException),
    reraise=True,
)


class LambdaSettings(BaseSettings):
    """Lambda Settings."""

    mediaconvert_endpoint: str
    mediaconvert_role: str

    config_bucket: str
    job_config: str

    destination_bucket: str
    sns_topic_arn: str

    max_width: int
    max_height: int
    input_file_suffixes: List[str]


class JobSettings(BaseModelExtra):
    """Job Settings."""

    TimecodeConfig: dict
    Inputs: List[dict] = []
    OutputGroups: List[dict] = []

    @validator("Inputs", "OutputGroups", always=True)
    def at_least_one_element(cls, v):
        """Validate that there is at least one element."""
        if len(v) == 0:
            raise ValueError("Must have at least one element")
        return v


class Job(BaseModelExtra):
    """Job Settings."""

    Role: str = ""
    Priority: int = 0

    AccelerationSettings: dict
    Settings: JobSettings
    UserMetadata: dict = {}


@validate_arguments
def get_default_convert_job(bucket: str, settings_file: str) -> Job:
    """Download and validate the job-settings.json file."""
    job = utils.get_json_from_s3(bucket, settings_file)
    job = Job.parse_obj(job)
    return job


@validate_arguments
def update_job_settings(
    job: Job, input_path: str, output_path: str, metadata: dict, role: str
) -> Job:
    print("Updating Job Settings with the source and destination details")
    settings = job.Settings

    try:
        settings.Inputs[0]["FileInput"] = input_path
        for group in settings.OutputGroups:
            group_type = group["OutputGroupSettings"]["Type"]

            if group_type == "FILE_GROUP_SETTINGS":
                group["OutputGroupSettings"]["FileGroupSettings"]["Destination"] = (
                    output_path + "/"
                )
        job.Role = role
        job.UserMetadata = metadata

    except Exception as err:
        raise Exception(
            f"Failed to update the job-settings.json file. Error: {str(err)}"
        )

    return job


@validate_arguments
def submit_job(job: Job, endpoint: str):
    mediaconvert = boto3.client("mediaconvert", endpoint_url=endpoint)
    try:
        mediaconvert.create_job(**job.dict())
        print(f"Job submitted to MediaConvert!")
    except Exception as err:
        raise Exception(f"Error submitting job to MediaConvert: {str(err)}")


@validate_arguments
def set_max_width_height(
    job: Job, width: int, height: int, max_width: int, max_height: int
) -> Job:
    """Sets the longest side of the output to the max_width or max_height,
    whichever is smaller."""
    out = job.Settings.OutputGroups[0]["Outputs"][0]["VideoDescription"]

    if width > height:
        out["Width"] = width
        if width > max_width:
            out["Width"] = max_width
            print(f"Setting width to {max_width}")
    else:
        out["Height"] = height
        if height > max_height:
            out["Height"] = max_height
            print(f"Setting height to {max_height}")
    return job


@validate_arguments
def get_width_height(probe: dict) -> tuple:
    """Retrieve the width and height from the ffprobe output."""
    width = height = None
    for stream in probe["streams"]:
        if stream["codec_type"] == "video":
            width = stream["width"]
            height = stream["height"]
            break
    return width, height


@ffprobe_retry
def ffprobe(url: str) -> dict:
    """Run ffprobe on a file and return the output as a dict."""
    cmd = [
        "ffprobe",
        "-v",
        "error",
        "-print_format",
        "json",
        "-show_format",
        "-show_streams",
        "-i",
        url,
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise FFProbeException(f"ffprobe failed: {result.stderr}")
    return json.loads(str(result.stdout))


@validate_arguments
def validate_input_probe(input_probe: dict):
    """Validate the input probe."""
    if len(input_probe["streams"]) == 0:
        raise InputFormatException("No streams found in the input file")
    # only audio
    if (
        len(input_probe["streams"]) == 1
        and input_probe["streams"][0]["codec_type"] == "audio"
    ):
        raise InputFormatException("Input file is audio only")
    return input_probe


def handler(event, context):
    """Lambda handler function to submit a job to AWS Elemental
    MediaConvert."""

    print(f"REQUEST:: {event}")

    lst = LambdaSettings()
    event = utils.convert_sns_event_to_s3_event(event)
    src_bucket, src_file = utils.retrive_sources_from_s3(event)

    try:
        utils.verify_path_is_valid(src_file, extensions=lst.input_file_suffixes)

        input_path = "s3://" + str(src_bucket / src_file)
        output_path = "s3://" + str(lst.destination_bucket / src_file.parent)

        presigned_url = utils.presign_url(str(src_bucket), str(src_file))

        input_probe = ffprobe(presigned_url)
        validate_input_probe(input_probe)
        width, height = get_width_height(input_probe)

        print(f"INPUT:: {input_probe['format']}")
        print(f"WxH:: {width}x{height}")

        metadata = {
            "guid": str(uuid4()),
            "source_name": str(src_file),
            "width": str(width),
            "height": str(height),
            "format": input_probe["format"]["format_name"],
            "duration": input_probe["format"]["duration"],
            "size": input_probe["format"]["size"],
            "bit_rate": input_probe["format"]["bit_rate"],
        }

        # Download and validate settings
        job = get_default_convert_job(lst.config_bucket, lst.job_config)

        # Parse settings file to update source / destination
        job = update_job_settings(
            job, input_path, output_path, metadata, lst.mediaconvert_role
        )

        job = set_max_width_height(job, width, height, lst.max_width, lst.max_height)

        print(f"JOB:: {job.json()}")
        submit_job(job, lst.mediaconvert_endpoint)

    except UnsupportedExtensionException as err:
        # We are ignoring unsupported file extensions as the are being
        # processed by other lambdas
        print(f"Ignoring unsupported file extension: {src_file}")
    except Exception as err:
        log_group = context.log_group_name if context else "unknown"
        utils.send_exception(lst.sns_topic_arn, log_group, str(err), path=src_file)
        raise err

    return
