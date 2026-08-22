# Permission policies and attachments for the GitHub Actions IAM roles.

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

resource "aws_iam_policy" "terraform_apply_changes" {
  name        = "github-terraform-apply-changes-policy"
  description = "Service-scoped mutation permissions for the Meeps development Terraform stack."
  policy      = data.aws_iam_policy_document.terraform_apply_changes.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "terraform_apply_changes" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.terraform_apply_changes.arn
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

resource "aws_iam_policy" "ecr_push" {
  name        = "github-ecr-push-policy"
  description = "Publish immutable application images and read scan results for the approved ECR repository."
  policy      = data.aws_iam_policy_document.ecr_push.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecr_push" {
  role       = aws_iam_role.ecr_push.name
  policy_arn = aws_iam_policy.ecr_push.arn
}
