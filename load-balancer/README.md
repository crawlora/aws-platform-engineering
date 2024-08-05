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
| [aws_lb.load_balancer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.https_target_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.target_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config"></a> [config](#input\_config) | n/a | <pre>object({<br>    vpc_id             = string<br>    environment        = string<br>    name               = string<br>    context            = string<br>    security_group_ids = list(string)<br>    subnet_ids         = list(string)<br>    certificate_arn    = string<br>    http_only          = optional(bool, false)<br>    }<br>  )</pre> | n/a | yes |
| <a name="input_settings"></a> [settings](#input\_settings) | n/a | <pre>object({<br>    path                = string<br>    healthy_threshold   = optional(number, 2)<br>    interval            = optional(number, 30)<br>    timeout             = optional(number, 15)<br>    unhealthy_threshold = optional(number, 3)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | n/a |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | n/a |
