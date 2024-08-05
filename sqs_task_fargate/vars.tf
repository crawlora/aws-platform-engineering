variable "environment" {
  type        = string
  description = "The environment name (e.g. dev, staging, prod)"
}

variable "task_name" {
  type        = string
  description = "The name of the task"
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
  description = "A map of secrets to be passed to the container"
  default     = {}
}

variable "cpu" {
  type        = string
  description = "The amount of CPU units to reserve for the task"
}

variable "memory" {
  type        = string
  description = "The amount of memory to reserve for the task"
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

variable "efs_id" {
  type        = string
  description = "The ID of the EFS file system"
}

variable "efs_name" {
  type        = string
  description = "The name of the EFS file system"
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

variable "subnet_ids" {
  type        = list(string)
  description = "The IDs of the subnets to deploy the task to"
}

variable "security_group_ids" {
  type        = list(string)
  description = "The IDs of the security groups to apply to the task"
}