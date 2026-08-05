# Trust policies attached to the GitHub Actions IAM roles.

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
