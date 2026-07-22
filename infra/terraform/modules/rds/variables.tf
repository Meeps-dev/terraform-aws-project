variable "project" {
  description = "Project name used for RDS resource naming."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.project)) > 0
    error_message = "Project cannot be empty."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "private_database_subnet_ids" {
  description = "Private database subnet IDs used by the DB subnet group."
  type        = list(string)
  nullable    = false

  validation {
    condition = (
      length(toset(var.private_database_subnet_ids)) >= 2 &&
      alltrue([
        for subnet_id in var.private_database_subnet_ids :
        startswith(subnet_id, "subnet-")
      ])
    )
    error_message = "Provide at least two unique database subnet IDs."
  }
}

variable "rds_security_group_id" {
  description = "Security group allowing PostgreSQL only from the application tier."
  type        = string
  nullable    = false

  validation {
    condition     = startswith(var.rds_security_group_id, "sg-")
    error_message = "RDS security group ID must begin with sg-."
  }
}

variable "database_config" {
  description = "Configuration for the private PostgreSQL instance."

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

  nullable = false

  validation {
    condition = (
      var.database_config.engine == "postgres" &&
      var.database_config.port == 5432 &&
      length(trimspace(var.database_config.engine_version)) > 0
    )
    error_message = "The database must use PostgreSQL on port 5432 with an engine version."
  }

  validation {
    condition = (
      contains(
        ["db.t3.micro", "db.t4g.micro"],
        var.database_config.instance_class
      ) &&
      var.database_config.allocated_storage >= 20 &&
      var.database_config.allocated_storage <= 100
    )
    error_message = "Use an approved development instance class and 20–100 GiB of storage."
  }

  validation {
    condition = (
      can(regex(
        "^[A-Za-z][A-Za-z0-9]{0,62}$",
        var.database_config.database_name
      )) &&
      can(regex(
        "^[A-Za-z][A-Za-z0-9]{0,62}$",
        var.database_config.username
      ))
    )
    error_message = "Database name and username must start with a letter and contain only letters and numbers."
  }
}

variable "backup_retention_period" {
  description = "Number of days automated RDS backups are retained."
  type        = number
  default     = 1
  nullable    = false

  validation {
    condition = (
      var.backup_retention_period >= 1 &&
      var.backup_retention_period <= 35
    )
    error_message = "Backup retention must be between 1 and 35 days."
  }
}

variable "tags" {
  description = "Tags applied to RDS resources."
  type        = map(string)
  nullable    = false
}