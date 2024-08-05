resource "aws_apigatewayv2_api" "ingress-api" {
  name          = "${var.name}-ingress-api"
  protocol_type = "HTTP"
  description   = "Ingress API for ${local.name}"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "ingress-api" {
  api_id = aws_apigatewayv2_api.ingress-api.id

  name        = "${var.name}-ingress-api"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.ingress-api.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

# Integrations

## Initialize

resource "aws_apigatewayv2_integration" "initialize" {
  api_id = aws_apigatewayv2_api.ingress-api.id

  integration_uri    = aws_lambda_function.initialize.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"

}

resource "aws_apigatewayv2_route" "initialize" {
  api_id = aws_apigatewayv2_api.ingress-api.id

  route_key = "POST /initialize"
  target    = "integrations/${aws_apigatewayv2_integration.initialize.id}"

  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.auth.id
}

resource "aws_lambda_permission" "initialize" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.initialize.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.ingress-api.execution_arn}/*/*"
}

## Presign

resource "aws_apigatewayv2_integration" "presign" {
  api_id = aws_apigatewayv2_api.ingress-api.id

  integration_uri    = aws_lambda_function.presigned_urls.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"

}

resource "aws_apigatewayv2_route" "presign" {
  api_id = aws_apigatewayv2_api.ingress-api.id

  route_key = "POST /presign"
  target    = "integrations/${aws_apigatewayv2_integration.presign.id}"

  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.auth.id
}

resource "aws_lambda_permission" "presign" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presigned_urls.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.ingress-api.execution_arn}/*/*"
}

## Finalize

resource "aws_apigatewayv2_integration" "finalize" {
  api_id = aws_apigatewayv2_api.ingress-api.id

  integration_uri    = aws_lambda_function.finalize.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"

}

resource "aws_apigatewayv2_route" "finalize" {
  api_id = aws_apigatewayv2_api.ingress-api.id

  route_key = "POST /finalize"
  target    = "integrations/${aws_apigatewayv2_integration.finalize.id}"

  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.auth.id
}

resource "aws_lambda_permission" "finalize" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.finalize.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.ingress-api.execution_arn}/*/*"
}

# Auth

resource "aws_apigatewayv2_authorizer" "auth" {
  api_id                            = aws_apigatewayv2_api.ingress-api.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.auth.invoke_arn
  identity_sources                  = ["$request.header.${var.auth_header}"]
  name                              = "${local.name}-ingress-api-auth"
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
}

resource "aws_lambda_permission" "auth" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.ingress-api.execution_arn}/*/*"
}

## mediainfo

resource "aws_apigatewayv2_integration" "mediainfo" {
  api_id = aws_apigatewayv2_api.ingress-api.id

  integration_uri    = aws_lambda_function.mediainfo.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"

}

resource "aws_apigatewayv2_route" "mediainfo" {
  api_id = aws_apigatewayv2_api.ingress-api.id

  route_key = "POST /mediainfo"
  target    = "integrations/${aws_apigatewayv2_integration.mediainfo.id}"

  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.auth.id
}

resource "aws_lambda_permission" "mediainfo" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mediainfo.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.ingress-api.execution_arn}/*/*"
}