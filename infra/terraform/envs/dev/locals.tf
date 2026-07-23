locals {
  name_prefix = "${var.project}-${var.environment}"

  application_bucket_name = "${var.project}-${var.environment}-application-${data.aws_caller_identity.current.account_id}"

  common_tags = {
    project      = var.project
    week         = "week-10"
    "managed-by" = "terraform"
    owner        = var.owner
    environment  = var.environment
  }
}  