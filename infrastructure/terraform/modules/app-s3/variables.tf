variable "project" {
  description = "Project name used for S3 resource naming."
  type        = string
  default     = "meeps"
  nullable    = false

  validation {
    condition     = length(trimspace(var.project)) > 0
    error_message = "Project cannot be empty."
  }
}

variable "environment" {
  description = "Environment used for S3 resource naming."
  type        = string
  default     = "dev"
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "application_name" {
  description = "Application name used for the deployment-artifact bucket."
  type        = string
  default     = "users-posts-api"
  nullable    = false

  validation {
    condition     = length(trimspace(var.application_name)) > 0
    error_message = "Application name cannot be empty."
  }
}

variable "bucket_name" {
  description = "Optional globally unique application bucket name override."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.bucket_name == null ? true : (
      length(var.bucket_name) >= 3 &&
      length(var.bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name))
    )
    error_message = "Bucket name must contain 3–63 lowercase letters, numbers, or hyphens."
  }
}

variable "deployment_bucket_name" {
  description = "Optional globally unique deployment bucket name override."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.deployment_bucket_name == null ? true : (
      length(var.deployment_bucket_name) >= 3 &&
      length(var.deployment_bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.deployment_bucket_name))
    )
    error_message = "Deployment bucket name must contain 3–63 lowercase letters, numbers, or hyphens."
  }
}

variable "force_destroy" {
  description = "Whether Terraform may delete objects while destroying the application bucket."
  type        = bool
  default     = false
  nullable    = false
}

variable "deployment_force_destroy" {
  description = "Whether Terraform may permanently delete all object versions and delete markers while destroying the deployment-artifacts bucket."
  type        = bool
  default     = false
  nullable    = false
}

variable "tags" {
  description = "Optional additional tags applied to S3 resources."
  type        = map(string)
  default     = {}
  nullable    = false
}
