variable "config" {
  type = object({
    environment    = string
    task_name      = string // name of the task
    image          = string
    log_aws_region = string // required for log region
    ecs_cluster_id = string
    // ecs_service_role comes from ecs
    // ecs_service_role=string
    load_balancer_target_group_arn = string
    container_name                 = string
    container_port                 = string
    log_group                      = string
    command                        = list(string) //the command to execute
    stopTimeout                    = optional(number, 30)
    desired_count                  = number
    cpu                            = number
    memory                         = number

    // role for executing the task
    execution_role_arn = string
    // role for running the task
    task_role_arn = string

    environment_vars = map(string)

    //
    secret_vars = optional(map(string), {})

    // deployment_circuit_breaker
    deployment_circuit_breaker_enable   = optional(bool, true)
    deployment_circuit_breaker_rollback = optional(bool, true)

    tags = map(string)
    // Optional Docker labels for the container
    docker_labels          = optional(map(string), null)
    instance_type_matcher  = optional(string, null)
    capacity_provider_name = optional(string, null)
  })
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
}