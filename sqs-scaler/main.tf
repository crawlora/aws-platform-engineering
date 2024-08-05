locals {
  name = "${var.environment}-${var.name}"
  tags = merge({
    Name        = var.name
    Environment = var.environment
  }, var.tags)
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "sqs_scaling_lambda_role" {
  name = "${local.name}_sqs_scaling_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "sqs_scaling_lambda_policy" {
  name        = "${local.name}_sqs_scaling_lambda_policy"
  description = "SQS based scaling lambda policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "ec2:*",
          "ssm:GetParameters",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:*",
          "sqs:*",
          "ecs:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sqs_scaling_lambda_policy_attachment" {
  role       = aws_iam_role.sqs_scaling_lambda_role.name
  policy_arn = aws_iam_policy.sqs_scaling_lambda_policy.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/main.py"
  output_path = "${path.module}/lambdas/main.py.zip"
}

resource "aws_lambda_function" "sqs_attributes_lambda" {
  function_name    = "${local.name}-sqs-metrics-lambda"
  role             = aws_iam_role.sqs_scaling_lambda_role.arn
  timeout          = var.lambda_timeout_in_seconds
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  handler = "main.lambda_handler"
  runtime = "python3.9"

  memory_size = 128

  depends_on = [aws_iam_role_policy_attachment.sqs_scaling_lambda_policy_attachment]

  tags = var.tags
}

resource "aws_lambda_permission" "sqs_attributes_lambda_permission" {
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  function_name = aws_lambda_function.sqs_attributes_lambda.function_name
  statement_id  = aws_cloudwatch_event_rule.sqs_attributes_rule.name
  source_arn    = aws_cloudwatch_event_rule.sqs_attributes_rule.arn
}

resource "aws_cloudwatch_event_rule" "sqs_attributes_rule" {
  name                = "${local.name}_SQS_AttributesRule"
  description         = "${local.name}_SQS_AttributesRule triggers lambda in every minute"
  schedule_expression = "cron(*/${var.run_every_minute} * * * ? *)"
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule = aws_cloudwatch_event_rule.sqs_attributes_rule.name
  arn  = aws_lambda_function.sqs_attributes_lambda.arn
  input = jsonencode({
    queue_names          = var.queue_names
    queue_weights        = var.queue_weights
    max_backlog_per_task = var.max_backlog_per_task
    account_id           = data.aws_caller_identity.current.account_id
    service_name         = var.service_name
    cluster_name         = var.ecs_cluster_name
    aws_region           = var.aws_region
  })
}

resource "aws_cloudwatch_log_group" "sqs_based_scaling_lambda_cw_log_group" {
  name              = "/lambda/${local.name}/${aws_lambda_function.sqs_attributes_lambda.function_name}"
  retention_in_days = var.cw_log_group_retention_period
  tags              = var.tags
}