output "oidc_provider_arn" {
  description = "GitHub OIDC provider ARN."
  value       = module.github_oidc.oidc_provider_arn
}

output "plan_role_arn" {
  description = "GitHub Terraform plan role ARN."
  value       = module.github_oidc.plan_role_arn
}

output "apply_role_arn" {
  description = "GitHub Terraform apply role ARN."
  value       = module.github_oidc.apply_role_arn
}

output "app_deploy_role_arn" {
  description = "GitHub application deployment role ARN."
  value       = module.github_oidc.app_deploy_role_arn
}

output "ecr_push_role_arn" {
  description = "GitHub Actions role ARN for publishing application images to ECR."
  value       = module.github_oidc.ecr_push_role_arn
}
