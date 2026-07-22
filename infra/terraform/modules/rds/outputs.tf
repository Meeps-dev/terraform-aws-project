output "db_instance_identifier" {
  description = "RDS database instance identifier."
  value       = aws_db_instance.main.identifier
}

output "db_subnet_group_name" {
  description = "Name of the private RDS subnet group."
  value       = aws_db_subnet_group.main.name
}

output "database_endpoint" {
  description = "RDS endpoint including its port."
  value       = aws_db_instance.main.endpoint
}

output "database_address" {
  description = "RDS hostname without the port."
  value       = aws_db_instance.main.address
}

output "database_port" {
  description = "Port used by the RDS database."
  value       = aws_db_instance.main.port
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret."
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
  sensitive   = true
}