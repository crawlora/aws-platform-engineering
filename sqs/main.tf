
locals {
  maxRetry = var.maxRetry
  appName = "${var.projectName}-${var.app}-${var.environment}"
}

resource "aws_sqs_queue" "q" {
  name                       = local.appName
  visibility_timeout_seconds = var.lambda_time_out

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = local.maxRetry
  })

  tags = {
    Name        = "${var.projectName}-${var.environment}"
    Environment = "${var.environment}"
    Project     = var.projectName
    App         = var.app
    Role        = "sqs"
  }
}



resource "aws_sqs_queue" "dlq" {
  visibility_timeout_seconds = var.lambda_time_out
  name                       = "${local.appName}-deadletter-queue"

  tags = {
    Name        = "${local.appName}"
    Environment = "${var.environment}"
    Project     = var.projectName
    App         = var.app
    Role        = "sqs"
    IS_DLQ      = "true"
  }
}


resource "aws_sqs_queue_redrive_allow_policy" "retry" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns = [
      aws_sqs_queue.q.arn
    ]
  })

}


output "q" {
  value = {
    q = aws_sqs_queue.q
    dlq  = aws_sqs_queue.dlq
  }
}
