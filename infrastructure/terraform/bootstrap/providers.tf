provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project      = var.project
      week         = "week-10"
      owner        = var.owner
      environment  = "bootstrap"
      "managed-by" = "terraform"
    }
  }
}