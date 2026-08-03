variable "bucket_name" {
  description = "Globally unique application S3 bucket name."
  type        = string
  nullable    = false
}

variable "deployment_bucket_name" {
  description = "Globally unique S3 bucket name for application deployment artifacts."
  type        = string
  nullable    = false
}

variable "aws_region" {
  description = "AWS Region used for Week 11 infrastructure."
  type        = string
  default     = "eu-west-2"
  nullable    = false
}

variable "force_destroy" {
  description = "Whether Terraform may delete objects while destroying the bucket."
  type        = bool
  default     = false
  nullable    = false
}

variable "tags" {
  description = "Tags applied to application S3 resources."
  type        = map(string)
  nullable    = false
}
