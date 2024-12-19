variable "aws_region" {
  description = "AWS region(s) to deploy resources"
  type        = string
}

variable "github_org" {
  description = "GitHub organization to register the runner with"
  type        = string
}

variable "public_subnets" {
  description = "Public subnets within the VPC where ECS tasks can launch."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnets within the VPC where ECS tasks can launch."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "ecr_repositories" {
  description = "A map of ECR repositories to create"
  type        = map(string)
}

variable "ecr_images" {
  description = "A map of ECR images to create"
  type = map(object({
    file    = string
    context = string
    name    = string
    tag     = string
  }))
}

variable "lambda_zip" {
  description = "The path to the lambda zip file"
  type        = string
}

variable "lambda_layer_zip" {
  description = "The path to the lambda layer zip file"
  type        = string
}