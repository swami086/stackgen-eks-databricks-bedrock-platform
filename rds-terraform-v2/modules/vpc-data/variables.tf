variable "vpc_name" {
  description = "Name tag of the VPC to look up"
  type        = string
}

variable "subnet_name_filter" {
  description = "Substring to match in subnet Name tags (e.g. 'private' or 'database')"
  type        = string
  default     = "private"
}

variable "security_group_name_filter" {
  description = "Substring to match in security group Name tags"
  type        = string
  default     = "database"
}

variable "kms_key_alias" {
  description = "KMS key ID or alias to look up (e.g. 'alias/aws/rds' or a key ARN)"
  type        = string
}
