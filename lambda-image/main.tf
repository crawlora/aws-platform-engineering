data "aws_iam_policy" "aws_xray_write_only_access_application" {
  arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_lambda_function" "application" {
  publish       = false
  function_name = "${var.project_name}-${var.app}-${var.environment}"
  image_uri     = var.image_uri
  package_type  = var.package_type
  role          = aws_iam_role.iam_for_lambda.arn

  memory_size = var.lambda_memory
  timeout     = var.lambda_time_out

  ephemeral_storage {
    size = var.lambda_epermal_memory # Min 512 MB and the Max 10240 MB
  }

  environment {
    variables = var.environment_vars
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.log_group,
    aws_iam_role_policy_attachment.ecr_pull_policy
  ]

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = "${var.environment}"
    Project     = var.project_name
    App         = var.app
    Role        = "lambda"
  }

  tracing_config {
    #!@link: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function#mode
    mode = var.enable_xray ? "Active" : "PassThrough"
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda-${var.app}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = "${var.environment}"
    Project     = var.project_name
    App         = var.app
    Role        = "lambda"
  }
}

resource "aws_iam_role_policy_attachment" "application" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = data.aws_iam_policy.aws_xray_write_only_access_application.arn
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${var.project_name}-${var.app}-${var.environment}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = "${var.environment}"
    Project     = var.project_name
    App         = var.app
    Role        = "lambda"
  }
}


resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda-logging-${var.app}-${var.environment}"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = "${var.environment}"
    Project     = var.project_name
    App         = var.app
    Role        = "lambda"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "ecr_pull_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "s3_access_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "sqs_access_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_lambda_event_source_mapping" "maps" {
  count            = length(var.sqs_arns)
  event_source_arn = element(var.sqs_arns, count.index)
  batch_size       = var.batch_size
  function_name    = aws_lambda_function.application.arn

  scaling_config {
    maximum_concurrency = var.maximum_concurrency
  }
}

