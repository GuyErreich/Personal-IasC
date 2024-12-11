# Module: IAM GitHub OIDC Provider
module "iam_github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "~> 5.0"
}

# Module: IAM GitHub OIDC Role for ECS Service Update
module "iam_github_oidc_ecs_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "~> 5.0"

  name = "GitHubActionsECSUpdateRole"

  provider_url = module.iam_github_oidc_provider.url

  subjects  = [
    "${var.github_org}:ref:refs/heads/*",
    "${var.github_org}:ref:refs/tags/*"
  ]

  policies = {
    ECSServicePolicy = aws_iam_policy.ecs_update_service_policy.arn
  }
}

module "iam_github_oidc_ecr_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "~> 5.0"

  name = "GitHubActionsECRRole"

  provider_url = module.iam_github_oidc_provider.url

  subjects  = [
    "${var.github_org}:ref:refs/heads/*",
    "${var.github_org}:ref:refs/tags/*"
  ]

  policies = {
    ECSServicePolicy = aws_iam_policy.ecr_pull_accesses.arn
  }
}
