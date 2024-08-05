## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.rds_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_security_group.db_access_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.rds_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config"></a> [config](#input\_config) | n/a | <pre>object({<br>    environment = string<br>    context     = string<br>    vpc_id      = string<br>    subnet_ids  = list(string)<br>  })</pre> | n/a | yes |
| <a name="input_settings"></a> [settings](#input\_settings) | n/a | <pre>object({<br>    allocated_storage = optional(number, 50)<br>    instance_class = optional(string, "db.t3.micro")<br>    db_name = string<br>    db_username = string<br>    db_password = string<br>    db_port  = optional(number, 5432)<br>    maintenance_window = optional(string, "Mon:00:00-Mon:03:00")<br>    backup_window = optional(string, "03:00-06:00")<br>    skip_final_snapshot = optional(bool, false)<br>    backup_retention_period = optional(number, 7)<br>    final_snapshot_identifier  = optional(string, "final")<br>    engine = optional(string, "postgres")<br>    engine_version = optional(string, "14.3")<br>    publicly_accessible = optional(bool, false)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_access_sg_id"></a> [db\_access\_sg\_id](#output\_db\_access\_sg\_id) | n/a |
| <a name="output_db_sg_id"></a> [db\_sg\_id](#output\_db\_sg\_id) | n/a |
| <a name="output_rds_address"></a> [rds\_address](#output\_rds\_address) | n/a |
