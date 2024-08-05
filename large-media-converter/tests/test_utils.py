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

from lambdas.src import models, utils


def create_bucket(bucket_name):
    """Create a bucket."""
    s3 = boto3.client("s3", "eu-west-1")
    s3.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": "eu-west-1"},
    )


class TestUtils(unittest.TestCase):
    """Test the lambda."""

    def setUp(self):
        self.bucket = "dev-lmu-media-input-bucket"
        self.sns_topic_name = "test-topic"
        os.environ["BUCKET_NAME"] = self.bucket
        os.environ["INPUT_FILE_SUFFIXES"] = json.dumps([".mp4", ".mov", ".avi", ".mkv"])
        os.environ["AWS_DEFAULT_REGION"] = "eu-west-1"

    def tearDown(self):
        del os.environ["BUCKET_NAME"]
        del os.environ["INPUT_FILE_SUFFIXES"]

    def test_send_sns(self):
        """Test sending an SNS message."""
        message = models.SNSMessage(subject="Test Subject", detail="Test Detail")
        with moto.mock_sns():
            sns = boto3.client("sns")
            resp = sns.create_topic(Name=self.sns_topic_name)
            utils.send_sns(resp["TopicArn"], message)

        with self.subTest("General Exception"):
            with unittest.mock.patch("boto3.client") as mock_client:
                mock_client().publish.side_effect = Exception("Test")
                with self.assertRaises(Exception):
                    utils.send_sns(resp["TopicArn"], message)

    def test_send_exception(self):
        """Test sending an SNS message with an exception."""
        with moto.mock_sns():
            sns = boto3.client("sns")
            resp = sns.create_topic(Name=self.sns_topic_name)
            utils.send_exception(resp["TopicArn"], "123", "123", "/tmp/test.txt")

    def test_get_json_from_s3(self):
        bucket_name = "test-bucket"
        key = "test.json"
        with moto.mock_s3():
            s3 = boto3.client("s3", region_name="us-east-1")
            s3.create_bucket(Bucket=bucket_name)
            s3.put_object(Bucket=bucket_name, Key=key, Body='{"key": "value"}')
            result = utils.get_json_from_s3(bucket_name, key)
        self.assertEqual(result, {"key": "value"})

        with self.subTest("General Exception"):
            with unittest.mock.patch("boto3.client") as mock_client:
                mock_client().get_object.side_effect = Exception("Test")
                with self.assertRaises(Exception):
                    result = utils.get_json_from_s3(bucket_name, key)

    def test_presign_url(self):
        bucket_name = "test-bucket"
        key = "test.txt"
        with moto.mock_s3():
            s3 = boto3.client("s3", region_name="us-east-1")
            s3.create_bucket(Bucket=bucket_name)
            url = utils.presign_url(bucket_name, key)
            self.assertIsNotNone(url)

    def test_decode_base_64_event_body(self):
        event = {"isBase64Encoded": True, "body": "SGVsbG8gV29ybGQ="}
        utils.decode_base_64_event_body(event)
        self.assertEqual(event["body"], "Hello World")

    def test_assert_event_has_body(self):
        event = {"body": "Hello World"}
        self.assertTrue(utils.assert_event_has_body(event))

    def test_preprocess_api_event(self):
        # Payload = {"hello": "world}
        event = {"isBase64Encoded": True, "body": "eyJIZWxsbyI6ICJ3b3JsZCJ9"}
        utils.preprocess_api_event(event)

    def test_retrive_sources_from_s3(self):
        """Test the retrive_sources_from_s3 function."""
        event = {
            "Records": [
                {
                    "s3": {
                        "bucket": {
                            "name": "dev-lmu-media-input-bucket",
                        },
                        "object": {
                            "key": "test/example.mp4",
                        },
                    },
                }
            ]
        }
        bucket, key = utils.retrive_sources_from_s3(event)

        self.assertEqual(str(bucket), "dev-lmu-media-input-bucket")
        self.assertEqual(str(key), "test/example.mp4")


if __name__ == "__main__":
    unittest.main()
