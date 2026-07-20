variable "project" {
  description = "Project name used for resource naming."
  type        = string
}

variable "vpc_id" {
  description = "VPC where the security groups will be created."
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "Approved IPv4 CIDRs allowed to access the ALB."
  type        = set(string)

  validation {
    condition = alltrue([
      for cidr in var.alb_ingress_cidrs : can(cidrnetmask(cidr))
    ])
    error_message = "Every ALB source must be a valid IPv4 CIDR."
  }
}

variable "application_port" {
  description = "Port used by the backend application."
  type        = number
}

variable "database_port" {
  description = "Port used by the database."
  type        = number
  default     = 5432
}