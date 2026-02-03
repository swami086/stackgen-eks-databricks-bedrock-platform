terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

###############################################################################
# VPC — creates networking infrastructure from scratch
###############################################################################
module "vpc" {
  source = "./modules/vpc"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

###############################################################################
# RDS — Aurora cluster wired to the VPC module outputs
###############################################################################
module "rds" {
  source = "./modules/rds"

  environment            = var.environment
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.vpc.database_security_group_id]
}
