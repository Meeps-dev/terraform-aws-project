locals {
  database_identifier = "${var.project}-${var.environment}-postgres"

  database_tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.environment}-postgres"
      Tier = "database"
    }
  )
}

resource "aws_db_subnet_group" "main" {
  name        = "${var.project}-${var.environment}-database-subnets"
  description = "Private database subnets for ${var.project}-${var.environment}"
  subnet_ids  = var.private_database_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-${var.environment}-database-subnets"
      Tier = "database"
    }
  )
}

resource "aws_db_instance" "main" {
  identifier = local.database_identifier

  engine         = var.database_config.engine
  engine_version = var.database_config.engine_version
  instance_class = var.database_config.instance_class

  allocated_storage = var.database_config.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.database_config.database_name
  username = var.database_config.username
  port     = var.database_config.port

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false

  multi_az            = var.database_config.multi_az
  deletion_protection = var.database_config.deletion_protection

  backup_retention_period = var.backup_retention_period
  backup_window           = "02:00-03:00"
  maintenance_window      = "sun:03:00-sun:04:00"

  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  copy_tags_to_snapshot       = true

  # Lab teardown settings. Production should normally retain a final snapshot.
  skip_final_snapshot      = true
  delete_automated_backups = true

  # Disabled for this cost-conscious development lab.
  performance_insights_enabled = false

  tags = local.database_tags
}