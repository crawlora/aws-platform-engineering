# ECS Task Definition Module

This module provisions resources for setting up an ECS task definition.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| [aws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| [cloudwatch_logger](../cloudwatch) | - | - |

## Resources

| Name | Type |
|------|------|
| [aws_ecs_task_definition.ecs_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_service.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecs_task_execution_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ecs_tasks_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.ecs_task_execution_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_task_role_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| [context](#input\_context) | The context for the ECS task. | `string` | n/a | yes |
| [cpu](#input\_cpu) | The number of CPU units used by the task. | `string` | n/a | yes |
| [desired_count](#input\_desired\_count) | The number of instantiations of the task to place and keep running. | `number` | n/a | yes |
| [efs_id](#input\_efs\_id) | The ID of the EFS file system. | `string` | n/a | yes |
| [efs_name](#input\_efs\_name) | The name of the EFS volume. | `string` | n/a | yes |
| [environment](#input\_environment) | The environment for the ECS task. | `string` | n/a | yes |
| [image](#input\_image) | The Docker image for the ECS task. | `string` | n/a | yes |
| [memory](#input\_memory) | The amount of memory (in MiB) used by the task. | `string` | n/a | yes |
| [secret_vars](#input\_secret\_vars) | A map of secret environment variables for the ECS task. | `map(string)` | n/a | yes |
| [task_name](#input\_task\_name) | The name of the ECS task. | `string` | n/a | yes |
| [aws_region](#input\_aws\_region) | The AWS region. | `string` | `""` | no |
| [command](#input\_command) | The command that is passed to the container. | `list(string)` | `[]` | no |
| [container_health_check](#input\_container\_health\_check) | The health check configuration for the container. | `list(map(string))` | `[]` | no |
| [environment_vars](#input\_environment\_vars) | A map of environment variables for the ECS task. | `map(string)` | `{}` | no |
| [gpu](#input\_gpu) | The number of GPUs used by the task. | `number` | `0` | no |
| [tags](#input\_tags) | Additional tags for the resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_name | The name of the ECS service. |

