output "api_endpoint" {
  value       = aws_apigatewayv2_api.webhook_api.api_endpoint
  description = "The endpoint for the API Gateway"
}

output "lambda_function_arn" {
  value       = aws_lambda_function.webhook_handler.arn
  description = "The ARN of the Lambda function"
}
