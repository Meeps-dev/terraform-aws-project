### Networking

module "vpc" {
  source = "../../modules/vpc"

  project = var.project

  vpc_cidr                 = "10.0.0.0/16"
  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  private_db_subnet_cidrs  = ["10.0.21.0/24", "10.0.22.0/24"]
  enable_nat_gateway       = true
}

### Security

module "security" {
  source = "../../modules/security"

  project = var.project
  vpc_id  = module.vpc.vpc_id

  alb_ingress_cidrs = ["0.0.0.0/0"]
  application_port  = 8080
  database_port     = 5432
}

### Load Balancing

module "alb" {
  source = "../../modules/alb"

  project               = var.project
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id

  application_port  = 8080
  health_check_path = "/health"
}

### Compute

module "compute" {
  source = "../../modules/compute"

  project     = var.project
  environment = var.environment

  instance_type    = "t3.micro"
  application_name = "users-posts-api"

  deployment_bucket_arn = module.app_s3.deployment_bucket_arn
  database_secret_arn   = module.rds.master_user_secret_arn

  private_subnet_id             = module.vpc.private_application_subnet_ids[0]
  application_security_group_id = module.security.application_security_group_id
  target_group_arn              = module.alb.target_group_arn

  application_port    = 8080
  root_volume_size    = 8
  root_volume_type    = "gp3"
  detailed_monitoring = false

  tags = local.common_tags
}

### Database

module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment

  private_database_subnet_ids = module.vpc.private_database_subnet_ids
  rds_security_group_id       = module.security.rds_security_group_id

  database_config = {
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

  backup_retention_period = 1
  tags                    = local.common_tags
}

### Application Storage

module "app_s3" {
  source = "../../modules/app-s3"

  project          = var.project
  environment      = var.environment
  application_name = "users-posts-api"

  force_destroy            = false
  deployment_force_destroy = true
  tags                     = local.common_tags
}
