output "bucket_name" {
  description = "Name of the private application S3 bucket."
  value       = aws_s3_bucket.main.bucket
}

output "bucket_arn" {
  description = "ARN of the private application S3 bucket."
  value       = aws_s3_bucket.main.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the application S3 bucket."
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "deployment_bucket_name" {
  description = "S3 bucket used for application deployment artifacts."
  value       = aws_s3_bucket.deployment_artifacts.bucket
}

output "deployment_bucket_arn" {
  description = "ARN of the application deployment artifact bucket."
  value       = aws_s3_bucket.deployment_artifacts.arn
}