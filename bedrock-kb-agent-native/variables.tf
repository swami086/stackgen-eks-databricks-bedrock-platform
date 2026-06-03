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

variable "embedding_vector_dimension" {
  description = "Vector dimension for the OpenSearch Serverless knn index (must match the embedding model; Titan Embed Text v2 = 1024)."
  type        = number
  default     = 1024

  validation {
    condition     = var.embedding_vector_dimension >= 1 && var.embedding_vector_dimension <= 4096
    error_message = "embedding_vector_dimension must be between 1 and 4096."
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

variable "vector_store_type" {
  description = "Vector store for the Knowledge Base. OPENSEARCH_SERVERLESS (default) works with VPC platforms; OPENSEARCH_MANAGED_CLUSTER requires a public OpenSearch domain."
  type        = string
  default     = "OPENSEARCH_SERVERLESS"

  validation {
    condition     = contains(["OPENSEARCH_SERVERLESS", "OPENSEARCH_MANAGED_CLUSTER"], var.vector_store_type)
    error_message = "vector_store_type must be OPENSEARCH_SERVERLESS or OPENSEARCH_MANAGED_CLUSTER."
  }
}

variable "opensearch_serverless_collection_name" {
  description = "OpenSearch Serverless VECTORSEARCH collection name (3-32 lowercase chars). Defaults to {kb_name}-vec when empty."
  type        = string
  default     = ""
}

variable "opensearch_collection_arn" {
  description = "Existing OpenSearch Serverless collection ARN. When set, skips collection and security policy creation."
  type        = string
  default     = ""
}

variable "opensearch_domain_arn" {
  description = "Managed OpenSearch domain ARN. Required only when vector_store_type is OPENSEARCH_MANAGED_CLUSTER."
  type        = string
  default     = ""
}

variable "opensearch_domain_endpoint" {
  description = "Optional managed OpenSearch HTTPS endpoint override. When empty, derived from opensearch_domain_arn."
  type        = string
  default     = ""
}

variable "manage_opensearch_domain_access_policy" {
  description = "Attach managed OpenSearch domain access policy for the KB IAM role (managed cluster only)."
  type        = bool
  default     = false
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

variable "additional_opensearch_data_access_principal_arns" {
  description = "Extra IAM principal ARNs for the OpenSearch Serverless data access policy (e.g. StackGen deployer role)."
  type        = list(string)
  default     = []
}
