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

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
  default = [
    "subnet-05d3ad5f88a12b70f",
    "subnet-0a6a9888d4b79c042",
    "subnet-0df2101bdb52d7a48"
  ]
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs"
  type        = list(string)
  default     = ["sg-05fd34801441b3061"]
}

variable "kms_key_id" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = "arn:aws:kms:us-east-1:180217099948:key/dc3fe720-5e2c-4217-91f2-2ad9d2a886b7"
}
