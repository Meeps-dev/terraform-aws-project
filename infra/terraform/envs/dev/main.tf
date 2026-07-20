module "vpc" {
  source = "../../modules/vpc"

  project = var.project

  vpc_cidr = var.vpc_cidr

  public_subnet_cidrs = var.public_subnet_cidrs

  private_app_subnet_cidrs = var.private_app_subnet_cidrs

  private_db_subnet_cidrs = var.private_db_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
}

module "security" {
  source = "../../modules/security"

  project = var.project
  vpc_id  = module.vpc.vpc_id

  alb_ingress_cidrs = var.alb_ingress_cidrs
  application_port  = var.application_port
  database_port     = var.database_config.port
}
