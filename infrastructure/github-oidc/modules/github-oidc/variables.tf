variable "existing_oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN. Leave null to create the provider."
  type        = string
  default     = null
}

variable "terraform_subject_prefix" {
  description = "GitHub OIDC repository prefix for the Terraform repository."
  type        = string

  validation {
    condition     = startswith(var.terraform_subject_prefix, "repo:")
    error_message = "terraform_subject_prefix must start with repo:."
  }
}

variable "app_subject_prefix" {
  description = "GitHub OIDC repository prefix for the application repository."
  type        = string

  validation {
    condition     = startswith(var.app_subject_prefix, "repo:")
    error_message = "app_subject_prefix must start with repo:."
  }
}

variable "github_environment" {
  description = "Protected GitHub Environment used for apply and deployment jobs."
  type        = string
  default     = "dev"
}

variable "terraform_state_bucket_name" {
  description = "Existing S3 bucket containing the Terraform remote state."
  type        = string
}

variable "terraform_state_key" {
  description = "Existing Week 10 development Terraform state key."
  type        = string
}

variable "deployment_bucket_name" {
  description = "Private S3 bucket used for application deployment artifacts."
  type        = string
}

variable "application_name" {
  description = "Application name used in deployment artifact paths."
  type        = string
  default     = "users-posts-api"
}

variable "project_tag_value" {
  description = "Required project tag value for EC2 SSM command access."
  type        = string
  default     = "meeps"
}

variable "environment_tag_value" {
  description = "Required environment tag value for EC2 SSM command access."
  type        = string
  default     = "dev"
}

variable "managed_s3_bucket_arns" {
  description = "S3 bucket ARNs whose configuration Terraform is allowed to inspect."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags for IAM resources."
  type        = map(string)
  default     = {}
}
