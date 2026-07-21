variable "project" {
  description = "Project name used for resource naming."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.project) != ""
    error_message = "Project must not be empty."
  }
}

variable "vpc_id" {
  description = "VPC in which the target group will be created."
  type        = string
  nullable    = false
}

variable "public_subnet_ids" {
  description = "Public subnet IDs used by the internet-facing ALB."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "The ALB requires at least two public subnets."
  }
}

variable "alb_security_group_id" {
  description = "Security group attached to the ALB."
  type        = string
  nullable    = false
}

variable "application_port" {
  description = "Port used by the backend application and target group."
  type        = number
  nullable    = false

  validation {
    condition     = var.application_port >= 1 && var.application_port <= 65535
    error_message = "Application port must be between 1 and 65535."
  }
}

variable "health_check_path" {
  description = "HTTP endpoint used by the target-group health check."
  type        = string
  default     = "/health"

  validation {
    condition     = startswith(var.health_check_path, "/")
    error_message = "Health-check path must begin with a forward slash."
  }
}