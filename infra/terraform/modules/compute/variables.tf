variable "project" {
  description = "Project name used for compute resource naming."
  type        = string
  default     = "meeps"
  nullable    = false

  validation {
    condition     = length(trimspace(var.project)) > 0
    error_message = "Project cannot be empty."
  }
}

variable "environment" {
  description = "Deployment environment used for compute resource naming."
  type        = string
  default     = "dev"
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "ami_id" {
  description = "Amazon Machine Image ID used by the backend instance."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^ami-[0-9a-f]+$", var.ami_id))
    error_message = "AMI ID must use a valid ami-xxxxxxxx format."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the backend."
  type        = string
  default     = "t3.micro"
  nullable    = false

  validation {
    condition     = contains(["t3.micro", "t3.small"], var.instance_type)
    error_message = "Approved EC2 types are t3.micro and t3.small."
  }
}

variable "ssm_managed_policy_arn" {
  description = "ARN of the AmazonSSMManagedInstanceCore managed policy."
  type        = string
  nullable    = false

  validation {
    condition     = endswith(var.ssm_managed_policy_arn, "/AmazonSSMManagedInstanceCore")
    error_message = "Provide the AmazonSSMManagedInstanceCore managed policy ARN."
  }
}

variable "private_subnet_id" {
  description = "Private application subnet for the backend instance."
  type        = string
  nullable    = false

  validation {
    condition     = startswith(var.private_subnet_id, "subnet-")
    error_message = "Private subnet ID must begin with subnet-."
  }
}

variable "application_security_group_id" {
  description = "Application security group attached to the EC2 instance."
  type        = string
  nullable    = false

  validation {
    condition     = startswith(var.application_security_group_id, "sg-")
    error_message = "Application security group ID must begin with sg-."
  }
}

variable "target_group_arn" {
  description = "ALB target-group ARN used to register the instance."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex(":targetgroup/", var.target_group_arn))
    error_message = "Provide a valid ALB target-group ARN."
  }
}

variable "application_port" {
  description = "Port on which the backend application listens."
  type        = number
  default     = 8080
  nullable    = false

  validation {
    condition = (
      var.application_port >= 1 &&
      var.application_port <= 65535 &&
      var.application_port != 22
    )
    error_message = "Application port must be between 1 and 65535 and must not be SSH port 22."
  }
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 8
  nullable    = false

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 30
    error_message = "Root volume size must be between 8 and 30 GiB."
  }
}

variable "root_volume_type" {
  description = "Root EBS volume type."
  type        = string
  default     = "gp3"
  nullable    = false

  validation {
    condition     = var.root_volume_type == "gp3"
    error_message = "The approved EBS volume type is gp3."
  }
}

variable "detailed_monitoring" {
  description = "Whether to enable detailed EC2 monitoring."
  type        = bool
  default     = false
  nullable    = false
}
