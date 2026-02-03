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
# Look up existing VPC, subnets, security groups, and KMS key
###############################################################################
module "vpc_data" {
  source = "./modules/vpc-data"

  vpc_name                   = var.vpc_name
  subnet_name_filter         = var.subnet_name_filter
  security_group_name_filter = var.security_group_name_filter
  kms_key_alias              = var.kms_key_alias
}

###############################################################################
# Aurora PostgreSQL cluster wired to the looked-up networking
###############################################################################
module "rds" {
  source = "./modules/rds"

  environment            = var.environment
  subnet_ids             = module.vpc_data.subnet_ids
  vpc_security_group_ids = module.vpc_data.security_group_ids
  kms_key_arn            = module.vpc_data.kms_key_arn
}
