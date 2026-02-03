output "vpc_id" {
  description = "The VPC ID that was looked up"
  value       = module.vpc_data.vpc_id
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
