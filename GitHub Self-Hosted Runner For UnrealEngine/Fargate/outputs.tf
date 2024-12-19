output "current_region" {
  description = "Current AWS region"
  value       = data.aws_region.current.name
}

output "available_regions" {
  description = "Available AWS regions"
  value       = data.aws_regions.available.names
}

output "availability_zones" {
  description = "AWS regions chosen for deployment"
  value       = data.aws_availability_zones.available.names
}

output "ecs_cluster_id" {
  value = module.ecs.cluster_id
}

output "github_runner_token" {
  value = local.github_runner_token
  sensitive = true
}

