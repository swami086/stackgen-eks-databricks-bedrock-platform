output "vpc_id" {
  description = "The VPC ID"
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "database_security_group_id" {
  description = "Security group ID for database access"
  value       = aws_security_group.database.id
}
