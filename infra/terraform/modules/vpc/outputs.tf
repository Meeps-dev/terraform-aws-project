output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public ALB subnets."
  value       = aws_subnet.public[*].id
}

output "private_application_subnet_ids" {
  description = "IDs of the private application subnets."
  value       = aws_subnet.private_app[*].id
}

output "private_database_subnet_ids" {
  description = "IDs of the isolated database subnets."
  value       = aws_subnet.private_db[*].id
}

output "availability_zones" {
  description = "Availability Zones used by the VPC."
  value       = aws_subnet.public[*].availability_zone
}