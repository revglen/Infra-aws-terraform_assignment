terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Ecommerce Platform"
      Terraform   = "true"
    }
  }
}

module "networking" {
  source = "./modules/networking"

  name               = "${var.project_name}-${var.environment}"
  cidr               = var.vpc_cidr
  azs                = var.availability_zones
  private_subnets    = var.private_subnet_cidrs
  public_subnets     = var.public_subnet_cidrs
  database_subnets   = var.database_subnet_cidrs
  enable_nat_gateway = true
  single_nat_gateway = true
}

module "alb" {
  source = "./modules/alb"

  name       = "${var.project_name}-${var.environment}-alb"
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.public_subnets # need to change this
  internal   = false
  # certificate_arn = var.acm_certificate_arn
  # enable_https    = false

  certificate_arn = aws_acm_certificate.self_signed.arn
  enable_https    = true
}

resource "aws_acm_certificate" "self_signed" {
  private_key      = file("${path.module}/certs/self_signed_key.pem")
  certificate_body = file("${path.module}/certs/self_signed_cert.pem")

  lifecycle {
    ignore_changes = [domain_validation_options]
  }
}

module "rds" {

  source = "./modules/rds"

  name              = "${var.project_name}-${var.environment}"
  username          = var.db_username
  password          = var.db_password
  db_name           = var.db_name
  subnet_ids        = module.networking.database_subnets
  security_group_id = module.networking.db_security_group_id
}

module "app_autoscaling" {
  source = "./modules/app_autoscaling"

  name   = "ecommerce"
  vpc_id = module.networking.vpc_id
  #subnet_ids         = module.networking.public_subnets # used for testing
  subnet_ids         = module.networking.private_subnets
  security_group_ids = [module.networking.app_security_group_id]
  instance_type      = var.app_instance_type
  min_size           = var.app_min_size
  max_size           = var.app_max_size

  db_endpoint = module.rds.endpoint
  db_username = var.db_username
  db_password = var.db_password
  db_name     = var.db_name
}

module "nginx_autoscaling" {
  source = "./modules/nginx_autoscaling"

  name   = "nginx"
  vpc_id = module.networking.vpc_id
  #subnet_ids         = module.networking.public_subnets
  subnet_ids         = module.networking.private_subnets
  security_group_ids = [module.networking.nginx_security_group_id]
  instance_type      = var.nginx_instance_type
  min_size           = var.nginx_min_size
  max_size           = var.nginx_max_size
  key_name           = module.app_autoscaling.ssh_key_pair

  app_alb_dns_name          = module.app_autoscaling.alb_dns_name
  frontend_target_group_arn = module.alb.target_group_arn # CRITICAL CONNECTION  
}

module "waf" {
  source = "./modules/waf"

  alb_arn = module.alb.alb_arn
  count   = 0 # Disabled for cost
}

module "apigateway" {
  source = "./modules/apigateway"
  count  = 0 # Disabled for cost
}

module "dns" {
  source = "./modules/dns"

  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
  count        = 0 # Disabled for cost
}