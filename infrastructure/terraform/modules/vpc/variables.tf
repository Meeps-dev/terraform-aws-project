variable "project" {
  description = "Project name used for VPC resource naming."
  type        = string
  default     = "meeps"
  nullable    = false

  validation {
    condition     = length(trimspace(var.project)) > 0
    error_message = "Project cannot be empty."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the VPC."
  type        = string
  default     = "10.0.0.0/16"
  nullable    = false

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR ranges used by the load balancer."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  nullable    = false

  validation {
    condition = (
      length(var.public_subnet_cidrs) >= 2 &&
      alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    )
    error_message = "Provide at least two valid public subnet CIDR blocks."
  }
}

variable "private_app_subnet_cidrs" {
  description = "Private subnet CIDR ranges used by the application tier."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
  nullable    = false

  validation {
    condition = (
      length(var.private_app_subnet_cidrs) >= 2 &&
      alltrue([for cidr in var.private_app_subnet_cidrs : can(cidrhost(cidr, 0))])
    )
    error_message = "Provide at least two valid private application subnet CIDR blocks."
  }
}

variable "private_db_subnet_cidrs" {
  description = "Private subnet CIDR ranges used by the database tier."
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
  nullable    = false

  validation {
    condition = (
      length(var.private_db_subnet_cidrs) >= 2 &&
      alltrue([for cidr in var.private_db_subnet_cidrs : can(cidrhost(cidr, 0))])
    )
    error_message = "Provide at least two valid private database subnet CIDR blocks."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway for the private application subnets."
  type        = bool
  default     = false
  nullable    = false
}
