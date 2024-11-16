variable "aws_region" {
  description = "AWS region(s) to deploy resources"
  type        = string
}

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default = "default"
}

variable "github_org" {
  description = "GitHub organization to register the runner with"
  type        = string
}

variable "subnets" {
  description = "Subnets within the VPC where ECS tasks can launch."
  type        = list(string)
  default     = []
}

variable "ecr_repositories" {
  type = map(string)
  description = "A map of ECR repositories to create"
}