locals {
  environment = var.config.environment
  task_name   = var.config.task_name
  name        = "${local.environment}-${local.task_name}"
  environment_variables = [
    for k, v in var.config.environment_vars : {
      name  = k
      value = v
    }
  ]
  secrets = [
    for k, v in var.config.secret_vars : {
      name      = k
      valueFrom = v
    }
  ]
  tags = merge({
    Name = local.name
  }, var.config.tags)
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${local.name}-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = var.config.cpu
  memory                   = var.config.memory
  task_role_arn            = var.config.task_role_arn
  execution_role_arn       = var.config.execution_role_arn
  container_definitions = jsonencode([{
    name         = var.config.container_name
    image        = var.config.image
    essential    = true
    environment  = local.environment_variables
    command      = var.config.command
    healthCheck  = var.container_health_check
    stopTimeout  = var.config.stopTimeout
    dockerLabels = var.config.docker_labels != null ? var.config.docker_labels : null
    portMappings = [{
      protocol      = "tcp"
      containerPort = tonumber(var.config.container_port)
      hostPort      = 0
    }]
    ulimits = [{
      name      = "nofile"
      softLimit = 65535
      hardLimit = 65535
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.config.log_group
        awslogs-stream-prefix = "ecs"
        awslogs-region        = var.config.log_aws_region
      }
    }
    secrets = local.secrets
  }])
  tags = local.tags
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


resource "aws_ecs_service" "service" {
  name            = "${local.name}-service"
  cluster         = var.config.ecs_cluster_id
  task_definition = "${aws_ecs_task_definition.task.family}:${max(aws_ecs_task_definition.task.revision, 0)}"


  desired_count                      = var.config.desired_count
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_ecs_managed_tags            = true

  health_check_grace_period_seconds = 300
  force_new_deployment              = true

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.instance-type ${var.config.instance_type_matcher}"
  }

  capacity_provider_strategy {
    capacity_provider = var.config.capacity_provider_name
    weight            = 100
  }


  placement_constraints {
    type       = "distinctInstance"
    expression = ""
  }

  load_balancer {
    target_group_arn = var.config.load_balancer_target_group_arn
    container_name   = var.config.container_name
    container_port   = var.config.container_port
  }

  deployment_circuit_breaker {
    enable   = var.config.deployment_circuit_breaker_enable
    rollback = var.config.deployment_circuit_breaker_rollback
  }

  tags = local.tags
  lifecycle {
    create_before_destroy = true
  }

  dynamic "service_registries" {
    for_each = var.enable_service_registry ? [1] : []
    content {
      registry_arn   = var.service_registry_arn
      container_port = var.config.container_port
      container_name = var.config.container_name
    }
  }
}
