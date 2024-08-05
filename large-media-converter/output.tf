
output "mediaconvert_role_arn" {
  value = aws_iam_role.mediaconvert_role.arn
}

output "video_complete_sns_topic_arn" {
  value = aws_sns_topic.large-media-upload-updates.arn
}

output "video_lambda_docker_repository_url" {
  value = aws_ecr_repository.lambda_repository.repository_url
}

output "video_lambda_docker_image_tag" {
  value = local.image_tag
}

output "video_submit_lambda_name" {
  value = aws_lambda_function.video_submit_lambda.function_name
}

output "video_complete_lambda-name" {
  value = aws_lambda_function.video_complete_lambda.function_name
}

output "input_bucket_name" {
  value = aws_s3_bucket.media-input-bucket.bucket
}

output "input_bucket_arn" {
  value = aws_s3_bucket.media-input-bucket.arn
}

output "output_bucket_name" {
  value = local.output_bucket
}

output "output_bucket_arn" {
  value = local.output_bucket_arn
}

output "ingress_gateway_url" {
  value = aws_apigatewayv2_stage.ingress-api.invoke_url
}

output "ingress_gateway_api_initialize" {
  value = aws_apigatewayv2_route.initialize.route_key
}

output "ingress_gateway_api_presign" {
  value = aws_apigatewayv2_route.presign.route_key
}

output "ingress_gateway_api_finalize" {
  value = aws_apigatewayv2_route.finalize.route_key
}

output "ingress_gateway_api_mediainfo" {
  value = aws_apigatewayv2_route.mediainfo.route_key
}

output "auth_token" {
  value     = local.auth_token
  sensitive = true
}

output "supported_filetypes" {
  value = local.all_suffixes
}