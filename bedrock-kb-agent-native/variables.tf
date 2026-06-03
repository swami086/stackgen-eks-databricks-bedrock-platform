variable "kb_name" {
  type        = string
  description = "Bedrock Knowledge Base name"
}

variable "agent_name" {
  type        = string
  description = "Bedrock Agent name"
}

variable "embedding_model_arn" {
  type        = string
  description = "ARN of the Bedrock embedding foundation model"
}

variable "foundation_model_id" {
  type        = string
  description = "Bedrock foundation model ID for the agent orchestration model"
}

variable "s3_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket used as the knowledge base document source"
}

variable "opensearch_domain_arn" {
  type        = string
  description = "ARN of the managed OpenSearch domain used as the vector store"
}

variable "opensearch_domain_endpoint" {
  type        = string
  description = "HTTPS endpoint of the managed OpenSearch domain"
}

variable "region" {
  type        = string
  description = "AWS region for Bedrock Agent and Knowledge Base resources"
  default     = "us-east-1"
}

variable "agent_instruction" {
  type        = string
  description = "System instruction for the Bedrock Agent"
  default     = "You are a helpful platform assistant. Answer using the connected knowledge base when relevant."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to created IAM roles"
  default     = {}
}
