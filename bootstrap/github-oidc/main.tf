module "github_oidc" {
  source = "../../modules/github-oidc"

  existing_oidc_provider_arn = var.existing_oidc_provider_arn

  terraform_subject_prefix = var.terraform_subject_prefix
  app_subject_prefix       = var.app_subject_prefix
  github_environment       = var.github_environment

  terraform_state_bucket_name = var.terraform_state_bucket_name
  terraform_state_key         = var.terraform_state_key

  deployment_bucket_name = var.deployment_bucket_name
  application_name       = var.application_name

  managed_s3_bucket_arns = var.managed_s3_bucket_arns

  project_tag_value     = "meeps"
  environment_tag_value = "dev"

  tags = var.tags
}