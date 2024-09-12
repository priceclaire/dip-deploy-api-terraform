terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
  required_version = ">= 1.2.0"
}
provider "aws" {
  region  = "eu-north-1"
}

module "vpc" {
  source = "../../modules/vpc"

  cidr_block            = var.cidr_block
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  app_name              = var.app_name
}

module "iam" {
  source = "../../modules/iam"

  app_name = var.app_name
}

module "ecr_frontend" {
  source = "../../modules/ecr"

  app_name  = var.app_name
  tier      = "frontend"
}

module "ecr_api" {
  source = "../../modules/ecr"

  app_name  = var.app_name
  tier      = "api"
}

module "bastion" {
  source = "../../modules/bastion"

  app_name = var.app_name
  vpc_id   = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnet_ids[0]
  ec2_profile_name = module.iam.ec2_profile_name
}

module "rds" {
  source = "../../modules/rds"

  app_name            = var.app_name

  private_sg_id       = module.private_ec2.security_group_id
  bastion_sg_id       = module.bastion.security_group_id

  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids

  db_username         = var.db_username
  db_password         = var.db_password
}

module "private_ec2" {
  source = "../../modules/private_ec2"

  app_name            = var.app_name

  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids

  lb_sg_id            = module.alb.lb_sg_id

  ec2_profile_name    = module.iam.ec2_profile_name
}

module "alb" {
  source = "../../modules/alb"

  app_name            = var.app_name

  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  instance_ids        = module.private_ec2.instance_ids
}






