# API Task Module

This module provisions resources for an API Task setup.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| [aws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) | n/a |
| [template](https://registry.terraform.io/providers/hashicorp/template/latest/docs) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_instance.api_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_task_instance) | resource |
| [aws_security_group.api_task_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_iam_role.api_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [template_file.api_task_userdata](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| [config](#input\_config) | Configuration for the API Task setup, including environment, name, context, VPC settings, and instance details. | <pre>object({<br>    environment = string<br>    name        = string<br>    context     = string<br>    vpc_id    = string<br>    subnet_id = string<br>    instance_ami_id    = string<br>    instance_type      = string<br>    aws_key_name        = string<br>    security_group_ids = list(string)<br>  })</pre> | n/a | yes |
| [settings](#input\_settings) | Additional settings for API Task, such as SSH security group creation, cloud init setup, volume size, and cloud init configurations. | <pre>object({<br>    create_ssh_sg = optional(bool, false)<br>    cloud_init_setup = optional(bool, false)<br>    cloud_init_cfg = optional(string, null)<br>    cloud_init_sh = optional(string, null)<br>    volume_size = optional(number, 20)<br>  },<br>  )</pre> | <pre>{<br>  "cloud_init_cfg": null,<br>  "cloud_init_setup": false,<br>  "cloud_init_sh": null,<br>  "create_ssh_sg": false,<br>  "volume_size": 20<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| [instance\_public\_ip](#output\_instance\_public\_ip) | Public IP address of the instance provisioned by the API Task module. |

