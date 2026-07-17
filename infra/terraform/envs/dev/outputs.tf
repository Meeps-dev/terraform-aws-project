output "deployment_context" {
  description = "General context for this Terraform environment."
  value = {
    name_prefix = local.name_prefix
    environment = var.environment
    region      = data.aws_region.current.region
  }
}

output "aws_account_id" {
  description = "AWS account used by Terraform."
  value       = data.aws_caller_identity.current.account_id
  sensitive   = true
}

output "availability_zones" {
  description = "First two available standard Availability Zones."
  value       = local.selected_availability_zones
}

output "approved_ami" {
  description = "Approved Amazon Linux 2023 AMI selected for future EC2 instances."
  value = {
    id           = data.aws_ami.amazon_linux_2023.id
    name         = data.aws_ami.amazon_linux_2023.name
    owner_id     = data.aws_ami.amazon_linux_2023.owner_id
    architecture = data.aws_ami.amazon_linux_2023.architecture
  }
}

output "network_configuration" {
  description = "Planned VPC and subnet CIDR configuration."
  value = {
    vpc_cidr     = var.vpc_cidr
    subnet_cidrs = var.subnet_cidrs
  }
}

output "ec2_configuration" {
  description = "Planned EC2 configuration."
  value       = var.ec2_config
}

output "database_configuration" {
  description = "Non-secret planned database configuration."
  value = {
    engine              = var.database_config.engine
    engine_version      = var.database_config.engine_version
    instance_class      = var.database_config.instance_class
    allocated_storage   = var.database_config.allocated_storage
    database_name       = var.database_config.database_name
    port                = var.database_config.port
    multi_az            = var.database_config.multi_az
    deletion_protection = var.database_config.deletion_protection
  }
}

output "database_credentials_configured" {
  description = "Confirms credentials were supplied without displaying them."
  value = {
    username_configured = length(trimspace(var.database_config.username)) > 0
    password_configured = length(var.database_password) >= 16
  }
  sensitive = true
}

output "common_tags" {
  description = "Tags that future AWS resources will inherit."
  value       = local.common_tags
}