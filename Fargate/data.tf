data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_regions" "available" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "github_token" {
  name = "github_runner"  # Replace with the name of your secret
}

data "aws_secretsmanager_secret_version" "github_token_version" {
  secret_id = data.aws_secretsmanager_secret.github_token.id
}

data "aws_ecr_repository" "existing_repos" {
  for_each = var.ecr_repositories

  name = each.value
}

data "aws_secretsmanager_secret_version" "github_runner_token" {
  secret_id = "arn:aws:secretsmanager:eu-central-1:961341519925:secret:github_runner-23Sc4K"
}

# data "aws_acm_certificate" "fargat_https_certificate" {
#   domain   = "example.com"  # Specify the domain for the certificate you're looking up
#   statuses = ["ISSUED"]     # Ensures you only get valid, issued certificates
# }