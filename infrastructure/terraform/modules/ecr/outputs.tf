output "repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.this.name
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "Repository URL used for Docker push and pull operations."
  value       = aws_ecr_repository.this.repository_url
}

output "registry_id" {
  description = "AWS registry ID that owns the repository."
  value       = aws_ecr_repository.this.registry_id
}

output "lifecycle_policy_enabled" {
  description = "Whether lifecycle-policy enforcement is currently enabled."
  value       = var.enable_lifecycle_policy
}
