output "oidc_provider_arn" {
  description = "GitHub OIDC provider ARN."
  value       = local.oidc_provider_arn
}

output "plan_role_arn" {
  description = "GitHub Terraform plan role ARN."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "GitHub Terraform apply role ARN."
  value       = aws_iam_role.apply.arn
}

output "app_deploy_role_arn" {
  description = "GitHub application deployment role ARN."
  value       = aws_iam_role.app_deploy.arn
}