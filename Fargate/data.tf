data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_regions" "available" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "github_token" {
  name = "github_runner"  # Replace with the name of your secret
}

data "aws_secretsmanager_secret_version" "github_accesses_token" {
  secret_id = data.aws_secretsmanager_secret.github_token.id
}

data "aws_ecr_repository" "existing_repos" {
  for_each = var.ecr_repositories

  name = each.value
}

data "aws_ecr_image" "unreal_engine" {
  depends_on = [ module.ecr_repos ]
  repository_name = "ci-cd/unreal-engine"
  image_tag       = "runner-5.4.4"
}

data "aws_secretsmanager_secret" "github_runner_secret" {
  name = "github_runner"
}

data "aws_secretsmanager_secret_version" "github_runner_token" {
  secret_id = data.aws_secretsmanager_secret.github_runner_secret.id
}