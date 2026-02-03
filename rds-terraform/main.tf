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
# DB Subnet Group
###############################################################################
resource "aws_db_subnet_group" "this" {
  name        = "dev-v2-db-subnet-group"
  description = "Database subnet group for dev-v2-vpc"

  subnet_ids = var.subnet_ids

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

###############################################################################
# Aurora PostgreSQL Cluster
###############################################################################
resource "aws_rds_cluster" "this" {
  cluster_identifier = "dev-v2-aurora-cluster"
  engine             = "aurora-postgresql"
  engine_version     = "17.5"
  port               = 5432

  master_username                     = "root"
  manage_master_user_password         = true
  iam_database_authentication_enabled = false

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids

  storage_encrypted = true
  kms_key_id        = var.kms_key_id

  backup_retention_period  = 1
  preferred_backup_window  = "02:00-03:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"

  deletion_protection = false
  copy_tags_to_snapshot = false

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

###############################################################################
# Aurora Cluster Instance
###############################################################################
resource "aws_rds_cluster_instance" "this" {
  identifier         = "dev-v2-aurora-cluster-one"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = "db.r6g.large"
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  publicly_accessible          = false
  auto_minor_version_upgrade   = true
  promotion_tier               = 0
  ca_cert_identifier           = "rds-ca-rsa2048-g1"

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.kms_key_id
  performance_insights_retention_period = 7

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
