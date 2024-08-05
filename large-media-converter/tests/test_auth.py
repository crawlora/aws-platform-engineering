#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Author: Oliver Borchers <o.borchers@oxolo.com>
# For License information, see corresponding LICENSE file.
"""Automated tests for checking the modules."""

import os
import sys
import unittest
from pathlib import Path

root_folder = Path(__file__).parent.parent.absolute()
sys.path.insert(0, root_folder.as_posix())


from lambdas.src.auth import LambdaSettings, handler


class TestAuth(unittest.TestCase):
    """Test the lambda."""

    def setUp(self):
        os.environ["AUTH_TOKEN"] = "12345"

    def test_lambda_settings(self):
        """Test LambdaSettings for correct configuration."""
        settings = LambdaSettings()
        self.assertIsNotNone(settings.auth_token)

    def test_request(self):
        """Test request validation."""
        event = {"headers": {"authorization": "12345"}, "body": "123"}

        resp = handler(event, None)
        self.assertEqual(resp["isAuthorized"], True)

        with self.subTest("Test validation with empty string"):
            event = {"headers": {"authorization": ""}, "body": "123"}

            resp = handler(event, None)
            self.assertEqual(resp["isAuthorized"], False)

        with self.subTest("Test validation without auth"):
            event = {"headers": {}, "body": "123"}

            resp = handler(event, None)
            self.assertEqual(resp["isAuthorized"], False)

        with self.subTest("Test validation without auth"):
            event = {"body": "123"}

            resp = handler(event, None)
            self.assertEqual(resp["statusCode"], 400)


if __name__ == "__main__":
    unittest.main()
