locals {
  cluster_name = "${var.config.environment}-${var.config.context}"
}

module "ecs_cloudwatch" {
  source  = "git.oxolo.com/platformengineering/cloudwatch/aws"
  version = "0.0.1"
  config = {
    context           = var.config.context
    environment       = var.config.environment
    retention_in_days = 7
    name              = "ecs"
  }

}
# Name of the cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name = module.ecs_cloudwatch.log_group_name
      }
    }
  }
}
