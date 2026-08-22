module "ecr" {
  source = "../../modules/ecr"

  repository_name      = var.repository_name
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  force_delete         = false

  # Enable only after previewing the lifecycle policy
  # against real images in the repository.
  enable_lifecycle_policy = var.enable_lifecycle_policy

  untagged_image_days = 7
  max_tagged_images   = 10

  tags = local.common_tags
}

resource "aws_ecr_registry_scanning_configuration" "this" {
  scan_type = "BASIC"

  rule {
    scan_frequency = "SCAN_ON_PUSH"

    repository_filter {
      filter      = "meeps-users-posts-api"
      filter_type = "WILDCARD"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
