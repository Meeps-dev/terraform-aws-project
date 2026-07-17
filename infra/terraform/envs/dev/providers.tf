provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project      = "meeps"
      week         = "week-10"
      owner        = var.owner
      environment  = var.environment
      "managed-by" = "terraform"
    }
  }
}