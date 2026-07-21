variable "project" {
  description = "Project name used for resource naming."
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  nullable    = false
}

variable "ami_id" {
  description = "Approved Amazon Linux 2023 AMI ID."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^ami-[0-9a-f]+$", var.ami_id))
    error_message = "AMI ID must use a valid ami-xxxxxxxx format."
  }
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  nullable    = false
}

variable "private_subnet_id" {
  description = "Private application subnet for the backend instance."
  type        = string
  nullable    = false
}

variable "application_security_group_id" {
  description = "Application security group attached to the EC2 instance."
  type        = string
  nullable    = false
}

variable "target_group_arn" {
  description = "ALB target-group ARN used to register the instance."
  type        = string
  nullable    = false
}

variable "application_port" {
  description = "Port on which the backend application listens."
  type        = number
  nullable    = false

  validation {
    condition     = var.application_port >= 1 && var.application_port <= 65535
    error_message = "Application port must be between 1 and 65535."
  }
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "Root volume size must be at least 8 GiB."
  }
}

variable "root_volume_type" {
  description = "Root EBS volume type."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2"], var.root_volume_type)
    error_message = "Root volume type must be gp3 or gp2."
  }
}

variable "detailed_monitoring" {
  description = "Enable detailed EC2 monitoring."
  type        = bool
  default     = false
}