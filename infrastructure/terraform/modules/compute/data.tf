data "aws_partition" "current" {}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_iam_policy_document" "backend_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "runtime_access" {
  statement {
    sid       = "ReadDeploymentBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [var.deployment_bucket_arn]
  }

  statement {
    sid       = "ListApplicationReleases"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.deployment_bucket_arn]

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
    sid     = "ReadApplicationReleaseObjects"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = [
      "${var.deployment_bucket_arn}/releases/${var.application_name}/*",
    ]
  }

  statement {
    sid    = "ReadRDSManagedSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]

    resources = [var.database_secret_arn]
  }
}
