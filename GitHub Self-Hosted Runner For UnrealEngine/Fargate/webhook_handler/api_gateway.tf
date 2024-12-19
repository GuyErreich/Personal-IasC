resource "aws_apigatewayv2_api" "webhook_api" {
  name          = "github_webhook_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.webhook_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.webhook_handler.invoke_arn
}

resource "aws_apigatewayv2_route" "webhook_route" {
  api_id    = aws_apigatewayv2_api.webhook_api.id
  route_key = "POST /webhook"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.webhook_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_log_group.arn
    format          = jsonencode({
      requestId     = "$context.requestId",
      ip            = "$context.identity.sourceIp",
      method        = "$context.httpMethod",
      resourcePath  = "$context.resourcePath",
      status        = "$context.status",
      responseTime  = "$context.responseLatency"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  name = "/aws/apigateway/github_webhook_api_logs"
}
