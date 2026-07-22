variable "bucket_name" {
  description = "Globally unique application S3 bucket name."
  type        = string
  nullable    = false

  validation {
    condition = (
      length(var.bucket_name) >= 3 &&
      length(var.bucket_name) <= 63 &&
      can(regex(
        "^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$",
        var.bucket_name
      ))
    )
    error_message = "Bucket name must contain 3–63 lowercase letters, numbers, or hyphens."
  }
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