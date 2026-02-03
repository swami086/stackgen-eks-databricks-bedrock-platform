###############################################################################
# VPC Data Source - Looks up existing VPC and networking resources
###############################################################################

data "aws_vpc" "this" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnets" "database" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    Name = "*${var.subnet_name_filter}*"
  }
}

data "aws_security_groups" "database" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    Name = "*${var.security_group_name_filter}*"
  }
}

data "aws_kms_key" "rds" {
  key_id = var.kms_key_alias
}
