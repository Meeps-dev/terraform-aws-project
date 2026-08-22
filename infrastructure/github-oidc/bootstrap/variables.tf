variable "aws_region" {
  type = string
}

variable "existing_oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN. Leave null to create the provider."
  type        = string
  default     = null
}

variable "terraform_subject_prefix" {
  description = "Subject prefix for Terraform-related GitHub Actions."
  type        = string
}

variable "app_subject_prefix" {
  description = "Subject prefix for application-related GitHub Actions."
  type        = string
}

variable "github_environment" {
  description = "GitHub Environment used for protected apply and deployment jobs."
  type        = string
  default     = "dev"
}

variable "terraform_state_bucket_name" {
  description = "Existing S3 bucket containing the Terraform remote state."
  type        = string
}

variable "terraform_state_key" {
  description = "Key for the Terraform state file in the S3 bucket."
  type        = string
}

variable "deployment_bucket_name" {
  description = "Private S3 bucket used for application deployment artifacts."
  type        = string
}

variable "application_name" {
  description = "Name of the application."
  type        = string
  default     = "users-posts-api"
}

variable "managed_s3_bucket_arns" {
  description = "List of ARNs for S3 buckets managed by this module."
  type        = list(string)
  default     = []
}

variable "ecr_repository_name" {
  description = "ECR repository the application workflow may publish to."
  type        = string
  default     = "meeps-users-posts-api"
}

variable "tags" {
  description = "Tags to apply to all resources created by this module."
  type        = map(string)
}
