###############################################################################
# DB Subnet Group
###############################################################################
resource "aws_db_subnet_group" "this" {
  name        = "${var.environment}-db-subnet-group"
  description = "Database subnet group for ${var.environment}"

  subnet_ids = var.subnet_ids

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

###############################################################################
# KMS Key for encryption
###############################################################################
resource "aws_kms_key" "rds" {
  description         = "KMS key for ${var.environment} Aurora encryption"
  enable_key_rotation = true

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.environment}-aurora"
  target_key_id = aws_kms_key.rds.key_id
}

###############################################################################
# Aurora PostgreSQL Cluster
###############################################################################
resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.environment}-aurora-cluster"
  engine             = "aurora-postgresql"
  engine_version     = var.engine_version
  port               = 5432

  master_username                     = var.master_username
  manage_master_user_password         = true
  iam_database_authentication_enabled = false

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids

  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"

  deletion_protection   = var.deletion_protection
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
  identifier         = "${var.environment}-aurora-cluster-one"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  publicly_accessible        = false
  auto_minor_version_upgrade = true
  promotion_tier             = 0
  ca_cert_identifier         = "rds-ca-rsa2048-g1"

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  performance_insights_retention_period = 7

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
