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

import boto3
import moto

root_folder = Path(__file__).parent.parent.absolute()
sys.path.insert(0, root_folder.as_posix())


from lambdas.src.finalize import LambdaSettings, handler


def create_bucket(bucket_name):
    """Create a bucket."""
    s3 = boto3.client("s3", "eu-west-1")
    s3.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": "eu-west-1"},
    )


class TestFinalize(unittest.TestCase):
    """Test the lambda."""

    def setUp(self):
        self.bucket = "dev-lmu-media-input-bucket"
        os.environ["BUCKET_NAME"] = self.bucket
        os.environ["INPUT_FILE_SUFFIXES"] = json.dumps([".mp4", ".mov", ".avi", ".mkv"])
        os.environ["AWS_DEFAULT_REGION"] = "eu-west-1"

    def test_lambda_settings(self):
        """Test LambdaSettings for correct configuration."""
        settings = LambdaSettings()
        self.assertIsNotNone(settings.bucket_name)
        self.assertIsInstance(settings.input_file_suffixes, list)

    def test_request(self):
        """Test request validation."""
        with moto.mock_s3():
            create_bucket(self.bucket)

            s3 = boto3.client("s3")
            resp = s3.create_multipart_upload(Bucket=self.bucket, Key="test.mov")
            up_resp = s3.upload_part(
                Bucket=self.bucket,
                Key="test.mov",
                PartNumber=1,
                UploadId=resp["UploadId"],
                Body=b"test",
            )

            event = {
                "body": json.dumps(
                    {
                        "path": resp["Key"],
                        "file_id": resp["UploadId"],
                        "parts": [{"PartNumber": 1, "ETag": up_resp["ETag"]}],
                    }
                )
            }

            resp = handler(event, None)

        self.assertEqual(resp["statusCode"], 200)
        self.assertIn("message", resp["body"])

        self.assertIn("Access-Control-Allow-Origin", resp["headers"])

        with self.subTest("Test path validation with empty string"):
            event = {"body": json.dumps({"path": "", "file_id": "test", "parts": [{}]})}
            with moto.mock_s3():
                create_bucket(self.bucket)
                resp = handler(event, None)
            self.assertEqual(resp["statusCode"], 400)

        with self.subTest("Test path validation with wrong file"):
            event = {
                "body": json.dumps(
                    {"path": "test.txt", "file_id": "test", "parts": [{}]}
                )
            }
            with moto.mock_s3():
                create_bucket(self.bucket)
                resp = handler(event, None)
            self.assertEqual(resp["statusCode"], 400)

        with self.subTest("General exception"):
            with unittest.mock.patch(
                "lambdas.src.presign_urls.boto3.client"
            ) as mock_client:
                mock_client().complete_multipart_upload.side_effect = Exception("Test")
                event = {
                    "body": json.dumps(
                        {
                            "path": "test.mov",
                            "file_id": "test",
                            "parts": [{"PartNumber": 1, "ETag": "test"}],
                        }
                    )
                }
                with self.assertRaises(Exception):
                    resp = handler(event, None)


if __name__ == "__main__":
    unittest.main()
