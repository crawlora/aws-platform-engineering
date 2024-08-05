## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_instance.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.instance_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_security_group.allow_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [template_cloudinit_config.cloud_init](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config"></a> [config](#input\_config) | n/a | <pre>object({<br>    // Custom variable to specify the environment.<br>    environment = string<br>    name        = string<br>    context     = string<br>    // VPC/Networking properties<br>    vpc_id    = string<br>    subnet_id = string<br>    // Instance setting<br>    instance_ami_id    = string<br>    instance_type      = string<br>    aws_key_name        = string<br>    security_group_ids = list(string)<br>  })</pre> | n/a | yes |
| <a name="input_settings"></a> [settings](#input\_settings) | n/a | <pre>object({<br>    create_ssh_sg = optional(bool, false)<br>    cloud_init_setup = optional(bool, false)<br>    cloud_init_cfg = optional(string, null)<br>    cloud_init_sh = optional(string, null)<br>    volume_size = optional(number, 20)<br>  },<br>  )</pre> | <pre>{<br>  "cloud_init_cfg": null,<br>  "cloud_init_setup": false,<br>  "cloud_init_sh": null,<br>  "create_ssh_sg": false,<br>  "volume_size": 20<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_public_ip"></a> [instance\_public\_ip](#output\_instance\_public\_ip) | n/a |
