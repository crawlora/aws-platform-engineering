locals {
  log_group_name = "${var.config.context}/${var.config.environment}/${var.config.name}"
}

resource "aws_cloudwatch_log_group" "cloudwatch_logger" {
  name = local.log_group_name

  retention_in_days = var.config.retention_in_days
}

