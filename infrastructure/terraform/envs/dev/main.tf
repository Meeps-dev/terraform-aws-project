### Networking

module "vpc" {
  source = "../../modules/vpc"

  project = "meeps"

  vpc_cidr                 = "10.0.0.0/16"
  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  private_db_subnet_cidrs  = ["10.0.21.0/24", "10.0.22.0/24"]
  availability_zones       = data.aws_availability_zones.available.names
  enable_nat_gateway       = false
}

### Security

module "security" {
  source = "../../modules/security"

  project = "meeps"
  vpc_id  = module.vpc.vpc_id

  alb_ingress_cidrs = ["0.0.0.0/0"]
  application_port  = 8080
  database_port     = 5432
}

### Load Balancing

module "alb" {
  source = "../../modules/alb"

  project               = "meeps"
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id

  application_port  = 8080
  health_check_path = "/health"
}

### Compute

module "compute" {
  source = "../../modules/compute"

  project     = "meeps"
  environment = "dev"

  ami_id        = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  ssm_managed_policy_arn = local.ssm_managed_instance_core_policy_arn

  private_subnet_id             = module.vpc.private_application_subnet_ids[0]
  application_security_group_id = module.security.application_security_group_id
  target_group_arn              = module.alb.target_group_arn

  application_port    = 8080
  root_volume_size    = 8
  root_volume_type    = "gp3"
  detailed_monitoring = false
}

### Database

module "rds" {
  source = "../../modules/rds"

  project     = "meeps"
  environment = "dev"

  database_identifier = local.database_identifier
  database_tags       = local.database_tags

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

  bucket_name            = local.application_bucket_name
  deployment_bucket_name = local.deployment_bucket_name
  force_destroy          = false
  tags                   = local.common_tags
}
