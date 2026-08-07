locals {
  common_tags = {
    project      = var.project
    week         = "week-11"
    "managed-by" = "terraform"
    owner        = var.owner
    environment  = var.environment
  }
}
