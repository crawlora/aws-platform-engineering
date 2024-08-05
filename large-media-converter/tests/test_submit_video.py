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


from lambdas.src.submit_video import (
    Job,
    JobSettings,
    LambdaSettings,
    ffprobe,
    handler,
    submit_job,
    update_job_settings,
    validate_input_probe,
)
from lambdas.src.utils import convert_s3_event_to_sns_event

env = os.environ


def create_bucket(bucket_name):
    """Create a bucket."""
    s3 = boto3.client("s3", "eu-west-1")
    s3.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": "eu-west-1"},
    )


class TestSubmitVideo(unittest.TestCase):
    """Test the lambda."""

    def setUp(self):
        env[
            "MEDIACONVERT_ENDPOINT"
        ] = "https://tgzfwmguc.mediaconvert.eu-west-1.amazonaws.com"
        env[
            "MEDIACONVERT_ROLE"
        ] = "arn:aws:iam::509069223821:role/dev-lmu-mediaconvert-role"
        env["JOB_CONFIG"] = "job-config.json"
        env["CONFIG_BUCKET"] = "dev-lmu-media-config-bucket"
        env["DESTINATION_BUCKET"] = "dev-lmu-media-output-bucket"
        env[
            "SNS_TOPIC_ARN"
        ] = "arn:aws:sns:eu-west-1:509069223821:dev-lmu-large-media-upload-updates"

        env["MAX_WIDTH"] = "1800"
        env["MAX_HEIGHT"] = "1800"
        env["INPUT_FILE_SUFFIXES"] = json.dumps([".mp4", ".mov", ".avi", ".mkv"])
        os.environ["AWS_DEFAULT_REGION"] = "eu-west-1"

        self.s3_event = {
            "Records": [
                {
                    "awsRegion": "eu-west-1",
                    "s3": {
                        "bucket": {
                            "name": "dev-lmu-media-input-bucket",
                            "ownerIdentity": {"principalId": "A2MVX7UJFL7XKW"},
                            "arn": "arn:aws:s3:::dev-lmu-media-input-bucket",
                        },
                        "object": {
                            "key": "example.mp4",
                        },
                    },
                }
            ]
        }

        self.event = convert_s3_event_to_sns_event(self.s3_event)

        config = (Path(__file__).parent / "assets" / "job-config.json").absolute()
        with open(config) as f:
            self.config = json.load(f)

    def tearDown(self) -> None:
        env["MAX_WIDTH"] = "1800"
        env["MAX_HEIGHT"] = "1800"

    def test_lambda_settings(self):
        """Test LambdaSettings for correct configuration."""
        settings = LambdaSettings()
        self.assertIsNotNone(settings.destination_bucket)
        self.assertIsInstance(settings.input_file_suffixes, list)

    def test_job_validator(self):
        """Tests the JobSettings validator."""
        with self.subTest("Test empty Inputs"):
            job = self.config
            job["Settings"]["Inputs"] = []
            with self.assertRaises(ValueError):
                JobSettings.parse_obj(job)

        with self.subTest("Test empty OutputGroups"):
            job = self.config
            job["Settings"]["OutputGroups"] = []
            with self.assertRaises(ValueError):
                JobSettings.parse_obj(job)

    def test_handler(self):
        example_path = (Path(__file__).parent / "assets" / "example.mp4").absolute()
        with moto.mock_s3():
            create_bucket(env["DESTINATION_BUCKET"])
            create_bucket(env["CONFIG_BUCKET"])

            with patch("lambdas.src.submit_video.utils") as mock, patch(
                "lambdas.src.submit_video.submit_job"
            ):
                mock.convert_sns_event_to_s3_event = convert_s3_event_to_sns_event
                mock.retrive_sources_from_s3.return_value = (
                    Path("dev-lmu-media-input-bucket"),
                    Path("example.mp4"),
                )
                mock.presign_url.return_value = str(example_path)
                mock.get_json_from_s3.return_value = self.config
                handler(self.event, None)

    def test_handler_ignore_unsupported_file(self):
        event = dict(self.s3_event)
        event["Records"][0]["s3"]["object"]["key"] = "example.txt"
        event = convert_s3_event_to_sns_event(event)
        handler(event, None)

    def test_handler_exception(self):
        example_path = (Path(__file__).parent / "assets" / "example.mp4").absolute()
        with moto.mock_s3():
            create_bucket(env["DESTINATION_BUCKET"])
            create_bucket(env["CONFIG_BUCKET"])

            with patch("lambdas.src.submit_video.utils") as mock, patch(
                "lambdas.src.submit_video.submit_job"
            ):
                mock.convert_sns_event_to_s3_event = convert_s3_event_to_sns_event
                mock.retrive_sources_from_s3.return_value = (
                    Path("dev-lmu-media-input-bucket"),
                    Path("example.mp4"),
                )
                mock.presign_url.return_value = str(example_path)
                mock.get_json_from_s3.side_effect = Exception("Test")

                with self.assertRaises(Exception):
                    handler(self.event, None)

    def test_handler_resize_width(self):
        example_path = (Path(__file__).parent / "assets" / "example.mp4").absolute()
        env["MAX_WIDTH"] = "200"
        with moto.mock_s3():
            create_bucket(env["DESTINATION_BUCKET"])
            create_bucket(env["CONFIG_BUCKET"])

            with patch("lambdas.src.submit_video.utils") as mock, patch(
                "lambdas.src.submit_video.submit_job"
            ):
                mock.convert_sns_event_to_s3_event.return_value = self.s3_event
                mock.retrive_sources_from_s3.return_value = (
                    Path("dev-lmu-media-input-bucket"),
                    Path("example.mp4"),
                )
                mock.presign_url.return_value = str(example_path)
                mock.get_json_from_s3.return_value = self.config
                handler(self.event, None)

    def test_handler_resize_height(self):
        example_path = (Path(__file__).parent / "assets" / "example.mp4").absolute()
        env["MAX_HEIGHT"] = "200"
        with moto.mock_s3():
            create_bucket(env["DESTINATION_BUCKET"])
            create_bucket(env["CONFIG_BUCKET"])

            with patch("lambdas.src.submit_video.utils") as mock, patch(
                "lambdas.src.submit_video.submit_job"
            ), patch("lambdas.src.submit_video.get_width_height") as mock_width_height:
                mock.convert_sns_event_to_s3_event = convert_s3_event_to_sns_event
                mock.retrive_sources_from_s3.return_value = (
                    Path("dev-lmu-media-input-bucket"),
                    Path("example.mp4"),
                )
                mock.presign_url.return_value = str(example_path)
                mock.get_json_from_s3.return_value = self.config
                mock_width_height.return_value = (480, 640)
                handler(self.event, None)

    def test_update_job_settings_exception(self):
        """Tests the exception on the update_job_settings function."""
        job = Job.parse_obj(self.config)
        job.Settings.Inputs.pop()
        with self.assertRaises(Exception):
            update_job_settings(job, "valid/path", "valid/path", {}, "valid/path")

    def test_submit_job(self):
        """Tests the submit_job function."""
        job = Job.parse_obj(self.config)
        with unittest.mock.patch("lambdas.src.submit_video.boto3.client"):
            submit_job(job, "1234")

        with unittest.mock.patch(
            "lambdas.src.submit_video.boto3.client"
        ) as mock_client:
            mock_client().create_job.side_effect = Exception("Test")
            with self.assertRaises(Exception):
                submit_job(job, "1234")

    def test_ffprobe_fail(self):
        """Tests the ffprobe fail case."""

        with patch("lambdas.src.submit_video.subprocess.run") as mock:
            mock.returncode = 1
            with self.assertRaises(Exception):
                ffprobe("valid/path")

    def test_validate_input_probe(self):
        """Tests the ffprobe fail case."""
        video = (Path(__file__).parent / "assets" / "example.mp4").absolute()
        probe = ffprobe(str(video))

        validate_input_probe(probe)

        with self.subTest("Only audio"):
            probe["streams"].pop(0)
            with self.assertRaises(Exception):
                validate_input_probe(probe)

        with self.subTest("No streams"):
            probe["streams"] = []
            with self.assertRaises(Exception):
                validate_input_probe(probe)


if __name__ == "__main__":
    unittest.main()
