variable "environment" {
  description = "The environment name for the ECS task and service"
  type        = string
}

variable "task_name" {
  description = "The name of the ECS task"
  type        = string
}

variable "context" {
  description = "The context name for the ECS task and service"
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to AWS resources"
}

variable "image" {
  description = "The Docker image to use for the ECS task"
  type        = string
}

variable "desired_count" {
  description = "The desired number of ECS tasks to run"
  type        = number
}

variable "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  type        = string
}

variable "cpu" {
  description = "The CPU units to allocate for the ECS task"
  type        = string
}

variable "memory" {
  description = "The memory to allocate for the ECS task"
  type        = string
}

variable "command" {
  description = "The command to execute in the ECS task"
  type        = list(string)
}

variable "container_ports" {
  description = "The container ports to expose for the ECS task"
  type        = list(number)
}

variable "load_balancer_target_group_arns" {
  description = "The ARNs of the target groups for the ECS service"
  type        = list(string)
}

# Optional variables with default values
variable "instance_type_matcher" {
  description = "The instance type matcher for the ECS service placement constraints"
  type        = string
  default     = "t2.micro"
}

variable "capacity_provider_name" {
  description = "The name of the capacity provider for the ECS service"
  type        = string
}

variable "aws_region" {
  description = "The AWS region for the ECS service"
  type        = string
  default     = "us-west-2"
}

# Maps of environment and secret variables
variable "environment_vars" {
  description = "A map of environment variables to pass to the ECS task"
  type        = map(string)
  default     = {}
}

variable "secret_vars" {
  description = "A map of secret variables to pass to the ECS task"
  type        = map(string)
  default     = {}
}

# ARNs of secrets to allow access to
variable "secret_arns" {
  description = "A list of ARNs of secrets to allow access to"
  type        = list(string)
}

# EFS volume settings
variable "efs_id" {
  description = "The ID of the EFS file system to mount"
  type        = string
}

variable "efs_name" {
  description = "The name of the EFS volume to create"
  type        = string
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