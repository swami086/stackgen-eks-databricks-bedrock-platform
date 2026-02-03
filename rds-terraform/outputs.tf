output "cluster_endpoint" {
  description = "Writer endpoint for the cluster"
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint for the cluster"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "cluster_id" {
  description = "The RDS cluster identifier"
  value       = aws_rds_cluster.this.id
}

output "instance_id" {
  description = "The RDS instance identifier"
  value       = aws_rds_cluster_instance.this.id
}
