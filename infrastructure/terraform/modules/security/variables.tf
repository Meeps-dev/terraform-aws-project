variable "project" {
  description = "Project name used for security-group naming."
  type        = string
  default     = "meeps"
  nullable    = false

  validation {
    condition     = length(trimspace(var.project)) > 0
    error_message = "Project cannot be empty."
  }
}

variable "vpc_id" {
  description = "VPC where the security groups will be created."
  type        = string
  nullable    = false

  validation {
    condition     = startswith(var.vpc_id, "vpc-")
    error_message = "VPC ID must begin with vpc-."
  }
}

variable "alb_ingress_cidrs" {
  description = "Approved IPv4 CIDRs allowed to access the public load balancer."
  type        = set(string)
  default     = ["0.0.0.0/0"]
  nullable    = false

  validation {
    condition = (
      length(var.alb_ingress_cidrs) > 0 &&
      alltrue([for cidr in var.alb_ingress_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "Provide at least one valid IPv4 CIDR block for ALB access."
  }
}

variable "application_port" {
  description = "Port used by the backend application."
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

variable "database_port" {
  description = "Port used by PostgreSQL."
  type        = number
  default     = 5432
  nullable    = false

  validation {
    condition     = var.database_port == 5432
    error_message = "The approved PostgreSQL port is 5432."
  }
}
