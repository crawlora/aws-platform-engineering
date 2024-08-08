locals {
  name           = "${var.environment}-${var.task_name}"
  container_name = "${local.name}-api-service"
  environment_variables = [
    for k, v in var.environment_vars : {
      name  = k
      value = v
    }
  ]
  secrets = [
    for k, v in var.secret_vars : {
      name      = k
      valueFrom = v
    }
  ]
  tags = merge({
    Name = local.name
  }, var.tags)
}


data "aws_iam_policy_document" "ecs_task_role_data" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${local.name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_data.json
}

resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "${local.name}-ecs-task-execution-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "autoscaling:*",
          "ecr:*",
          "s3:*",
          "sqs:*",
          "ecs:*",
          "elasticfilesystem:*",
          "elasticache:*",
        ]
        Resource = "*"
      }
      ],
      length(var.secret_arns) > 0 ? [
        {
          Effect = "Allow"
          Action = [
            "ssm:GetParameters",
            "secretsmanager:GetSecretValue"
          ]
          Resource = var.secret_arns
        }
      ] : []
    )
  })
}


module "cloudwatch_logger" {
  source  = "git::https://github.com/dataminer-site/aws-platform-engineering.git//cloudwatch?ref=main"
  version = "0.0.1"
  config = {
    environment       = var.environment
    context           = var.context
    name              = "${local.name}-cloudwatch-logger"
    retention_in_days = 14
  }
}

resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "${local.name}-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  cpu                = var.cpu
  memory             = var.memory
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_task_role.arn
  volume {
    name = var.efs_name
    efs_volume_configuration {
      file_system_id = var.efs_id
      root_directory = "/"
    }
  }
  container_definitions = jsonencode([{
    name         = "${local.name}-api-service"
    image        = var.image
    essential    = true
    environment  = local.environment_variables
    command      = var.command
    stopTimeout  = 120 # max value
    healthCheck  = var.container_health_check
    dockerLabels = var.docker_labels != null ? var.docker_labels : null
    portMappings = [{
      protocol      = "tcp"
      containerPort = var.container_port
    }]
    resourceRequirements = var.gpu == 0 ? [] : [
      {
        type  = "GPU"
        value = "1"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = module.cloudwatch_logger.log_group_name
        awslogs-stream-prefix = "ecs"
        awslogs-region        = var.aws_region
      }
    }
    mountPoints = [
      {
        sourceVolume  = var.efs_name
        containerPath = "/shared"
        readOnly      = false
      }
    ]
    ulimits = [{
      name      = "nofile"
      softLimit = 65535
      hardLimit = 65535
      }
    ]
    secrets = local.secrets
  }])
  tags = local.tags
  depends_on = [
    aws_iam_role.ecs_task_role
  ]
}

resource "aws_ecs_service" "ecs_service" {
  name                   = "${local.name}-api-service"
  cluster                = var.ecs_cluster_id
  task_definition        = "${aws_ecs_task_definition.ecs_task.family}:${max(aws_ecs_task_definition.ecs_task.revision, 0)}"
  launch_type            = "FARGATE"
  enable_execute_command = true
  wait_for_steady_state  = true

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = var.security_group_ids
  }

  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_ecs_managed_tags            = true

  force_new_deployment              = true
  health_check_grace_period_seconds = 30

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
    ]
  }

  tags = local.tags
  depends_on = [
    aws_iam_role.ecs_task_role
  ]

  dynamic "service_registries" {
    for_each = var.enable_service_registry ? [1] : []
    content {
      registry_arn   = var.service_registry_arn
      container_port = var.container_port
      container_name = local.container_name
    }
  }
}
