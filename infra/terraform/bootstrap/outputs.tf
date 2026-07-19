output "state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket."
  value       = aws_s3_bucket.terraform_state.arn
}

output "backend_configuration" {
  description = "Values required by the development S3 backend."
  value = {
    bucket       = aws_s3_bucket.terraform_state.bucket
    key          = "week-10/dev/terraform.tfstate"
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}