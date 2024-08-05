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


from lambdas.src.mediainfo import LambdaSettings, handler
from lambdas.src.utils import run_mediainfo


def create_bucket(bucket_name):
    """Create a bucket."""
    s3 = boto3.client("s3", "eu-west-1")
    s3.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": "eu-west-1"},
    )


class TestMediaInfo(unittest.TestCase):
    """Test the lambda."""

    def setUp(self):
        self.bucket = "dev-lmu-media-input-bucket"
        os.environ["INPUT_FILE_SUFFIXES"] = json.dumps(
            [".mp4", ".mov", ".avi", ".mkv", ".mp3"]
        )
        os.environ["AWS_DEFAULT_REGION"] = "eu-west-1"

    def test_lambda_settings(self):
        """Test LambdaSettings for correct configuration."""
        settings = LambdaSettings()
        self.assertIsInstance(settings.input_file_suffixes, list)

    def test_mediainfo(self):
        """Test mediainfo function."""
        example_path = (Path(__file__).parent / "assets" / "example.mp4").absolute()
        result = run_mediainfo(example_path.as_posix())
        self.assertIsInstance(result, dict)
        self.assertIn("media", result)
        self.assertIn("track", result["media"])
        self.assertIsInstance(result["media"]["track"], list)

    def test_request_mp4(self):
        """Test request validation."""
        event = {"body": json.dumps({"path": f"s3://{self.bucket}/path/example.mp4"})}
        video = (Path(__file__).parent / "assets" / "example.mp4").absolute()

        with patch("lambdas.src.mediainfo.utils.presign_url") as utils_mock:
            utils_mock.return_value = video.as_posix()
            resp = handler(event, None)

        self.assertEqual(resp["statusCode"], 200)
        body = json.loads(resp["body"])
        self.assertIn("filename", resp["body"])
        self.assertIn("file_extension", resp["body"])
        self.assertIn("filname_extension", resp["body"])
        self.assertIn("content-type", resp["body"])
        self.assertIn("duration_seconds", resp["body"])

        self.assertEqual(body["duration_seconds"], 30.527)

    def test_request_mp3(self):
        """Test request validation."""
        event = {"body": json.dumps({"path": f"s3://{self.bucket}/path/example.mp3"})}
        video = (Path(__file__).parent / "assets" / "example.mp3").absolute()

        with patch("lambdas.src.mediainfo.utils.presign_url") as utils_mock:
            utils_mock.return_value = video.as_posix()
            resp = handler(event, None)

        self.assertEqual(resp["statusCode"], 200)
        body = json.loads(resp["body"])
        self.assertIn("filename", resp["body"])
        self.assertIn("file_extension", resp["body"])
        self.assertIn("filname_extension", resp["body"])
        self.assertIn("content-type", resp["body"])
        self.assertIn("duration_seconds", resp["body"])

        self.assertEqual(body["duration_seconds"], 1.697)

    def test_request_failed(self):
        """Test request validation."""
        event = {"body": json.dumps({"path": f"s3://{self.bucket}/path/example.mp3"})}

        with patch("lambdas.src.mediainfo.utils.presign_url") as utils_mock:
            utils_mock.return_value = "test.mp4"
            resp = handler(event, None)

        self.assertEqual(resp["statusCode"], 500)
        self.assertIn("No media information found.", resp["body"])

    def test_request_failed_exception(self):
        """Test request validation."""
        event = {"body": json.dumps({"path": f"s3://{self.bucket}/path/example.mp3"})}

        with patch("lambdas.src.mediainfo.utils.presign_url") as utils_mock:
            utils_mock.side_effect = Exception("Test")
            with self.assertRaises(Exception):
                handler(event, None)

    def test_request_validation(self):
        """Test request validation."""

        with self.subTest("Test path validation with empty string"):
            event = {"body": json.dumps({"path": ""})}
            with moto.mock_s3():
                create_bucket(self.bucket)
                resp = handler(event, None)
            self.assertEqual(resp["statusCode"], 400)

        with self.subTest("Test path validation with wrong file"):
            event = {"body": json.dumps({"path": "test.txt"})}
            with moto.mock_s3():
                create_bucket(self.bucket)
                resp = handler(event, None)
            self.assertEqual(resp["statusCode"], 400)

        with self.subTest("Test path validation with folder"):
            event = {"body": json.dumps({"path": "test"})}
            with moto.mock_s3():
                create_bucket(self.bucket)
                resp = handler(event, None)
            self.assertEqual(resp["statusCode"], 400)

        with self.subTest("Test validation with no body"):
            event = {}
            with moto.mock_s3():
                create_bucket(self.bucket)
                resp = handler(event, None)
            self.assertEqual(resp["statusCode"], 400)


if __name__ == "__main__":
    unittest.main()
