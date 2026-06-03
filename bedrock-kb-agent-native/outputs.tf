output "agent_alias_arn" {
  description = "Bedrock Agent alias ARN"
  value       = aws_bedrockagent_agent_alias.this.agent_alias_arn
}

output "agent_alias_id" {
  description = "Bedrock Agent alias ID"
  value       = aws_bedrockagent_agent_alias.this.id
}

output "agent_arn" {
  description = "Bedrock Agent ARN"
  value       = aws_bedrockagent_agent.this.agent_arn
}

output "agent_id" {
  description = "Bedrock Agent ID"
  value       = aws_bedrockagent_agent.this.id
}

output "agent_role_arn" {
  description = "IAM role ARN used by the Bedrock Agent"
  value       = aws_iam_role.agent.arn
}

output "data_source_id" {
  description = "Bedrock Knowledge Base S3 data source ID"
  value       = aws_bedrockagent_data_source.s3.data_source_id
}

output "knowledge_base_arn" {
  description = "Bedrock Knowledge Base ARN"
  value       = aws_bedrockagent_knowledge_base.this.arn
}

output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID"
  value       = aws_bedrockagent_knowledge_base.this.id
}

output "knowledge_base_role_arn" {
  description = "IAM role ARN used by the Bedrock Knowledge Base"
  value       = aws_iam_role.knowledge_base.arn
}

output "opensearch_domain_endpoint" {
  description = "Resolved OpenSearch domain endpoint used by the Knowledge Base"
  value       = local.opensearch_domain_endpoint
}
