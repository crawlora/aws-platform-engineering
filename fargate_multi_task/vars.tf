variable "environment" {
  type        = string
  description = "The environment name (e.g. dev, staging, prod)"
}

variable "task_name" {
  type        = string
  description = "The name of the task"
}

variable "container_definitions" {
  type        = any
  description = "Config definitions for a containers, which will run in the task as JSON"
}

variable "container_service_name" {
  type        = any
  description = "name of the main container which communicates as a service"
}

variable "secret_arns" {
  type        = list(string)
  description = "A list of secret arns to be passed to the iam policy to allow ssm reading"
  default     = []
}

variable "cpu" {
  type        = string
  description = "The amount of CPU units to reserve for the task"
}

variable "memory" {
  type        = string
  description = "The amount of memory to reserve for the task"
}

variable "ephemeral_storage" {
  default     = 21
  type        = number
  description = "The amount of ephemeral storage disk size to reserve for the task"
}

variable "desired_count" {
  type        = number
  description = "The number of instances of the task to run"
}

variable "container_port" {
  description = "The port number on which the containers are listening"
  type        = number
}
variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to AWS resources"
}

variable "context" {
  type        = string
  description = "The context of the deployment (e.g. ci, cd)"
}

variable "aws_region" {
  type        = string
  description = "The AWS region to use for the task"
}

variable "ecs_cluster_id" {
  type        = string
  description = "The ID of the ECS cluster to deploy the task to"
}

variable "ecs_cluster_name" {
  type        = string
  description = "The name of the ECS cluster to deploy the task to"
}

variable "efs_id" {
  type        = string
  description = "The ID of the EFS file system"
}

variable "efs_name" {
  type        = string
  description = "The name of the EFS file system"
}

variable "vpc_id" {
  description = "The ID of the VPC in which the target group will be created"
  type        = string
}

variable "healthy_threshold" {
  description = "The number of consecutive successful health checks required to mark a target as healthy"
  type        = number
}

variable "interval" {
  description = "The duration between health checks"
  type        = number
}

variable "health_code" {
  description = "The HTTP codes to use when checking for a successful response from a target"
  type        = string
}

variable "health_path" {
  description = "The destination path for the health check request"
  type        = string
}

variable "timeout" {
  description = "The amount of time to wait for a timeout response from a target"
  type        = number
}

variable "unhealthy_threshold" {
  description = "The number of consecutive failed health checks required to mark a target as unhealthy"
  type        = number
}

variable "private_subnet_ids" {
  description = "The IDs of the private subnets in which the target group will be created"
  type        = list(string)
}

variable "internal_zone_id" {
  description = "The ID of the Route53 internal zone in which the DNS record will be created"
  type        = string
}

# Autoscaling

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

variable "scale_in_cooldown" {
  default     = 60
  type        = number
  description = "The amount of time, in seconds, after a scale in activity completes before another scale in activity can start"
}

variable "scale_out_cooldown" {
  default     = 60
  type        = number
  description = "The amount of time, in seconds, after a scale out activity completes before another scale out activity can start"
}

variable "average_cpu_utilization" {
  default     = 0
  type        = number
  description = "The average CPU utilization threshold to trigger scaling"

  validation {
    condition     = var.average_cpu_utilization >= 0 && var.average_cpu_utilization <= 100
    error_message = "The average CPU utilization threshold must be between 0 and 100."
  }
}

variable "average_mem_utilization" {
  default     = 0
  type        = number
  description = "The average memory utilization threshold to trigger scaling"

  validation {
    condition     = var.average_mem_utilization >= 0 && var.average_mem_utilization <= 100
    error_message = "The average memory utilization threshold must be between 0 and 100."
  }
}

variable "average_requests_per_service" {
  default     = 0
  type        = number
  description = "The average requests per service threshold to trigger scaling"

  validation {
    condition     = var.average_requests_per_service >= 0 && var.average_requests_per_service <= 25000
    error_message = "The average requests per service threshold must be greater than or equal to 0."
  }
}

variable "enable_service_registry" {
  description = "Whether to enable service registry"
  type        = bool
  default     = false
}

variable "service_registry_arn" {
  description = "ARN of the service registry"
  type        = string
  default     = ""
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for the ECS task"
}

variable "slack_endpoint" {
  description = "Slack endpoint for alerts"
  type        = string
}