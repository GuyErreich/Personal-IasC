locals {
  github_token    = jsondecode(data.aws_secretsmanager_secret_version.github_accesses_token.secret_string)  # If the token is plain text, just use secret_string directly
  current_region  = data.aws_region.current.name
  current_account = data.aws_caller_identity.current.account_id
}