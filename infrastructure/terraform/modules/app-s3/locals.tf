locals {
  bucket_name = coalesce(
    var.bucket_name,
    "${var.project}-${var.environment}-application-${data.aws_caller_identity.current.account_id}",
  )

  deployment_bucket_name = coalesce(
    var.deployment_bucket_name,
    "${var.project}-${var.application_name}-artifacts-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}",
  )
}
