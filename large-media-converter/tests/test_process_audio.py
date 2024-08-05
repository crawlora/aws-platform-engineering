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


from lambdas.src import utils
from lambdas.src.process_audio import LambdaSettings, handler

env = os.environ


def create_bucket(bucket_name):
    """Create a bucket."""
    s3 = boto3.client("s3", "eu-west-1")
    s3.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": "eu-west-1"},
    )


def upload_file(bucket_name, key, file_path):
    s3 = boto3.client("s3", "eu-west-1")
    with open(file_path, "rb") as f:
        out = s3.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=f,
        )
    assert out["ResponseMetadata"]["HTTPStatusCode"] == 200


def check_file_exists(bucket_name, key):
    s3 = boto3.client("s3", "eu-west-1")
    try:
        s3.head_object(Bucket=bucket_name, Key=key)
        return True
    except:
        return False


def create_sns_topic(topic_name):
    """Create a SNS topic."""
    sns = boto3.client("sns", "eu-west-1")
    return sns.create_topic(Name=topic_name)["TopicArn"]


class TestProcessAudio(unittest.TestCase):
    """Test the lambda."""

    def setUp(self):
        env["AWS_DEFAULT_REGION"] = "eu-west-1"
        env["DESTINATION_BUCKET"] = "dev-lmu-media-output-bucket"
        env["SRC_BUCKET"] = "dev-lmu-media-input-bucket"
        env[
            "SNS_TOPIC_ARN"
        ] = "arn:aws:sns:eu-west-1:509069223821:dev-lmu-large-media-upload-updates"
        env["INPUT_FILE_SUFFIXES"] = json.dumps([".mp3"])

        self.s3_event = {
            "Records": [
                {
                    "awsRegion": "eu-west-1",
                    "s3": {
                        "bucket": {
                            "name": "dev-lmu-media-input-bucket",
                        },
                        "object": {
                            "key": "test/example.mp3",
                        },
                    },
                }
            ]
        }
        self.event = utils.convert_s3_event_to_sns_event(self.s3_event)

        self.file = (Path(__file__).parent / "assets" / "example.mp3").absolute()

    def test_lambda_settings(self):
        """Test LambdaSettings for correct configuration."""
        settings = LambdaSettings()
        self.assertIsNotNone(settings.destination_bucket)
        self.assertIsInstance(settings.input_file_suffixes, list)

    def test_handler(self):
        with moto.mock_s3(), moto.mock_sns(), patch(
            "lambdas.src.mediainfo.utils.presign_url"
        ) as utils_mock, patch("lambdas.src.mediainfo.utils.send_sns") as send_sns:
            create_bucket(env["DESTINATION_BUCKET"])
            create_bucket(env["SRC_BUCKET"])
            upload_file(env["SRC_BUCKET"], "test/example.mp3", self.file)
            out = create_sns_topic("dev-lmu-large-media-upload-updates")
            env["SNS_TOPIC_ARN"] = out

            utils_mock.return_value = self.file.as_posix()

            handler(self.event, None)
            self.assertTrue(
                check_file_exists(env["DESTINATION_BUCKET"], "test/example.mp3")
            )
            self.assertFalse(check_file_exists(env["SRC_BUCKET"], "test/example.mp3"))

            # Check the file has the correct content type
            s3 = boto3.client("s3", "eu-west-1")
            response = s3.head_object(
                Bucket=env["DESTINATION_BUCKET"], Key="test/example.mp3"
            )
            self.assertEqual(response["Metadata"]["content-type"], "audio/mpeg")

            send_sns.assert_called_once()
            msg = send_sns.call_args_list[0][0][1]

            self.assertEqual(
                msg.output_file,
                f"s3://dev-lmu-media-output-bucket/test/example.mp3",
            )
            self.assertEqual(
                msg.input_file,
                f"s3://dev-lmu-media-input-bucket/test/example.mp3",
            )
            self.assertEqual(msg.subject, "COMPLETE")

    def test_handler_ignore_unsupported_file(self):
        event = dict(self.s3_event)
        event["Records"][0]["s3"]["object"]["key"] = "example.txt"
        event = utils.convert_s3_event_to_sns_event(event)
        handler(event, None)

    def test_handler_exception(self):
        with moto.mock_s3(), moto.mock_sns():
            out = create_sns_topic("dev-lmu-large-media-upload-updates")
            env["SNS_TOPIC_ARN"] = out

            with patch("lambdas.src.process_audio.utils") as mock:
                mock.retrive_sources_from_s3.return_value = ("test-bucket", "test.mp3")
                mock.verify_path_is_valid.side_effect = Exception("Test")
                with self.assertRaises(Exception):
                    handler(self.event, None)


if __name__ == "__main__":
    unittest.main()
