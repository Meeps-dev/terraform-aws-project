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

resource "aws_iam_policy" "plan_state" {
  name        = "github-plan-state-policy"
  description = "Remote-state and native S3 lock access for Terraform plan."
  policy      = data.aws_iam_policy_document.plan_state.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "plan_state" {
  role       = aws_iam_role.plan.name
  policy_arn = aws_iam_policy.plan_state.arn
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

resource "aws_iam_policy" "apply_state" {
  name        = "github-apply-state-policy"
  description = "Remote-state and native S3 lock access for Terraform apply."
  policy      = data.aws_iam_policy_document.apply_state.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "apply_state" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.apply_state.arn
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

resource "aws_iam_policy" "terraform_read" {
  name        = "github-terraform-read-policy"
  description = "Read-only discovery permissions for Terraform plan and apply."
  policy      = data.aws_iam_policy_document.terraform_read.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "plan_read" {
  role       = aws_iam_role.plan.name
  policy_arn = aws_iam_policy.terraform_read.arn
}

resource "aws_iam_role_policy_attachment" "apply_read" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.terraform_read.arn
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

resource "aws_iam_policy" "app_deploy" {
  name        = "github-app-deploy-policy"
  description = "Upload application artifacts and deploy to approved EC2 instances through SSM."
  policy      = data.aws_iam_policy_document.app_deploy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "app_deploy" {
  role       = aws_iam_role.app_deploy.name
  policy_arn = aws_iam_policy.app_deploy.arn
}
