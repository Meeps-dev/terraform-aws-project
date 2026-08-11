resource "aws_s3_bucket" "main" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    {
      Name = local.bucket_name
      Tier = "application-storage"
    }
  )
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "deployment_artifacts" {
  bucket        = local.deployment_bucket_name
  force_destroy = var.deployment_force_destroy

  tags = merge(
    var.tags,
    {
      Name         = local.deployment_bucket_name
      purpose      = "application-deployment-artifacts"
      "managed-by" = "terraform"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "deployment_artifacts" {
  bucket = aws_s3_bucket.deployment_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "deployment_artifacts" {
  bucket = aws_s3_bucket.deployment_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deployment_artifacts" {
  bucket = aws_s3_bucket.deployment_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "deployment_artifacts" {
  bucket = aws_s3_bucket.deployment_artifacts.id

  rule {
    id     = "expire-old-application-releases"
    status = "Enabled"

    filter {
      prefix = "releases/"
    }

    expiration {
      days = 14
    }

    noncurrent_version_expiration {
      noncurrent_days           = 7
      newer_noncurrent_versions = 2
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.deployment_artifacts,
  ]
}
