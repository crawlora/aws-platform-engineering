variable "environment" {
  type        = string
  description = "The environment name (e.g. dev, staging, prod)"
}

variable "name" {
  type        = string
  description = "The name of the deployment"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to AWS resources"
}

variable "aws_region" {
  type        = string
  description = "The AWS region to use for the task"
}

variable "ecs_cluster_name" {
  type        = string
  description = "The name of the ECS cluster to deploy the task to"
}

variable "queue_names" {
  type        = list(string)
  description = "The name of the input SQS queue"
}

variable "queue_weights" {
  type        = list(number)
  description = "The weight of each queue"
}

variable "lambda_timeout_in_seconds" {
  default     = 60
  type        = number
  description = "The timeout for the lambda function"
}

variable "run_every_minute" {
  description = "The number of minutes between each run of the lambda function"
  type        = number
  default     = 1

  validation {
    condition     = var.run_every_minute >= 1 && var.run_every_minute <= 60
    error_message = "The value must be between 1 and 60."
  }
}

variable "service_name" {
  type        = string
  description = "The name of the ECS service"
}

variable "max_backlog_per_task" {
  description = "The maximum backlog of messages to process per task"
  type        = number
  default     = 2
}

variable "cw_log_group_retention_period" {
  default     = 30
  type        = number
  description = "The number of days to retain CloudWatch logs"
}

variable "evaluation_periods_high" {
  default     = 1
  type        = number
  description = "The number of periods to evaluate the metric over"
}

variable "evaluation_seconds_high" {
  default     = 30
  type        = number
  description = "The number of seconds in each evaluation period"
}

variable "evaluation_periods_low" {
  default     = 1
  type        = number
  description = "The number of periods to evaluate the metric over"
}

variable "evaluation_seconds_low" {
  default     = 30
  type        = number
  description = "The number of seconds in each evaluation period"
}

variable "scale_up_cooldown_seconds" {
  default     = 60
  type        = number
  description = "The number of seconds to wait before scaling up again"
}

variable "scale_down_cooldown_seconds" {
  default     = 60
  type        = number
  description = "The number of seconds to wait before scaling down again"
}

variable "scale_up_number_of_tasks" {
  description = "The number of tasks to scale up by"
  type        = number
  default     = 1

  validation {
    condition     = var.scale_up_number_of_tasks >= 1
    error_message = "The scale up number of tasks must be greater than or equal to 1."
  }
}


variable "scale_down_number_of_tasks" {
  description = "The number of tasks to scale down by"
  type        = number
  default     = -1

  validation {
    condition     = var.scale_down_number_of_tasks <= -1
    error_message = "The scale down number of tasks must be smaller than or equal to -1."
  }
}

variable "minimum_tasks" {
  default     = 1
  type        = number
  description = "The minimum number of tasks to scale down to"
}

variable "maximum_tasks" {
  default     = 10
  type        = number
  description = "The maximum number of tasks to scale up to"
}

variable "schedule_scale_in" {
  default     = ""
  type        = string
  description = "The schedule to scale in the service (e.g. 0 0 * * ? *)"
}

variable "schedule_scale_in_base_tasks" {
  default     = 1
  type        = number
  description = "The minimum number of tasks to scale in to periodically"
}

variable "schedule_scale_out" {
  default     = ""
  type        = string
  description = "The schedule to scale out the service (e.g. 0 0 * * ? *)"
}

variable "schedule_scale_out_base_tasks" {
  default     = 1
  type        = number
  description = "The maximum number of tasks to scale out to periodically"
}

variable "additional_alarm_actions_scale_up" {
  description = "Additional alarm actions to be added to the CloudWatch alarm for scaling up"
  type        = list(string)
  default     = []
}


variable "additional_alarm_actions_scale_down" {
  description = "Additional alarm actions to be added to the CloudWatch alarm for scaling down"
  type        = list(string)
  default     = []
}