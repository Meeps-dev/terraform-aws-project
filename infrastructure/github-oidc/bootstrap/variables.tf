variable "aws_region" {
  type = string
}

variable "existing_oidc_provider_arn" {
  type    = string
  default = null
}

variable "terraform_subject_prefix" {
  type = string
}

variable "app_subject_prefix" {
  type = string
}

variable "github_environment" {
  type    = string
  default = "dev"
}

variable "terraform_state_bucket_name" {
  type = string
}

variable "terraform_state_key" {
  type = string
}

variable "deployment_bucket_name" {
  type = string
}

variable "application_name" {
  type    = string
  default = "users-posts-api"
}

variable "managed_s3_bucket_arns" {
  type    = list(string)
  default = []
}

variable "tags" {
  type = map(string)
}