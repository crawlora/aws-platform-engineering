# ECS Instance Provisioning Module

This module provisions resources for setting up ECS instances.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| [aws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.ecs_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_instance_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_instance_profile.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_launch_configuration.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration) | resource |
| [aws_autoscaling_group.ec2_worker_launch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_iam_policy_document.ecs_instance_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| [config](#input\_config) | Configuration for ECS instance setup, including environment, security groups, ECS cluster name, volume type, and volume size. | <pre>object({<br>    context                     = string<br>    environment                 = string<br>    name                        = string<br>    aws_launch_configuration_suffix = string<br>    security_group_ids          = list(string)<br>    ecs_cluster_name            = string<br>    volume_type                 = string<br>    volume_size                 = number<br>    image_id                    = string<br>    instance_type               = string<br>    aws_key_name                = string<br>    autoscale_min               = number<br>    autoscale_max               = number<br>    autoscale_desired           = number<br>    subnet_ids                  = list(string)<br>    tags                        = map(string)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| asg_name | The name of the autoscaling group. |
| asg_arn | The ARN of the autoscaling group. |

