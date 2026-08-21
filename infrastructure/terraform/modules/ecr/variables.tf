variable "repository_name" {
  description = "Name of the Amazon ECR private repository."
  type        = string

  validation {
    condition     = length(trimspace(var.repository_name)) > 0
    error_message = "repository_name cannot be empty."
  }
}

variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition = contains(
      ["MUTABLE", "IMMUTABLE"],
      var.image_tag_mutability
    )
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Whether Amazon ECR performs a basic vulnerability scan when an image is pushed."
  type        = bool
  default     = true
}

variable "force_delete" {
  description = "Whether Terraform may delete the repository when images still exist."
  type        = bool
  default     = false
}

variable "enable_lifecycle_policy" {
  description = "Whether the ECR lifecycle policy is attached to the repository."
  type        = bool
  default     = false
}

variable "untagged_image_days" {
  description = "Number of days after which untagged images become eligible for expiration."
  type        = number
  default     = 7

  validation {
    condition     = var.untagged_image_days >= 1
    error_message = "untagged_image_days must be at least 1."
  }
}

variable "max_tagged_images" {
  description = "Maximum number of tagged images retained before older images become eligible for expiration."
  type        = number
  default     = 10

  validation {
    condition     = var.max_tagged_images >= 1
    error_message = "max_tagged_images must be at least 1."
  }
}

variable "tags" {
  description = "Additional tags applied to the ECR repository."
  type        = map(string)
  default     = {}
}
