# SQS Task Fargate Module

This module provisions resources for an ECS task running on AWS Fargate that interacts with Amazon SQS.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecs_task_execution_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [data.aws_iam_policy_document.ecs_task_role_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_ecs_task_definition.ecs_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_service.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_iam_role_policy_attachment.ecs_tasks_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [module.cloudwatch_logger](https://registry.terraform.io/modules/terraform-aws-modules/cloudwatch/aws/latest) | module |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | The AWS region. | string | | yes |
| command | The command that is passed to the container. | list(string) | | yes |
| container_health_check | The health check configuration for the container. | object | null | no |
| cpu | The amount of CPU to use. | number | | yes |
| desired_count | The number of instances of the task definition to place and keep running. | number | | yes |
| ecs_cluster_id | The ARN of the ECS cluster to associate with the service. | string | | yes |
| environment | The environment for the task. | string | | yes |
| environment_vars | The environment variables for the task. | map(string) | | yes |
| image | The Docker image for the container. | string | | yes |
| memory | The amount of memory (in MiB) to use. | number | | yes |
| secret_vars | The secret variables for the task. | map(string) | | yes |
| security_group_ids | The security group IDs associated with the task. | list(string) | | yes |
| subnet_ids | The subnet IDs associated with the task. | list(string) | | yes |
| tags | The tags to apply to all resources in the module. | map(string) | | yes |
| task_name | The name of the ECS task. | string | | yes |

## Outputs

| Name | Description |
|------|-------------|
| service_name | The name of the ECS service. |

This module provisions sets up IAM roles and policies, defines the ECS task definition, and creates the ECS service. Additionally, it attaches the Amazon ECSTaskExecutionRolePolicy to the ECS task role for managing tasks in ECS.

The `config` variable contains the configuration for the ECS task.

Make sure to fill in the required inputs when using this module to provision an ECS task for Amazon SQS on AWS Fargate.

