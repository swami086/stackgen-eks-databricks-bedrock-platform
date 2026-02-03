###############################################################################
# VPC
###############################################################################
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-vpc"
    Terraform   = "true"
    Environment = var.environment
  }
}

###############################################################################
# Subnets (one per AZ)
###############################################################################
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.environment}-private-${var.availability_zones[count.index]}"
    Terraform   = "true"
    Environment = var.environment
  }
}

###############################################################################
# Database Security Group
###############################################################################
resource "aws_security_group" "database" {
  name        = "${var.environment}-database-sg"
  description = "Security group for Aurora PostgreSQL"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "PostgreSQL from within VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-database-sg"
    Terraform   = "true"
    Environment = var.environment
  }
}
