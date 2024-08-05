resource "aws_cloudwatch_log_group" "ingress-api" {
  name              = "/aws/lambda/${local.name}-ingress-api"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "video_submit_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.video_submit_lambda.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "video_complete_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.video_complete_lambda.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "process_image" {
  name              = "/aws/lambda/${aws_lambda_function.process_image.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "process_audio" {
  name              = "/aws/lambda/${aws_lambda_function.process_audio.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "initialize" {
  name              = "/aws/lambda/${aws_lambda_function.initialize.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "presigned_urls" {
  name              = "/aws/lambda/${aws_lambda_function.presigned_urls.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "finalize" {
  name              = "/aws/lambda/${aws_lambda_function.finalize.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "auth" {
  name              = "/aws/lambda/${aws_lambda_function.auth.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "mediainfo" {
  name              = "/aws/lambda/${aws_lambda_function.mediainfo.function_name}"
  retention_in_days = 30
}