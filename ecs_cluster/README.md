# ECS CloudWatch Module

This module provisions resources for ECS CloudWatch setup.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| [aws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecs_cluster.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| [config](#input\_config) | Configuration for the ECS CloudWatch setup, including context, environment, retention period, and name. | <pre>object({<br>    context           = string<br>    environment       = string<br>    retention_in_days = number<br>    name              = string<br>  })</pre> | n/a | yes |

## Outputs

No outputs.

## Usage

```hcl
locals {
  cluster_name = "${var.config.environment}-${var.config.context}"
}

module "ecs_cloudwatch" {
  source = "../cloudwatch"
  config = {
    context           = var.config.context
    environment       = var.config.environment
    retention_in_days = 7
    name              = "ecs"
  }
}

# Name of the cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name = module.ecs_cloudwatch.log_group_name
      }
    }
  }
}

