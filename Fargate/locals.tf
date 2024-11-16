locals {
  github_token = jsondecode(data.aws_secretsmanager_secret_version.github_token_version.secret_string)  # If the token is plain text, just use secret_string directly
}