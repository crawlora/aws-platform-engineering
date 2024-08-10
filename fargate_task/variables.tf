variable "config" {
  type = object({
    environment = string
    context     = string
    task_name = string
    image = string
    environment_vars = map(string)
    secret_vars = map(string)
    cpu = string
    memory = string
    command = list(string)
    desired_count = number
    tags = map(string)
    context = string
    aws_region = string
    ecs_cluster_id = string
    container_health_check = map(object)
    private_subnet_ids = list(string)
    security_group_ids = list(string)
  })
}