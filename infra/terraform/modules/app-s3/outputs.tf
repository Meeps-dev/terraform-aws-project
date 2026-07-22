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