data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.existing_oidc_provider_arn == null ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = var.tags
}

locals {
  oidc_provider_arn = (
    var.existing_oidc_provider_arn != null
    ? var.existing_oidc_provider_arn
    : aws_iam_openid_connect_provider.github[0].arn
  )

  state_bucket_arn  = "arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket_name}"
  state_object_arn  = "${local.state_bucket_arn}/${var.terraform_state_key}"
  state_lock_arn    = "${local.state_object_arn}.tflock"

  deploy_bucket_arn    = "arn:${data.aws_partition.current.partition}:s3:::${var.deployment_bucket_name}"
  deploy_object_prefix = "${local.deploy_bucket_arn}/releases/${var.application_name}"
}

data "aws_iam_policy_document" "plan_trust" {
  statement {
    sid     = "GitHubOIDCPlanAccess"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "${var.terraform_subject_prefix}:ref:refs/heads/main",
        "${var.terraform_subject_prefix}:ref:refs/heads/feature/*",
        "${var.terraform_subject_prefix}:pull_request",
      ]
    }
  }
}

data "aws_iam_policy_document" "apply_trust" {
  statement {
    sid     = "GitHubOIDCApplyAccess"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "${var.terraform_subject_prefix}:environment:${var.github_environment}",
      ]
    }
  }
}

data "aws_iam_policy_document" "app_deploy_trust" {
  statement {
    sid     = "GitHubOIDCApplicationDeployAccess"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "${var.app_subject_prefix}:environment:${var.github_environment}",
      ]
    }
  }
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