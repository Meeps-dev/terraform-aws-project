output "test_bucket_name" {
  description = "Name of the Day 64 Terraform test bucket."
  value       = aws_s3_bucket.day64_test.bucket
}