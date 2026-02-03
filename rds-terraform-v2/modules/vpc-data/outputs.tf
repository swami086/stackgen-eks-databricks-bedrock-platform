output "vpc_id" {
  description = "The VPC ID"
  value       = data.aws_vpc.this.id
}

output "subnet_ids" {
  description = "List of subnet IDs matching the filter"
  value       = data.aws_subnets.database.ids
}

output "security_group_ids" {
  description = "List of security group IDs matching the filter"
  value       = data.aws_security_groups.database.ids
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = data.aws_kms_key.rds.arn
}
