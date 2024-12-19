module "github_webhook_handler" {
    depends_on = [ aws_lambda_layer_version.requests_layer ]
    source                  = "./webhook_handler"

    api_name                = "GitHubWebhookHandler"
    lambda_zip_path         = "${var.lambda_zip}"
    lambda_function_name    = "GitHubWebhookHandler"
    lambda_handler          = "github_webhook.handler"

    lambda_layers = [aws_lambda_layer_version.requests_layer.arn]

    lambda_function_env_vars = {
      GITHUB_WEBHOOK_TOKEN = jsondecode(data.aws_secretsmanager_secret_version.github_webhook_token.secret_string)["Token"]
      GITHUB_ACCESSES_TOKEN = jsondecode(data.aws_secretsmanager_secret_version.github_runner_token.secret_string)["Token"]
      CLUSTER_NAME  = module.ecs.cluster_name 
      SERVICE_NAME  = module.ecs.services["unreal_engine"].name // TODO: in the future might want this more dynamic with a loop over all services
    }

    lambda_iam_role_policies = [
      {
        Effect   = "Allow"
        Action   = [
          "ecs:UpdateService", 
          "ecs:DescribeServices"
        ]
        Resource = flatten([
          for service in module.ecs.services : service.id
        ])
      },
      {
        Effect   = "Allow"
        Action   = [
          "ecs:ListTasks"
        ]
        Resource = flatten([
          for service in module.ecs.services : "arn:aws:ecs:${local.current_region}:${local.current_account}:container-instance/${module.ecs.cluster_name}/*"
        ])
      },
      {
        Effect   = "Allow"
        Action   = [
          "ecs:DescribeTasks"
        ]
        Resource = flatten([
          for service in module.ecs.services : "arn:aws:ecs:${local.current_region}:${local.current_account}:task/${module.ecs.cluster_name}/*"
        ])
      }
    ]
}

resource "aws_lambda_layer_version" "requests_layer" {
  source_code_hash = filebase64sha256("${var.lambda_layer_zip}")
  
  filename          = "${var.lambda_layer_zip}" # Path to the packaged layer zip file
  layer_name        = "requests_layer"
  compatible_runtimes = ["python3.9"]                    # Update the runtime version as needed
  description       = "Lambda layer with requests library"
}