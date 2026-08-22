locals {
  oidc_provider_arn = (
    var.existing_oidc_provider_arn != null
    ? var.existing_oidc_provider_arn
    : aws_iam_openid_connect_provider.github[0].arn
  )

  state_bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket_name}"
  state_object_arn = "${local.state_bucket_arn}/${var.terraform_state_key}"
  state_lock_arn   = "${local.state_object_arn}.tflock"

  ecr_repository_arn = "arn:${data.aws_partition.current.partition}:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_name}"

  deploy_bucket_arn    = "arn:${data.aws_partition.current.partition}:s3:::${var.deployment_bucket_name}"
  deploy_object_prefix = "${local.deploy_bucket_arn}/releases/${var.application_name}"
}
