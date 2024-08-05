# AWS SQS Scaling Lambda Terraform Module

## Overview
This Terraform module sets up an AWS environment for auto-scaling an ECS service based on the load of SQS queues. It includes resources like IAM roles and policies, Lambda functions, CloudWatch Event Rules and Metrics, and Application Auto Scaling policies.

## Key Components

1. **IAM Roles and Policies:** Setup for the necessary permissions for the Lambda function to interact with other AWS services like ECS, SQS, and CloudWatch.

2. **Lambda Function:** A Lambda function (`aws_lambda_function.sqs_attributes_lambda`) is created to monitor the attributes of SQS queues and trigger scaling actions.

3. **CloudWatch Event Rule and Target:** Schedules the Lambda function execution at regular intervals defined by the `run_every_minute` variable.

4. **CloudWatch Metric Alarms:** Two CloudWatch Metric Alarms are defined for scaling up and down based on the queue length in relation to the max backlog per task.

5. **Application Auto Scaling:** Scaling policies (`aws_appautoscaling_policy`) and targets (`aws_appautoscaling_target`) for the ECS service are created, with scheduled actions for scaling in and out.

6. **CloudWatch Logs:** Log group for the Lambda function for monitoring and debugging.

## Usage

To use this module, you need to set your AWS provider and declare this module with appropriate input variables in your Terraform configuration.

### Example Usage

```hcl
module "aws_sqs_scaling" {
  source = "./path/to/module"

  environment                = "production"
  name                       = "my-app"
  lambda_timeout_in_seconds  = 30
  run_every_minute           = 5
  queue_names                = ["my-queue1", "my-queue2"]
  queue_weights              = [1, 2]
  max_backlog_per_task       = 10
  service_name               = "my-ecs-service"
  ecs_cluster_name           = "my-cluster"
  aws_region                 = "us-east-1"
  // ... other variables
}
```

### Variables

- `environment`: Deployment environment (e.g., `staging`, `production`).
- `name`: Name of the deployment.
- `lambda_timeout_in_seconds`: Timeout for the Lambda function.
- `run_every_minute`: Frequency in minutes to trigger the Lambda function.
- `queue_names`: Names of the SQS queues.
- `queue_weights`: Weights for each SQS queue to calculate the load.
- `max_backlog_per_task`: Maximum number of backlogged items per ECS task before scaling.
- `service_name`: Name of the ECS service to scale.
- `ecs_cluster_name`: Name of the ECS cluster.
- `aws_region`: AWS region where resources are deployed.
- ... (Additional variables and descriptions can be added based on the context.)