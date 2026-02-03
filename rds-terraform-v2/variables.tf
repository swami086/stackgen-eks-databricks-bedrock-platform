variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev-v2"
}

variable "vpc_name" {
  description = "Name tag of the VPC to look up"
  type        = string
  default     = "dev-v2-vpc"
}

variable "subnet_name_filter" {
  description = "Substring to match in subnet Name tags"
  type        = string
  default     = "private"
}

variable "security_group_name_filter" {
  description = "Substring to match in security group Name tags"
  type        = string
  default     = "database"
}

variable "kms_key_alias" {
  description = "KMS key ID or alias for RDS encryption"
  type        = string
  default     = "arn:aws:kms:us-east-1:180217099948:key/dc3fe720-5e2c-4217-91f2-2ad9d2a886b7"
}
