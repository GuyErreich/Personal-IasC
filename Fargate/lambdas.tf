resource "aws_lambda_function" "task_failure_handler" {
  depends_on = [aws_iam_role.lambda_exec]

  # Force update when the zip_files resource changes
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

  environment {
    variables = {
      CLUSTER_NAME = module.ecs.cluster_name
      SERVICE_NAME = module.ecs.services["unreal_engine"].name // TODO: in the future might want this more dynamic with a loop over all services
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  depends_on = [ 
    aws_lambda_function.task_failure_metric_generator,
    aws_cloudwatch_event_rule.ecs_task_stop
  ]

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.task_failure_metric_generator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_task_stop.arn
}

resource "aws_lambda_permission" "allow_sns_to_invoke_lambda" {
  depends_on = [ 
    aws_lambda_function.task_failure_handler,
    aws_sns_topic.task_failure_topic
  ]

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.task_failure_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.task_failure_topic.arn
}

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

resource "aws_iam_role_policy" "lambda_put_metric" {
  name = "LambdaPutMetric"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:PutMetricData"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_ecs_update" {
  name = "LambdaECSUpdate"
  role = aws_iam_role.lambda_exec.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
