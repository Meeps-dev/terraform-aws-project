variable "aws_region" {
  description = "AWS Region used for Week 10 infrastructure."
  type        = string
  default     = "eu-west-2"
  nullable    = false

  validation {
    condition     = var.aws_region == "eu-west-2"
    error_message = "The approved AWS Region is eu-west-2."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "owner" {
  description = "Person responsible for the infrastructure."
  type        = string
  default     = "meeps"
  nullable    = false

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "Owner cannot be empty."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the VPC."
  type        = string
  default     = "10.0.0.0/16"
  nullable    = false

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "subnet_cidrs" {
  description = "CIDR blocks for public, private EC2, and private database subnets."
  type = object({
    public           = list(string)
    private_ec2      = list(string)
    private_database = list(string)
  })

  default = {
    public           = ["10.0.1.0/24", "10.0.2.0/24"]
    private_ec2      = ["10.0.11.0/24", "10.0.12.0/24"]
    private_database = ["10.0.21.0/24", "10.0.22.0/24"]
  }

  validation {
    condition = alltrue([
      for cidr in concat(
        var.subnet_cidrs.public,
        var.subnet_cidrs.private_ec2,
        var.subnet_cidrs.private_database
      ) : can(cidrhost(cidr, 0))
    ])
    error_message = "Every subnet value must be a valid CIDR block."
  }

  validation {
    condition = (
      length(var.subnet_cidrs.public) >= 2 &&
      length(var.subnet_cidrs.private_ec2) >= 2 &&
      length(var.subnet_cidrs.private_database) >= 2
    )
    error_message = "Provide at least two CIDRs for each subnet tier."
  }
}

variable "ec2_config" {
  description = "EC2 configuration that will be used by the application servers."
  type = object({
    instance_type       = string
    root_volume_size    = number
    root_volume_type    = string
    detailed_monitoring = bool
  })

  default = {
    instance_type       = "t3.micro"
    root_volume_size    = 8
    root_volume_type    = "gp3"
    detailed_monitoring = false
  }

  validation {
    condition     = contains(["t3.micro", "t3.small"], var.ec2_config.instance_type)
    error_message = "Approved EC2 types are t3.micro and t3.small."
  }

  validation {
    condition = (
      var.ec2_config.root_volume_size >= 8 &&
      var.ec2_config.root_volume_size <= 30
    )
    error_message = "EC2 root volume size must be between 8 and 30 GiB."
  }

  validation {
    condition     = var.ec2_config.root_volume_type == "gp3"
    error_message = "The approved EBS volume type is gp3."
  }
}

variable "database_config" {
  description = "Configuration for the future private PostgreSQL database."
  type = object({
    engine              = string
    engine_version      = string
    instance_class      = string
    allocated_storage   = number
    database_name       = string
    username            = string
    port                = number
    multi_az            = bool
    deletion_protection = bool
  })

  default = {
    engine              = "postgres"
    engine_version      = "16"
    instance_class      = "db.t3.micro"
    allocated_storage   = 20
    database_name       = "meepsapp"
    username            = "meepsadmin"
    port                = 5432
    multi_az            = false
    deletion_protection = false
  }

  validation {
    condition     = var.database_config.engine == "postgres"
    error_message = "The approved database engine is postgres."
  }

  validation {
    condition = contains(
      ["db.t3.micro", "db.t4g.micro"],
      var.database_config.instance_class
    )
    error_message = "Use an approved low-cost RDS instance class."
  }

  validation {
    condition = (
      var.database_config.allocated_storage >= 20 &&
      var.database_config.allocated_storage <= 100
    )
    error_message = "Database storage must be between 20 and 100 GiB."
  }

  validation {
    condition     = var.database_config.port == 5432
    error_message = "PostgreSQL must use port 5432."
  }

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]*$", var.database_config.database_name))
    error_message = "Database name must begin with a letter and contain only letters, numbers, or underscores."
  }
}

variable "database_password" {
  description = "Master password for the future database."
  type        = string
  sensitive   = true
  nullable    = false

  validation {
    condition = (
      length(var.database_password) >= 16 &&
      length(var.database_password) <= 128
    )
    error_message = "Database password must contain between 16 and 128 characters."
  }
}

variable "resource_tags" {
  description = "Standard tags applied to AWS resources."
  type        = map(string)
  nullable    = false

  default = {
    project      = "meeps"
    week         = "week-10"
    "managed-by" = "terraform"
  }

  validation {
    condition = alltrue([
      for required_key in ["project", "week", "managed-by"] :
      contains(keys(var.resource_tags), required_key)
    ])
    error_message = "Resource tags must include project, week, and managed-by."
  }

  validation {
    condition = alltrue([
      for tag_value in values(var.resource_tags) :
      length(trimspace(tag_value)) > 0
    ])
    error_message = "Resource tag values cannot be empty."
  }
}