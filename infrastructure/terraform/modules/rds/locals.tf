locals {
  database_identifier = coalesce(
    var.database_identifier,
    "${var.project}-${var.environment}-postgres",
  )

  database_tags = merge(
    var.tags,
    {
      Name = local.database_identifier
      Tier = "database"
    }
  )
}
