output "vpc_id" {
  description = "The VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "database_security_group_id" {
  description = "Security group ID for database access"
  value       = module.vpc.database_security_group_id
}

output "cluster_endpoint" {
  description = "Writer endpoint for the Aurora cluster"
  value       = module.rds.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint for the Aurora cluster"
  value       = module.rds.cluster_reader_endpoint
}

output "cluster_id" {
  description = "The RDS cluster identifier"
  value       = module.rds.cluster_id
}

output "instance_id" {
  description = "The RDS instance identifier"
  value       = module.rds.instance_id
}
