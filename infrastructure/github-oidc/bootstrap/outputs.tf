output "oidc_provider_arn" {
  value = module.github_oidc.oidc_provider_arn
}

output "plan_role_arn" {
  value = module.github_oidc.plan_role_arn
}

output "apply_role_arn" {
  value = module.github_oidc.apply_role_arn
}

output "app_deploy_role_arn" {
  value = module.github_oidc.app_deploy_role_arn
}