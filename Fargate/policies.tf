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
  name        = "ECSUpdateServicePolicy"
  description = "Policy to allow updating desired count of ECS service"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecs:UpdateService"
        Resource = flatten([
          # Generate service ARNs for each service in the cluster
          for service in module.ecs.services : "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${module.ecs.cluster_name}/${service.name}"
        ])
      },
      {
        Effect   = "Allow"
        Action   = "ecs:UpdateService"
        Resource = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${module.ecs.cluster_name}"
      }
    ]
  })
}