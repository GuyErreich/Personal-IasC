module "ecr_repos" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.0"

  for_each = var.ecr_repositories

  repository_name = each.value

  repository_image_scan_on_push = false
  repository_image_tag_mutability = "MUTABLE"

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection    = {
          tagStatus     = "untagged"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action       = {
          type = "expire"
        }
      }
    ]
  })
}

resource "null_resource" "build_and_push_images" {
  for_each = var.ecr_images

  depends_on = [module.ecr_repos]

  provisioner "local-exec" {
    command = <<EOT
      # Run the Go task to build and push the Docker image to ECR
      task -d ../Images push IMAGE_NAME=${each.value.name} TAG=${each.value.tag} CONTEXT=${each.value.context} FILE=${each.value.file} REGION=${data.aws_region.current.name} ACCOUNT_ID=${data.aws_caller_identity.current.account_id}
    EOT
  }
}