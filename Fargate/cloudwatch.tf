resource "aws_cloudwatch_log_metric_filter" "ecs_task_failure" {
  log_group_name = "/ecs/${module.ecs.cloudwatch_log_group_name}"

  name           = "ECS_Task_Failure"
  pattern        = "{ $.reason = \"EssentialContainerExited\" }"

  metric_transformation {
    name      = "ECSFailedTasks"
    namespace = "ECS"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_task_failure_alarm" {
  alarm_name          = "ECS_Task_Failure_Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 30
  threshold           = 2  # Set based on acceptable retries
  metric_name         = "ECSFailedTasks"
  namespace           = "ECS"
  period              = 60

  alarm_actions       = [aws_sns_topic.task_failure_topic.arn]
}

resource "aws_cloudwatch_log_metric_filter" "ecs_running_task_count" {
  log_group_name = "/ecs/${module.ecs.cloudwatch_log_group_name}"

  name           = "ECS_Running_Task_Count"
  pattern        = "{ $.desiredStatus = \"RUNNING\" }"

  metric_transformation {
    name      = "ECSRunningTaskCount"
    namespace = "ECS"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_running_task_count_alarm" {
  alarm_name          = "ECS_Running_Task_Count_Alarm"
  comparison_operator = "NotEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1  # We expect only 1 running task
  metric_name         = "ECSRunningTaskCount"
  namespace           = "ECS"
  period              = 60  # Check every minute

  alarm_actions       = [aws_sns_topic.task_failure_topic.arn]
}

resource "aws_sns_topic" "task_failure_topic" {
  name = "ECS_Task_Failure_Topic"
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.task_failure_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.task_failure_handler.arn
}

