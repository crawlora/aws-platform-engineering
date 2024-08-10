locals {
  name = "${var.config.environment}-${var.config.task_name}"
  environment_variables = [
    for k, v in var.config.environment_vars : {
      name  = k
      value = v
    }
  ]
  tags = merge({
    Name = local.name
  }, var.config.tags)

  secrets = [
    for k, v in var.config.secret_vars : {
      name      = k
      valueFrom = v
    }
  ]
  secret_arns = [
  for k, v in var.config.secret_vars : v]

  has_secrets = length(local.secret_arns) > 0
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

data "aws_iam_policy_document" "ecs_task_execution_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "autoscaling:*",
      "ecr:*",
      "s3:*",
      "sqs:*",
      "ecs:*",
      "elasticfilesystem:*",
      "elasticache:*",
      "events:*"
    ]
    resources = ["*"]
  }
  dynamic "statement" {
    for_each = local.has_secrets ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue"
      ]
      resources = local.secret_arns
    }
  }
}
resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name   = "${local.name}-ecs-task-execution-policy"
  policy = data.aws_iam_policy_document.ecs_task_execution_policy.json
  role   = aws_iam_role.ecs_task_role.id
}


module "cloudwatch_logger" {
  # source = "git.oxolo.com/platformengineering/cloudwatch/aws"
  # version = "0.0.1"
  source = "../cloudwatch"
  config = {
    environment       = var.config.environment
    context           = var.config.context
    name              = "${local.name}-cloudwatch-logger"
    retention_in_days = 14
  }
}



resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "${local.name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.config.cpu
  memory                   = var.config.memory
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  # volume {
  #   name = var.efs_name

  #   efs_volume_configuration {
  #     file_system_id = var.efs_id
  #     root_directory = "/"
  #   }
  # }
  container_definitions = jsonencode([{
    name        = "${local.name}-service"
    image       = var.image
    essential   = true
    environment = local.environment_variables
    command     = var.config.command
    stopTimeout = 120 # max value
    healthCheck = var.config.container_health_check
    # resourceRequirements = var.gpu == 0 ? [] : [
    #   {
    #     type  = "GPU"
    #     value = "1"
    #   }
    # ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = module.cloudwatch_logger.log_group_name
        awslogs-stream-prefix = "ecs"
        awslogs-region        = var.config.aws_region
      }
    }
    # mountPoints = [
    #   {
    #     sourceVolume  = var.efs_name
    #     containerPath = "/shared"
    #     readOnly      = false
    #   }
    # ]
    # secrets = local.secrets
  }])
  tags = local.tags
}

resource "aws_ecs_service" "ecs_service" {
  name                  = "${local.name}-service"
  cluster               = var.config.ecs_cluster_id
  task_definition       = "${aws_ecs_task_definition.ecs_task.family}:${max(aws_ecs_task_definition.ecs_task.revision, 0)}"
  launch_type           = "FARGATE"
  wait_for_steady_state = true

  network_configuration {
    subnets         = var.config.private_subnet_ids
    security_groups = var.config.security_group_ids
  }
  desired_count                      = var.config.desired_count
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  enable_ecs_managed_tags            = true

  force_new_deployment = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = local.tags
  lifecycle {
    create_before_destroy = true
  }
}

output "service_name" {
  value = aws_ecs_service.ecs_service.name
}
