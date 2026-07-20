variable "project" {
  description = "Project name used for resource tagging"
  type        = string
}


variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}


variable "public_subnet_cidrs" {
  description = "Public subnet CIDR ranges"
  type        = list(string)
}


variable "private_app_subnet_cidrs" {
  description = "Private application subnet CIDR ranges"
  type        = list(string)
}


variable "private_db_subnet_cidrs" {
  description = "Private database subnet CIDR ranges"
  type        = list(string)
}


variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private application subnets"
  type        = bool
  default     = false
}