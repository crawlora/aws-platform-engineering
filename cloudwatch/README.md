# CloudWatch Module

This module provisions resources for CloudWatch setup.

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
| [aws_cloudwatch_log_group.cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_subscription_filter.cloudwatch_log_subscription_filter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_cloudwatch_metric_alarm.cloudwatch_metric_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| [log_group_name](#input\_log\_group\_name) | Name of the CloudWatch Log Group. | string | n/a | yes |
| [filter_pattern](#input\_filter\_pattern) | Filter pattern for CloudWatch Logs subscription filter. | string | n/a | yes |
| [destination_arn](#input\_destination\_arn) | Destination ARN for CloudWatch Logs subscription filter. | string | n/a | yes |
| [metric_namespace](#input\_metric\_namespace) | Namespace for CloudWatch metric alarm. | string | n/a | yes |
| [metric_name](#input\_metric\_name) | Name of the metric for CloudWatch metric alarm. | string | n/a | yes |
| [comparison_operator](#input\_comparison\_operator) | Comparison operator for CloudWatch metric alarm. | string | n/a | yes |
| [threshold](#input\_threshold) | Threshold value for CloudWatch metric alarm. | number | n/a | yes |
| [evaluation_periods](#input\_evaluation\_periods) | Number of evaluation periods for CloudWatch metric alarm. | number | n/a | yes |
| [alarm_actions](#input\_alarm\_actions) | List of actions to take when the alarm state changes to "ALARM". | list(string) | n/a | yes |
| [ok_actions](#input\_ok\_actions) | List of actions to take when the alarm state changes to "OK". | list(string) | n/a | yes |
| [alarm_description](#input\_alarm\_description) | Description for CloudWatch metric alarm. | string | n/a | yes |
| [insufficient_data_actions](#input\_insufficient\_data\_actions) | List of actions to take when the alarm state changes to "INSUFFICIENT_DATA". | list(string) | n/a | yes |

## Outputs

No outputs.

## Usage

```hcl
resource "aws_cloudwatch_log_group" "example" {
  name              = var.log_group_name
  retention_in_days = 30
}

resource "aws_cloudwatch_log_subscription_filter" "example" {
  name            = "example-filter"
  log_group_name  = aws_cloudwatch_log_group.example.name
  filter_pattern  = var.filter_pattern
  destination_arn = var.destination_arn
}

resource "aws_cloudwatch_metric_alarm" "example" {
  alarm_name          = "example-metric-alarm"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  threshold           = var.threshold
  metric_name         = var.metric_name
  namespace           = var.metric_namespace
  period              = 60
  alarm_description   = var.alarm_description
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  insufficient_data_actions = var.insufficient_data_actions

  dimensions = {
    InstanceId = "i-0123456789abcdef0"
  }
}


