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

module "alb" {
  source = "../../modules/alb"

  project               = var.project
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  application_port      = var.application_port
  health_check_path     = "/health"
}

module "compute" {
  source = "../../modules/compute"

  project     = var.project
  environment = var.environment

  ami_id        = data.aws_ami.amazon_linux_2023.id
  instance_type = var.ec2_config.instance_type

  private_subnet_id             = module.vpc.private_application_subnet_ids[0]
  application_security_group_id = module.security.application_security_group_id
  target_group_arn              = module.alb.target_group_arn
  application_port              = var.application_port

  root_volume_size    = var.ec2_config.root_volume_size
  root_volume_type    = var.ec2_config.root_volume_type
  detailed_monitoring = var.ec2_config.detailed_monitoring
}