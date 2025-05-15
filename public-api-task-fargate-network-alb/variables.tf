variable "environment" {
  type        = string
  description = "The environment name (e.g. dev, staging, prod)"
}

variable "exposed_port" {
  type = number
}

variable "task_name" {
  type        = string
  description = "The name of the task"
}

variable "should_wait_untill_complete" {
  type = bool
  default = false
  description = "terraform will check if the task in started or not"
}

variable "image" {
  type        = string
  description = "The image to run in the container"
}

variable "environment_vars" {
  type        = map(string)
  description = "A map of environment variables to be passed to the container"
}

variable "secret_vars" {
  type        = map(string)
  description = "A map of secret variables to be passed to the container"
  default     = {}
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

variable "gpu" {
  type        = number
  description = "The amount of GPU units to reserve for the task"
  default     = 0

  validation {
    condition     = var.gpu == 0 || var.gpu == 1
    error_message = "The number of GPUs must be either 0 or 1."
  }
}

variable "command" {
  type        = list(string)
  description = "The command to run in the container"
}

variable "desired_count" {
  type        = number
  description = "The number of instances of the task to run"
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

variable "certificate_arn" {
  type        = string
  description = "The ARN of the certificate to use for the listener"
}

variable "container_port" {
  description = "The port number on which the containers are listening"
  type        = number
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

variable "timeout" {
  description = "The amount of time to wait for a timeout response from a target"
  type        = number
}

variable "unhealthy_threshold" {
  description = "The number of consecutive failed health checks required to mark a target as unhealthy"
  type        = number
}

variable "public_subnet_ids" {
  description = "The IDs of the public subnets in which the LB listener will be created"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "The IDs of the private subnets in which the ECS service will be created"
  type        = list(string)
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

variable "container_health_check" {
  description = "Health check configuration for the container"
  type = object({
    command     = list(string)
    interval    = number
    timeout     = number
    retries     = number
    startPeriod = number
  })
  default = null
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

variable "docker_labels" {
  description = "the docker label map for ECS task"
  type        = map(string)
  default     = null
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for the ECS task"
}


variable "slack_endpoint" {
  description = "Slack endpoint for alerts"
  type        = string
}


variable "enable_lb" {
  description = "should we enable loadbalancer"
  type = bool
  default = true
}

variable "is_internal_load_balancer" {
  type = bool
  description = "is internal loadbalancer"
  default = false
}


variable "ecs_service_connect_namespace_arn" {
  type = string
  default = ""
  description = "if you are using service connect please specify the arn"
}

variable "efs_id" {
  type        = string
  description = "The ID of the EFS filesystem (required)"
  default = ""
}

variable "efs_name" {
  type        = string
  default     = null
  description = "Optional name tag for the EFS volume"
}

variable "efs_access_point_id" {
  type        = string
  description = "The ID of the EFS access point (required)"
  default = ""
}

variable "mount_container_path" {
  type        = string
  default     = "/"
  description = "Container path where EFS should be mounted"

  validation {
    condition     = can(regex("^/", var.mount_container_path))
    error_message = "Mount path must start with '/'"
  }
}

variable "root_directory" {
  type        = string
  default     = "/"
  description = "Root directory path in EFS"

  validation {
    condition     = can(regex("^/", var.root_directory))
    error_message = "Root directory must start with '/'"
  }
}

variable "transit_encryption" {
  type        = string
  default     = "ENABLED"
  description = "Whether to enable EFS transit encryption (ENABLED/DISABLED)"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.transit_encryption)
    error_message = "Must be either 'ENABLED' or 'DISABLED'"
  }
}

variable "iam_authorization" {
  type        = string
  default     = "ENABLED"
  description = "Whether to enable IAM authorization (ENABLED/DISABLED)"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.iam_authorization)
    error_message = "Must be either 'ENABLED' or 'DISABLED'"
  }
}

variable "read_only" {
  type        = bool
  default     = false
  description = "Whether the EFS mount should be read-only"
}