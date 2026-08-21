output "ecr_repository_name" {
  description = "Name of the application ECR repository."
  value       = module.ecr.repository_name
}

output "ecr_repository_arn" {
  description = "ARN of the application ECR repository."
  value       = module.ecr.repository_arn
}

output "ecr_repository_url" {
  description = "Repository URL used for Docker push and pull operations."
  value       = module.ecr.repository_url
}

output "ecr_registry_id" {
  description = "AWS registry ID that owns the repository."
  value       = module.ecr.registry_id
}

output "ecr_lifecycle_policy_enabled" {
  description = "Whether lifecycle-policy enforcement is currently enabled."
  value       = module.ecr.lifecycle_policy_enabled
}
