locals {
  name_prefix = "${var.resource_tags.project}-${var.environment}"

  common_tags = merge(
    var.resource_tags,
    {
      owner       = var.owner
      environment = var.environment
    }
  )

  selected_availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    2
  )
}