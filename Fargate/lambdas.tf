resource "aws_lambda_function" "task_failure_handler" {
  depends_on = [aws_iam_role.lambda_exec]

  source_code_hash = filebase64sha256("Lambda_Functions/archive.zip")

  filename         = "Lambda_Functions/archive.zip"
  function_name    = "task_failure_handler"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "ecs.reset_desired_count_on_repeating_failure"
  runtime          = "python3.9"

  environment {
    variables = {
      CLUSTER_NAME = module.ecs.cluster_name
      SERVICE_NAME = module.ecs.services["unreal_engine"].name // TODO: in the future might want this more dynamic with a loop over all services
    }
  }
}

resource "aws_lambda_function" "task_failure_metric_generator" {
  depends_on = [aws_iam_role.lambda_exec]
  
   # Force update when the zip_files resource changes
  source_code_hash = filebase64sha256("Lambda_Functions/archive.zip")

  filename         = "Lambda_Functions/archive.zip"
  function_name    = "task_failure_metric_generator"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "cloudwatch.generate_metrics_for_failure_alarm"
  runtime          = "python3.9"
  # layers        = [aws_lambda_layer_version.boto3_layer.arn]

  environment {
    variables = {
      CLUSTER_NAME = module.ecs.cluster_name
      SERVICE_NAME = module.ecs.services["unreal_engine"].name // TODO: in the future might want this more dynamic with a loop over all services
    }
  }
}

# resource "aws_lambda_layer_version" "boto3_layer" {
#   source_code_hash = filebase64sha256("Lambda_Functions/Layers/basic_boto3_layer.zip")

#   layer_name  = "basic-boto3-layer"
#   filename    = "Lambda_Functions/Layers/basic_boto3_layer.zip" # Path to your local zip file
#   compatible_runtimes = ["python3.9", "python3.8", "python3.7"] # Adjust based on your Lambda runtime
#   description = "Lambda layer with boto3"
# }

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# resource "aws_iam_role_policy_attachment" "lambda_cloudwatch" {
#   role       = aws_iam_role.lambda_exec.name
#   policy_arn = aws_iam_policy.lambda_put_metric.arn
# }

# resource "aws_iam_policy" "lambda_put_metric" {
resource "aws_iam_role_policy" "lambda_put_metric" {
  name = "LambdaPutMetric"
  role = aws_iam_role.lambda_exec.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:PutMetricData"
        ]
        Effect   = "Allow"
        # Resource = [
        #   "arn:aws:cloudwatch:eu-central-1:961341519925:alarm:ECS_Task_Failure_Alarm",
        #   "arn:aws:cloudwatch:eu-central-1:961341519925:metric/MetricsNamespace/*"
        # ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_ecs_update" {
  name = "LambdaECSUpdate"
  role = aws_iam_role.lambda_exec.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Effect   = "Allow"
        # Resource = [
        #   "arn:aws:cloudwatch:eu-central-1:961341519925:alarm:ECS_Task_Failure_Alarm",
        #   "arn:aws:cloudwatch:eu-central-1:961341519925:metric/MetricsNamespace/*"
        # ]
        Resource = "*"
      },
    ]
  })
}
