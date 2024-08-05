from datetime import datetime  # Add this import
import boto3
from dateutil import parser
import os

TAG_FILTER = os.environ['TAG_FILTER']
DELETE_OLDER_THAN_DAYS = int(os.environ['DELETE_OLDER_THAN_DAYS'])
EXCLUSION_TAG = os.environ['EXCLUSION_TAG']

def lambda_handler(event, context):
    client = boto3.client('ec2')

    # Get all images with the specified tag
    response = client.describe_images(Filters=[{'Name': 'tag:' + TAG_FILTER, 'Values': ['*']}])

    print(f'Total images with this tag: {str(len(response["Images"]))}')

    # Create a list to store images that match the criteria
    eligible_images = []

    # Iterate through the images and filter based on criteria
    for img in response['Images']:
        datobj = parser.parse(img['CreationDate'])
        time_between_creation = datetime.now().replace(tzinfo=None) - datobj.replace(tzinfo=None)

        # Check if the image is older than 15 days and has the 'cv-service' tag
        if time_between_creation.days > DELETE_OLDER_THAN_DAYS:
            has_cv_service_tag = any(tag['Key'] == 'cv-service' and tag['Value'] == 'True' for tag in img['Tags'])

            if has_cv_service_tag:
                eligible_images.append(img)

    # Sort eligible images by creation date (oldest to newest)
    eligible_images.sort(key=lambda x: x['CreationDate'])

    # Keep the last 5 images
    images_to_keep = eligible_images[-5:]

    i = 0
    for img in response['Images']:
        if img not in images_to_keep:
            i += 1
            img_name = img.get('Name', 'N/A')  # Handle the case where 'Name' is not present
            print(f"Deleting {img['ImageId']} {img_name}")
            responsederegister = client.deregister_image(ImageId=img['ImageId'])

    print(f'Number of images deleted: {str(i)}')
    return True
