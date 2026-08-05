# AWS account metadata used to build partition-safe ARNs.
data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Trust policy documents used by the GitHub Actions IAM roles.
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

# Permission policy documents attached to the GitHub Actions IAM roles.
data "aws_iam_policy_document" "plan_state" {
  statement {
    sid       = "ListStatePath"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        var.terraform_state_key,
        "${var.terraform_state_key}.tflock",
      ]
    }
  }

  statement {
    sid       = "ReadStateBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [local.state_bucket_arn]
  }

  statement {
    sid     = "ReadTerraformState"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = [
      local.state_object_arn,
      local.state_lock_arn,
    ]
  }

  statement {
    sid    = "ManageTerraformPlanLock"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [local.state_lock_arn]
  }
}

data "aws_iam_policy_document" "apply_state" {
  statement {
    sid       = "ListStatePath"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        var.terraform_state_key,
        "${var.terraform_state_key}.tflock",
      ]
    }
  }

  statement {
    sid       = "ReadStateBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [local.state_bucket_arn]
  }

  statement {
    sid    = "ReadAndWriteTerraformState"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [local.state_object_arn]
  }

  statement {
    sid    = "ManageTerraformApplyLock"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [local.state_lock_arn]
  }
}

data "aws_iam_policy_document" "terraform_read" {
  statement {
    sid    = "ReadTerraformManagedAWSResources"
    effect = "Allow"

    actions = [
      "autoscaling:Describe*",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListTagsForResource",
      "ec2:Describe*",
      "elasticloadbalancing:Describe*",
      "iam:GetInstanceProfile",
      "iam:GetOpenIDConnectProvider",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListOpenIDConnectProviderTags",
      "iam:ListPolicyTags",
      "iam:ListPolicyVersions",
      "iam:ListRolePolicies",
      "iam:ListRoleTags",
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListAliases",
      "kms:ListResourceTags",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:ListTagsForResource",
      "rds:Describe*",
      "rds:ListTagsForResource",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets",
      "sts:GetCallerIdentity",
    ]

    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.managed_s3_bucket_arns) > 0 ? [true] : []

    content {
      sid    = "ReadManagedS3BucketConfiguration"
      effect = "Allow"

      actions = [
        "s3:GetAccelerateConfiguration",
        "s3:GetBucket*",
        "s3:GetEncryptionConfiguration",
        "s3:GetLifecycleConfiguration",
        "s3:GetReplicationConfiguration",
        "s3:ListBucket",
      ]

      resources = var.managed_s3_bucket_arns
    }
  }
}

data "aws_iam_policy_document" "app_deploy" {
  statement {
    sid       = "ReadDeploymentBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [local.deploy_bucket_arn]
  }

  statement {
    sid       = "ListApplicationReleases"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.deploy_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "releases/${var.application_name}",
        "releases/${var.application_name}/*",
      ]
    }
  }

  statement {
    sid    = "ManageApplicationArtifacts"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "${local.deploy_object_prefix}/*",
    ]
  }

  statement {
    sid     = "UseApprovedSSMDocument"
    effect  = "Allow"
    actions = ["ssm:SendCommand"]

    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}::document/AWS-RunShellScript",
    ]
  }

  statement {
    sid     = "SendCommandsToTaggedApplicationInstances"
    effect  = "Allow"
    actions = ["ssm:SendCommand"]

    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:instance/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/project"
      values   = [var.project_tag_value]
    }

    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/environment"
      values   = [var.environment_tag_value]
    }
  }

  statement {
    sid    = "ReadCommandExecutionStatus"
    effect = "Allow"

    actions = [
      "ssm:DescribeInstanceInformation",
      "ssm:GetCommandInvocation",
      "ssm:ListCommandInvocations",
      "ssm:ListCommands",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "InspectDeploymentInstances"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeTags",
    ]

    resources = ["*"]
  }
}
