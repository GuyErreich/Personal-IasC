resource "aws_iam_policy" "ecr_pull_accesses" {
  name = "ECRPullAccessesPolicy"
  description = "Policy to allow pulling images from the ecr"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_update_service_policy" {
  depends_on = [ module.ecs ]

  name        = "ECSUpdateServicePolicy"
  description = "Policy to allow updating desired count of ECS service"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
        ]
        Resource = flatten([
          for service in module.ecs.services : service.id
        ])
      },
      {
        Effect   = "Allow"
        Action   = [
          "ecs:DescribeTasks",
          "ecs:StopTask"
        ]
        Resource = flatten([
          for service in module.ecs.services : "arn:aws:ecs:${local.current_region}:${local.current_account}:task/${module.ecs.cluster_name}/*"
        ])
      },
    ]
  })
}