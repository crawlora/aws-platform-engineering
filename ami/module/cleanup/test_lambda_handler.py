import unittest
from unittest.mock import patch, Mock

# Define your mock environment variables
MOCK_ENV_VARS = {
    'TAG_FILTER': 'cv-service',
    'DELETE_OLDER_THAN_DAYS': '15',
    'EXCLUSION_TAG': 'cv-service'
}

class TestLambdaHandler(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        # Set up mock environment variables
        cls.mock_env = MOCK_ENV_VARS

    @patch.dict('os.environ', MOCK_ENV_VARS)
    @patch('boto3.client')
    def test_lambda_handler(self, mock_boto3_client):
        import lambda_handler  # Import your Lambda function code

        # Define test data
        test_images = [
            {
                'ImageId': 'ami-0613860c04ade6dc0',
                'CreationDate': '2023-09-01T12:00:00Z',
                'Tags': [{'Key': 'cv-service', 'Value': 'True'}]
            },
            {
                'ImageId': 'ami-05cb4a1b207273b88',
                'CreationDate': '2023-09-02T12:00:00Z',
                'Tags': [{'Key': 'cv-service', 'Value': 'False'}]
            },
            {
                'ImageId': 'ami-027f2158ab805f63f',
                'CreationDate': '2023-09-03T12:00:00Z',
                'Tags': [{'Key': 'cv-service', 'Value': 'True'}]
            },
            {
                'ImageId': 'ami-07b108c2f003f7ae1',
                'CreationDate': '2023-09-04T12:00:00Z',
                'Tags': [{'Key': 'cv-service', 'Value': 'True'}]
            },
            {
                'ImageId': 'ami-09b90f80da8f7585f',
                'CreationDate': '2023-09-05T12:00:00Z',
                'Tags': [{'Key': 'cv-service', 'Value': 'True'}]
            },
            {
                'ImageId': 'ami-0241b711fc63f2d63',
                'CreationDate': '2023-09-06T12:00:00Z',
                'Tags': [{'Key': 'cv-service', 'Value': 'True'}]
            },
        ]

        mock_ec2_client = Mock()
        mock_ec2_client.describe_images.return_value = {'Images': test_images}
        mock_boto3_client.return_value = mock_ec2_client

        # Execute the Lambda handler function
        result = lambda_handler.lambda_handler({}, {})

        # Verify that the expected images are deleted
        self.assertEqual(mock_ec2_client.deregister_image.call_count, 1)
        self.assertEqual(mock_ec2_client.deregister_image.call_args[1]['ImageId'], 'ami-0613860c04ade6dc0')  # Adjust to 'ami-0613860c04ade6dc0'
        # Verify the result of the Lambda handler
        self.assertTrue(result)

if __name__ == '__main__':
    unittest.main()
