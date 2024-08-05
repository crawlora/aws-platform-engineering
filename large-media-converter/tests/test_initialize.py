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


from lambdas.src.initialize import LambdaSettings, handler


def create_bucket(bucket_name):
    """Create a bucket."""
    s3 = boto3.client("s3", "eu-west-1")
    s3.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": "eu-west-1"},
    )


class TestInitialize(unittest.TestCase):
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
        event = {"body": json.dumps({"path": "valid/path/valid.mp4"})}

        with moto.mock_s3():
            create_bucket(self.bucket)
            resp = handler(event, None)

        self.assertEqual(resp["statusCode"], 200)
        self.assertIn("valid/path/valid.mp4", resp["body"])
        self.assertIn("file_id", resp["body"])
        self.assertIn("path", resp["body"])
        self.assertIn("Access-Control-Allow-Origin", resp["headers"])

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

        with self.subTest("General exception"):
            with unittest.mock.patch(
                "lambdas.src.initialize.boto3.client"
            ) as mock_client:
                mock_client().create_multipart_upload.side_effect = Exception("Test")
                event = {"body": json.dumps({"path": "valid/path/valid.mp4"})}
                with self.assertRaises(Exception):
                    resp = handler(event, None)

    def test_sample_event(self):
        """Testing the sample event with ast."""

        event = {
            "version": "1.0",
            "resource": "/initialize",
            "path": "/dev-lmc-ingress-api/initialize",
            "httpMethod": "POST",
            "body": "eydwYXRoJzondGVzdC5tcDQnfQ==",
            "isBase64Encoded": True,
        }

        with moto.mock_s3():
            create_bucket(self.bucket)
            handler(event, None)


if __name__ == "__main__":
    unittest.main()
