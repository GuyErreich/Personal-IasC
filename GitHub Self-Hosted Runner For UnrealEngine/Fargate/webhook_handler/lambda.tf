resource "aws_lambda_function" "webhook_handler" {
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  filename         = var.lambda_zip_path
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = var.lambda_handler
  runtime          = var.runtime
  timeout          = var.timeout

  layers = var.lambda_layers

  environment {
    variables = var.lambda_function_env_vars
  }
}
