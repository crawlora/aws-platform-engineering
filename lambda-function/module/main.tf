locals {
  lambda_function_name = var.config.lambda_function_name
  handler              = var.config.handler
  runtime              = var.config.runtime
  source_type          = var.config.python_file_path != null ? "file" : "directory"
  source_path          = var.config.python_file_path != null ? var.config.python_file_path : var.config.python_folder_path
  zip_lambda_path      = "${path.module}/function_payload.zip"
  memory_size          = var.config.memory_size
}

resource "aws_iam_role" "lambda_role" {
  name = "LambdaExecutionRole-${local.lambda_function_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.this.output_path
  function_name    = local.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = local.handler
  runtime          = local.runtime
  source_code_hash = data.archive_file.this.output_base64sha256
  memory_size      = local.memory_size
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = local.source_type == "directory" ? local.source_path : null
  source_file = local.source_type == "file" ? local.source_path : null
  output_path = local.zip_lambda_path
  depends_on  = [null_resource.install_requirements]
}

resource "null_resource" "install_requirements" {
  count = local.source_type == "directory" ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
      pip3.11 install \
        -r ${local.source_path}/requirements.txt \
        -t ${local.source_path}
    EOF
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}