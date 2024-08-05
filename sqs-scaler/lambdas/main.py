"""AWS Lambda function to get SQS queue attributes and put them to CloudWatch."""

import datetime
import boto3
import dateutil


def lambda_handler(event: dict, context: list):
    """The main function that is executed when the Lambda function is triggered.

    It takes in an event as input and outputs SQS-based scaling metrics to CloudWatch.

    Args:
        event (dict): The event that triggered the Lambda function.
        context (list): The context of the Lambda function.
    """
    _ = context

    # Initializing AWS clients
    sqs_client = boto3.client("sqs")
    cw_client = boto3.client("cloudwatch")
    ecs_client = boto3.client("ecs")

    print(f"Event: {event}")

    # Extracting inputs from the event
    queues = event["queue_names"]
    weights = event["queue_weights"]
    max_backlog_per_task = event["max_backlog_per_task"]
    account_id = event["account_id"]
    service_name = event["service_name"]
    cluster = event["cluster_name"]
    aws_region = event["aws_region"]

    assert float(max_backlog_per_task) > 0, "Backlog per task must be greater than 0"
    assert all(
        [float(weight) > 0 for weight in weights]
    ), "All weights must be greater than 0"
    assert len(weights) == len(
        queues
    ), "Number of weights must be equal to number of queues"

    queue_urls = [
        f"https://sqs.{aws_region}.queue.amazonaws.com/{account_id}/{q}" for q in queues
    ]

    # Get the number of running tasks in the specified ECS service
    response = ecs_client.describe_services(cluster=cluster, services=[service_name])
    running_task_count = response["services"][0]["runningCount"]
    print(f"Running Tasks: {running_task_count}")

    # Calculate the acceptable backlog per capacity unit
    raw_queue_backlogs = []
    for qurl, qname in zip(queue_urls, queues):
        # Get the number of messages in the specified SQS queue
        message_count = sqs_client.get_queue_attributes(
            QueueUrl=qurl, AttributeNames=["ApproximateNumberOfMessages"]
        )
        visible_message_count = message_count["Attributes"][
            "ApproximateNumberOfMessages"
        ]
        print(f"{qname} Message Count: {visible_message_count}")
        raw_queue_backlogs.append(int(visible_message_count))

    weighted_queue_backlogs = [
        backlog * weight for backlog, weight in zip(raw_queue_backlogs, weights)
    ]

    # Calculate the backlog per capacity unit
    try:
        backlog_per_capacity_unit = (
            int(sum(weighted_queue_backlogs)) / running_task_count
        )
    except ZeroDivisionError as err:
        print(f"Handling run-time error: {err}")
        backlog_per_capacity_unit = 0
    print(f"Weighted backlog per capacity unit: {backlog_per_capacity_unit}")

    # Calculate the scale adjustment needed based on the backlog per capacity unit and acceptable backlog per capacity unit
    try:
        scale_adjustment = int(backlog_per_capacity_unit / max_backlog_per_task)
    except ZeroDivisionError as err:
        print(f"Handling run-time error: {err}")
        scale_adjustment = 0
    print(f"Scale Up and Down Adjustment: {scale_adjustment}")

    metrics = [
        {
            "name": "ApproximateNumberOfMessages",
            "value": int(visible_message_count),
            "unit": "Count",
        },
        {
            "name": "BackLogPerCapacityUnit",
            "value": backlog_per_capacity_unit,
            "unit": "Count",
        },
        {
            "name": "AcceptableBackLogPerCapacityUnit",
            "value": max_backlog_per_task,
            "unit": "Count",
        },
        {
            "name": "ScaleAdjustmentTaskCount",
            "value": scale_adjustment,
            "unit": "Count",
        },
    ]

    # Put the metrics to CloudWatch
    for metric in metrics:
        putMetricToCW(
            cw=cw_client,
            dimension_name="SQS",
            dimension_value=service_name,
            metric_name=metric["name"],
            metric_value=metric["value"],
        )


def putMetricToCW(
    cw,
    dimension_name,
    dimension_value,
    metric_name,
    metric_value,
    namespace="SQS Based Scaling Metrics",
):
    cw.put_metric_data(
        Namespace=namespace,
        MetricData=[
            {
                "MetricName": metric_name,
                "Dimensions": [{"Name": dimension_name, "Value": dimension_value}],
                "Timestamp": datetime.datetime.now(dateutil.tz.tzlocal()),
                "Value": metric_value,
            }
        ],
    )


if __name__ == "__main__":
    event = {
        "queue_names": ["dev-cv-high_priority.fifo", "dev-cv-low_priority.fifo"],
        "queue_weights": [1, 0.3],
        "max_backlog_per_task": 2,
        "account_id": "575448432945",
        "service_name": "dev-cv-service",
        "cluster_name": "dev-oxolo",
        "aws_region": "eu-west-1",
    }
    context = []
    lambda_handler(event, context)
