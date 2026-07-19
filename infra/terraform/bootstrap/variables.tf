variable "aws_region" {
  description = "AWS Region used for the Terraform state bucket."
  type        = string
  default     = "eu-west-2"

  validation {
    condition     = var.aws_region == "eu-west-2"
    error_message = "The Day 66 bootstrap must use eu-west-2."
  }
}

variable "project" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "meeps"
}

variable "owner" {
  description = "Owner of the Terraform backend."
  type        = string
  default     = "meeps"
}