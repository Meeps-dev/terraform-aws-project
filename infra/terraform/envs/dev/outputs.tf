output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = module.alb.alb_dns_name
}

output "target_group_arn" {
  description = "ARN of the backend target group."
  value       = module.alb.target_group_arn
}

output "backend_instance_id" {
  description = "ID of the private backend EC2 instance."
  value       = module.compute.instance_id
}

output "backend_private_ip" {
  description = "Private IPv4 address of the backend EC2 instance."
  value       = module.compute.private_ip
}

output "database_instance_identifier" {
  description = "Identifier of the private PostgreSQL instance."
  value       = module.rds.db_instance_identifier
}

output "database_endpoint" {
  description = "Private RDS endpoint including its port."
  value       = module.rds.database_endpoint
}

output "database_port" {
  description = "Port used by the PostgreSQL database."
  value       = module.rds.database_port
}

output "database_master_user_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret."
  value       = module.rds.master_user_secret_arn
  sensitive   = true
}

output "application_s3_bucket_name" {
  description = "Name of the private application S3 bucket."
  value       = module.app_s3.bucket_name
}

output "application_s3_bucket_arn" {
  description = "ARN of the private application S3 bucket."
  value       = module.app_s3.bucket_arn
}