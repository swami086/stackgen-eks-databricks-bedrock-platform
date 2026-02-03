variable "environment" {
  description = "Environment name (used in resource naming)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "17.5"
}

variable "instance_class" {
  description = "Instance class for the Aurora cluster instance"
  type        = string
  default     = "db.r6g.large"
}

variable "master_username" {
  description = "Master database username"
  type        = string
  default     = "root"
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 1
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}
