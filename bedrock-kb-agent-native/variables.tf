variable "agent_instruction" {
  description = "System instruction for the Bedrock Agent"
  type        = string
  default     = "You are a helpful platform assistant. Answer using the connected knowledge base when relevant."

  validation {
    condition     = length(trimspace(var.agent_instruction)) > 0
    error_message = "agent_instruction must not be empty."
  }
}

variable "agent_name" {
  description = "Bedrock Agent name"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-zA-Z_-]{1,100}$", var.agent_name))
    error_message = "agent_name must be 1-100 characters (letters, numbers, hyphen, underscore)."
  }
}

variable "embedding_model_arn" {
  description = "ARN of the Bedrock embedding foundation model"
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:bedrock:", var.embedding_model_arn))
    error_message = "embedding_model_arn must be a Bedrock model ARN."
  }
}

variable "foundation_model_id" {
  description = "Bedrock foundation model ID for the agent orchestration model"
  type        = string

  validation {
    condition     = length(trimspace(var.foundation_model_id)) > 0
    error_message = "foundation_model_id must not be empty."
  }
}

variable "kb_name" {
  description = "Bedrock Knowledge Base name"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-zA-Z_-]{1,100}$", var.kb_name))
    error_message = "kb_name must be 1-100 characters (letters, numbers, hyphen, underscore)."
  }
}

variable "opensearch_domain_arn" {
  description = "ARN of the managed OpenSearch domain used as the vector store"
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:es:", var.opensearch_domain_arn))
    error_message = "opensearch_domain_arn must be an Amazon OpenSearch Service domain ARN."
  }
}

variable "opensearch_domain_endpoint" {
  description = "Optional OpenSearch HTTPS endpoint override. When empty, derived from opensearch_domain_arn via data.aws_opensearch_domain."
  type        = string
  default     = ""
}

variable "manage_opensearch_domain_access_policy" {
  description = "Attach OpenSearch domain access policy for the KB IAM role. Set OpenSearch enable_access_policies=false in StackGen to avoid policy conflicts."
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region for Bedrock Agent and Knowledge Base IAM scope"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.region))
    error_message = "region must be a valid AWS region identifier."
  }
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket used as the knowledge base document source"
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:s3:::", var.s3_bucket_arn))
    error_message = "s3_bucket_arn must be an S3 bucket ARN."
  }
}

variable "tags" {
  description = "Tags applied to Bedrock and IAM resources"
  type        = map(string)
  default     = {}
}
