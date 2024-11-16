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