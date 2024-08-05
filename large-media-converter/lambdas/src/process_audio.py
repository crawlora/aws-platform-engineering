import sys
from pathlib import Path
from typing import List
from uuid import uuid4

root_folder = Path(__file__).parent.absolute()
sys.path.insert(0, root_folder.as_posix())

import utils
from errors import UnsupportedExtensionException
from models import JobStatus
from models import Settings as BaseSettings


class LambdaSettings(BaseSettings):
    """Lambda Settings."""

    destination_bucket: str
    sns_topic_arn: str

    input_file_suffixes: List[str]


def handler(event, context):
    """Lambda handler function to process audio."""

    print(f"REQUEST:: {event}")

    lst = LambdaSettings()
    event = utils.convert_sns_event_to_s3_event(event)
    src_bucket, src_file = utils.retrive_sources_from_s3(event)

    try:
        utils.verify_path_is_valid(src_file, extensions=lst.input_file_suffixes)

        input_path = "s3://" + str(src_bucket / src_file)
        output_path = "s3://" + str(lst.destination_bucket / src_file)
        path_elements = input_path.replace("s3://", "").split("/")

        utils.copy(s3_url=input_path, target_bucket=lst.destination_bucket)
        utils.delete_s3_object(input_path)

        msg = JobStatus(
            id=str(uuid4()),
            output_file=output_path,
            input_file=input_path,
            path_elements=path_elements,
            subject="COMPLETE",
            data={},
        )
        utils.send_sns(lst.sns_topic_arn, msg)

    except UnsupportedExtensionException as err:
        # We are ignoring unsupported file extensions as the are being
        # processed by other lambdas
        print(f"Ignoring unsupported file extension: {src_file}")
    except Exception as err:
        log_group = context.log_group_name if context else "unknown"
        utils.send_exception(lst.sns_topic_arn, log_group, str(err), path=src_file)
        raise err

    return
