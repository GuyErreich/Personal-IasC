resource "aws_cloudwatch_metric_alarm" "ecs_task_failure_alarm" {
  alarm_name          = "ECS_Task_Failure_Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 30
  metric_name         = "EssentialContainerExited"
  namespace           = "ECS/TaskFailures"
  period              = 60
  statistic           = "Sum"
  threshold           = 2

  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = module.ecs.services["unreal_engine"].name
  }

  alarm_actions = [aws_sns_topic.task_failure_topic.arn]
}


resource "aws_sns_topic" "task_failure_topic" {
  name = "ECS_Task_Failure_Topic"
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.task_failure_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.task_failure_handler.arn
}

resource "aws_cloudwatch_event_rule" "ecs_task_stop" {
  name        = "ecs_task_stop"
  description = "Trigger when ECS tasks stop"
  event_pattern = jsonencode({
    "detail-type": ["ECS Task State Change"],
    "source": ["aws.ecs"],
    "detail": {
      "lastStatus": ["STOPPED"],
      "stopCode": ["EssentialContainerExited"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ecs_failure_alarm_lambda" {
  rule      = aws_cloudwatch_event_rule.ecs_task_stop.name
  target_id = "task_failure_metric_generator"
  arn       = aws_lambda_function.task_failure_metric_generator.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.task_failure_metric_generator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_task_stop.arn
}

