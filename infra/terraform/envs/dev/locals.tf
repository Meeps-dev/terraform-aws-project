locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    project      = var.project
    week         = "week-11"
    "managed-by" = "terraform"
    owner        = var.owner
    environment  = var.environment
  }

  ssm_managed_instance_core_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"

  application_bucket_name = "${local.name_prefix}-application-${data.aws_caller_identity.current.account_id}"

  deployment_bucket_name = "${var.project}-users-posts-api-artifacts-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"

  database_identifier = "${local.name_prefix}-postgres"

  database_tags = merge(
    local.common_tags,
    {
      Name = local.database_identifier
      Tier = "database"
    }
  )
}
