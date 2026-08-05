resource "aws_iam_openid_connect_provider" "github" {
  count = var.existing_oidc_provider_arn == null ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = var.tags
}

resource "aws_iam_role" "plan" {
  name                 = "github-plan-role"
  description          = "GitHub OIDC role for Terraform validation and plan operations."
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = 3600

  tags = var.tags
}

resource "aws_iam_role" "apply" {
  name                 = "github-apply-role"
  description          = "GitHub OIDC role for protected Terraform apply operations."
  assume_role_policy   = data.aws_iam_policy_document.apply_trust.json
  max_session_duration = 3600

  tags = var.tags
}

resource "aws_iam_role" "app_deploy" {
  name                 = "github-app-deploy-role"
  description          = "GitHub OIDC role for application artifact upload and SSM deployment."
  assume_role_policy   = data.aws_iam_policy_document.app_deploy_trust.json
  max_session_duration = 3600

  tags = var.tags
}
