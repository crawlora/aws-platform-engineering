#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Author: Oliver Borchers <o.borchers@oxolo.com>
# For License information, see corresponding LICENSE file.
"""Automated tests for checking the modules."""

import json
import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

import boto3
import moto

root_folder = Path(__file__).parent.parent.absolute()
sys.path.insert(0, root_folder.as_posix())


from lambdas.src.complete_video import create_thumbnail_and_upload_to_s3, handler

MEDIACONVERT_JOB = (
    Path(__file__).parent / "assets" / "mediaconvert_details.json"
).absolute()


def get_mediaconvert_job() -> dict:
    with open(MEDIACONVERT_JOB, "r") as f:
        return json.load(f)


def create_bucket(bucket_name):
    """Create a bucket."""
    s3 = boto3.client("s3", "eu-west-1")
    s3.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": "eu-west-1"},
    )


@moto.mock_s3
@moto.mock_sns
class TestCompleteVideo(unittest.TestCase):
    """Test the lambda."""

    def setUp(self):
        os.environ[
            "MEDIACONVERT_ENDPOINT"
        ] = "https://tgzfwmguc.mediaconvert.eu-west-1.amazonaws.com"
        os.environ["JOBS_MANIFEST"] = "jobs-manifest.json"
        os.environ["CONFIG_BUCKET"] = "dev-lmu-media-config-bucket"
        os.environ[
            "SNS_TOPIC_ARN"
        ] = "arn:aws:sns:eu-west-1:509069223821:dev-lmu-large-media-upload-updates"
        os.environ["AWS_DEFAULT_REGION"] = "eu-west-1"

    def tearDown(self):
        del os.environ["MEDIACONVERT_ENDPOINT"]
        del os.environ["JOBS_MANIFEST"]
        del os.environ["CONFIG_BUCKET"]
        del os.environ["SNS_TOPIC_ARN"]

    def test_handler_complete_status(self):
        """Test handler with complete status."""

        with patch("lambdas.src.complete_video.boto3.client") as boto3_client:
            boto3_client().get_job.return_value = get_mediaconvert_job()

            # Create test event
            job_id = "1234"
            event = {
                "version": "0",
                "id": "6fcf4518-dc1b-a1ba-a6aa-643a5b88e4cb",
                "detail-type": "MediaConvert Job State Change",
                "source": "aws.mediaconvert",
                "account": "509069223821",
                "time": "2023-11-22T14:58:43Z",
                "region": "eu-west-1",
                "resources": [
                    f"arn:aws:mediaconvert:eu-west-1:509069223821:jobs/{job_id}"
                ],
                "detail": {
                    "timestamp": 1700665123889,
                    "accountId": "509069223821",
                    "queue": "arn:aws:mediaconvert:eu-west-1:509069223821:queues/Default",
                    "jobId": job_id,
                    "status": "COMPLETE",
                    "userMetadata": {
                        "guid": "f0e28185-d663-439b-b4d6-b94c640ae6d0",
                        "source_name": "Meteora Graphic.mp4",
                    },
                    "outputGroupDetails": [
                        {
                            "outputDetails": [
                                {
                                    "outputFilePaths": [
                                        f"s3://dev-lmu-media-output-bucket/Meteora Graphic.mp4"
                                    ],
                                    "durationInMs": 46000,
                                    "videoDetails": {
                                        "widthInPx": 768,
                                        "heightInPx": 768,
                                        "averageBitrate": 1528700,
                                    },
                                }
                            ],
                            "type": "FILE_GROUP",
                        }
                    ],
                    "paddingInserted": 0,
                    "blackVideoDetected": 0,
                    "warnings": [
                        {"code": 230001, "count": 1},
                        {"code": 230005, "count": 1},
                    ],
                },
            }

            with patch("lambdas.src.complete_video.utils.send_sns") as send_sns:
                handler(event, None)

                send_sns.assert_called_once()
                msg = send_sns.call_args_list[0][0][1]

                self.assertEqual(msg.id, job_id)
                self.assertEqual(
                    msg.output_file,
                    f"s3://dev-lmu-media-output-bucket/Meteora Graphic.mp4",
                )
                self.assertEqual(
                    msg.input_file,
                    f"s3://dev-lmc-media-input-bucket/fix/Oxolo-test-2024-02-06.mp4",
                )
                self.assertEqual(msg.subject, "COMPLETE")

    def test_handler_error_status(self):
        """Test handler with error status."""
        job_id = "1234"
        event = {
            "version": "0",
            "id": "6fcf4518-dc1b-a1ba-a6aa-643a5b88e4cb",
            "detail-type": "MediaConvert Job State Change",
            "source": "aws.mediaconvert",
            "account": "509069223821",
            "time": "2023-11-22T14:58:43Z",
            "region": "eu-west-1",
            "resources": [f"arn:aws:mediaconvert:eu-west-1:509069223821:jobs/{job_id}"],
            "detail": {
                "timestamp": 1700665123889,
                "accountId": "509069223821",
                "queue": "arn:aws:mediaconvert:eu-west-1:509069223821:queues/Default",
                "jobId": job_id,
                "status": "ERROR",  # <---- Error status
                "userMetadata": {
                    "guid": "f0e28185-d663-439b-b4d6-b94c640ae6d0",
                    "source_name": "Meteora Graphic.mp4",
                },
                "outputGroupDetails": [
                    {
                        "outputDetails": [
                            {
                                "outputFilePaths": [
                                    f"s3://dev-lmu-media-output-bucket/Meteora Graphic.mp4"
                                ],
                                "durationInMs": 46000,
                                "videoDetails": {
                                    "widthInPx": 768,
                                    "heightInPx": 768,
                                    "averageBitrate": 1528700,
                                },
                            }
                        ],
                        "type": "FILE_GROUP",
                    }
                ],
                "paddingInserted": 0,
                "blackVideoDetected": 0,
                "warnings": [
                    {"code": 230001, "count": 1},
                    {"code": 230005, "count": 1},
                ],
            },
        }
        with patch("lambdas.src.complete_video.boto3.client") as boto3_client:
            boto3_client().get_job.return_value = get_mediaconvert_job()
            handler(event, None)

    def test_handler_progress_status(self):
        """Test with unknown status."""

        event = {
            "version": "0",
            "id": "88fc19b5-c85a-0b26-2e34-5fddf197def4",
            "detail-type": "MediaConvert Job State Change",
            "source": "aws.mediaconvert",
            "account": "575448432945",
            "time": "2023-11-29T10:26:06Z",
            "region": "eu-west-1",
            "resources": [
                "arn:aws:mediaconvert:eu-west-1:575448432945:jobs/1701253555613-6oooe6"
            ],
            "detail": {
                "timestamp": 1701253566860,
                "accountId": "575448432945",
                "queue": "arn:aws:mediaconvert:eu-west-1:575448432945:queues/Default",
                "jobId": "1701253555613-6oooe6",
                "status": "INPUT_INFORMATION",
                "userMetadata": {
                    "guid": "7ee7e038-238a-4de6-a710-af229a6e58f6",
                    "source_name": "billo-92494-orig.mp4",
                    "width": "1080",
                    "height": "1920",
                    "format": "mov,mp4,m4a,3gp,3g2,mj2",
                    "duration": "29.466667",
                    "size": "65326534",
                    "bit_rate": "17735710",
                },
                "inputDetails": [
                    {
                        "audio": [
                            {
                                "channels": 2,
                                "codec": "AAC",
                                "language": "UND",
                                "sampleRate": 48000,
                                "streamId": 2,
                            }
                        ],
                        "id": 1,
                        "uri": "s3://dev-lmc-media-input-bucket/billo-92494-orig.mp4",
                        "video": [
                            {
                                "bitDepth": 8,
                                "codec": "H_264",
                                "colorFormat": "YUV_420",
                                "fourCC": "avc1",
                                "frameRate": 30,
                                "height": 1920,
                                "interlaceMode": "PROGRESSIVE",
                                "sar": "1:1",
                                "standard": "UNSPECIFIED",
                                "streamId": 1,
                                "width": 1080,
                            }
                        ],
                    }
                ],
            },
        }
        with patch("lambdas.src.complete_video.boto3.client"):
            handler(event, None)

    def test_handler_unkown_status(self):
        """Test with unknown status."""

        event = {
            "version": "0",
            "id": "88fc19b5-c85a-0b26-2e34-5fddf197def4",
            "detail-type": "MediaConvert Job State Change",
            "source": "aws.mediaconvert",
            "account": "575448432945",
            "time": "2023-11-29T10:26:06Z",
            "region": "eu-west-1",
            "resources": [
                "arn:aws:mediaconvert:eu-west-1:575448432945:jobs/1701253555613-6oooe6"
            ],
            "detail": {
                "timestamp": 1701253566860,
                "accountId": "575448432945",
                "queue": "arn:aws:mediaconvert:eu-west-1:575448432945:queues/Default",
                "jobId": "1701253555613-6oooe6",
                "status": "NONONONON",  # <---- Unknown status
                "userMetadata": {
                    "guid": "7ee7e038-238a-4de6-a710-af229a6e58f6",
                    "source_name": "billo-92494-orig.mp4",
                    "width": "1080",
                    "height": "1920",
                    "format": "mov,mp4,m4a,3gp,3g2,mj2",
                    "duration": "29.466667",
                    "size": "65326534",
                    "bit_rate": "17735710",
                },
                "inputDetails": [
                    {
                        "audio": [
                            {
                                "channels": 2,
                                "codec": "AAC",
                                "language": "UND",
                                "sampleRate": 48000,
                                "streamId": 2,
                            }
                        ],
                        "id": 1,
                        "uri": "s3://dev-lmc-media-input-bucket/billo-92494-orig.mp4",
                        "video": [
                            {
                                "bitDepth": 8,
                                "codec": "H_264",
                                "colorFormat": "YUV_420",
                                "fourCC": "avc1",
                                "frameRate": 30,
                                "height": 1920,
                                "interlaceMode": "PROGRESSIVE",
                                "sar": "1:1",
                                "standard": "UNSPECIFIED",
                                "streamId": 1,
                                "width": 1080,
                            }
                        ],
                    }
                ],
            },
        }
        with patch("lambdas.src.complete_video.boto3.client"):
            with self.assertRaises(Exception):
                handler(event, None)

    def test_handler_untreated_error(self):
        """Test handler with error status."""
        job_id = "1234"
        event = {
            "version": "0",
            "id": "6fcf4518-dc1b-a1ba-a6aa-643a5b88e4cb",
            "detail-type": "MediaConvert Job State Change",
            "source": "aws.mediaconvert",
            "account": "509069223821",
            "time": "2023-11-22T14:58:43Z",
            "region": "eu-west-1",
            "resources": [f"arn:aws:mediaconvert:eu-west-1:509069223821:jobs/{job_id}"],
            "detail": {
                "timestamp": 1700665123889,
                "accountId": "509069223821",
                "queue": "arn:aws:mediaconvert:eu-west-1:509069223821:queues/Default",
                "jobId": job_id,
                "status": "ERROR",  # <---- Error status
                "userMetadata": {
                    "guid": "f0e28185-d663-439b-b4d6-b94c640ae6d0",
                    "source_name": "Meteora Graphic.mp4",
                },
                "outputGroupDetails": [
                    {
                        "outputDetails": [
                            {
                                "outputFilePaths": [
                                    f"s3://dev-lmu-media-output-bucket/Meteora Graphic.mp4"
                                ],
                                "durationInMs": 46000,
                                "videoDetails": {
                                    "widthInPx": 768,
                                    "heightInPx": 768,
                                    "averageBitrate": 1528700,
                                },
                            }
                        ],
                        "type": "FILE_GROUP",
                    }
                ],
                "paddingInserted": 0,
                "blackVideoDetected": 0,
                "warnings": [
                    {"code": 230001, "count": 1},
                    {"code": 230005, "count": 1},
                ],
            },
        }
        with patch("lambdas.src.complete_video.boto3.client") as boto3_client, patch(
            "lambdas.src.complete_video.utils"
        ) as mock_utils:
            boto3_client().get_job.return_value = get_mediaconvert_job()
            mock_utils.s3_url_to_bucket_and_key.return_value = (
                "test-bucket",
                "test.mp3",
            )
            mock_utils.copy.side_effect = Exception("Test")
            handler(event, None)

    def test_handler_missing_outputgroup_details(self):
        """Test handler with complete status."""

        with patch("lambdas.src.complete_video.boto3.client") as boto3_client:
            boto3_client().get_job.return_value = get_mediaconvert_job()

            # Create test event
            job_id = "1234"
            event = {
                "version": "0",
                "id": "6fcf4518-dc1b-a1ba-a6aa-643a5b88e4cb",
                "detail-type": "MediaConvert Job State Change",
                "source": "aws.mediaconvert",
                "account": "509069223821",
                "time": "2023-11-22T14:58:43Z",
                "region": "eu-west-1",
                "resources": [
                    f"arn:aws:mediaconvert:eu-west-1:509069223821:jobs/{job_id}"
                ],
                "detail": {
                    "timestamp": 1700665123889,
                    "accountId": "509069223821",
                    "queue": "arn:aws:mediaconvert:eu-west-1:509069223821:queues/Default",
                    "jobId": job_id,
                    "status": "COMPLETE",
                    "userMetadata": {
                        "guid": "f0e28185-d663-439b-b4d6-b94c640ae6d0",
                        "source_name": "Meteora Graphic.mp4",
                    },
                    "paddingInserted": 0,
                    "blackVideoDetected": 0,
                    "warnings": [
                        {"code": 230001, "count": 1},
                        {"code": 230005, "count": 1},
                    ],
                },
            }

            handler(event, None)

    def test_create_thumbnail_and_upload_to_s3(self):
        """Tests the full thumbnail creation flow."""
        bucket_name = "dev-lmu-media-output-bucket"

        example_path = (Path(__file__).parent / "assets" / "example.jpg").absolute()

        with moto.mock_s3():
            s3 = boto3.client("s3")
            create_bucket(bucket_name)
            s3.upload_file(str(example_path), bucket_name, "image.0000000.jpg")
            create_thumbnail_and_upload_to_s3(f"s3://{bucket_name}/image.mp4")

            self.assertTrue(s3.head_object(Bucket=bucket_name, Key="image.png"))

            self.assertEqual(
                s3.get_object(Bucket=bucket_name, Key="image.png")["ContentType"],
                "image/png",
            )


if __name__ == "__main__":
    unittest.main()
