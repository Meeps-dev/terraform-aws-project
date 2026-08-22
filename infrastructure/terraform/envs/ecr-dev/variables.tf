variable "aws_region" {
  description = "AWS Region for the ECR development environment."
  type        = string
  default     = "eu-west-2"
  nullable    = false

  validation {
    condition     = var.aws_region == "eu-west-2"
    error_message = "The approved ECR development Region is eu-west-2."
  }
}

variable "project" {
  description = "Project tag applied to ECR resources."
  type        = string
  default     = "meeps"
  nullable    = false

  validation {
    condition     = length(trimspace(var.project)) > 0
    error_message = "Project cannot be empty."
  }
}

variable "owner" {
  description = "Owner tag applied to ECR resources."
  type        = string
  default     = "meeps"
  nullable    = false

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "Owner cannot be empty."
  }
}

variable "environment" {
  description = "Environment tag applied to ECR resources."
  type        = string
  default     = "dev"
  nullable    = false

  validation {
    condition     = var.environment == "dev"
    error_message = "This root manages only the dev ECR environment."
  }
}

variable "repository_name" {
  description = "Application ECR repository name."
  type        = string
  default     = "meeps-users-posts-api"
  nullable    = false
}

variable "enable_lifecycle_policy" {
  description = "Enable lifecycle enforcement after previewing the policy."
  type        = bool
  default     = true
}
