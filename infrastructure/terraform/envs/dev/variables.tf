variable "aws_region" {
  description = "AWS Region for the development environment."
  type        = string
  default     = "eu-west-2"
  nullable    = false

  validation {
    condition     = var.aws_region == "eu-west-2"
    error_message = "The approved development Region is eu-west-2."
  }
}

variable "project" {
  description = "Project tag applied to all resources by the root provider."
  type        = string
  default     = "meeps"
  nullable    = false

  validation {
    condition     = length(trimspace(var.project)) > 0
    error_message = "Project cannot be empty."
  }
}

variable "owner" {
  description = "Owner tag applied to all resources by the root provider."
  type        = string
  default     = "meeps"
  nullable    = false

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "Owner cannot be empty."
  }
}

variable "environment" {
  description = "Environment tag applied to all resources by the root provider."
  type        = string
  default     = "dev"
  nullable    = false

  validation {
    condition     = var.environment == "dev"
    error_message = "This root module represents only the dev environment."
  }
}
