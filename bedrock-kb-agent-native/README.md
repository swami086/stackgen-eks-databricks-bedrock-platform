# bedrock-kb-agent-native

Terraform module for **Amazon Bedrock Knowledge Base + Agent** with **OpenSearch Serverless** as the default vector store (VPC-safe; no public managed domain required).

**StackGen catalog version:** `1.0.14`

## Features

- OpenSearch Serverless VECTORSEARCH collection, encryption/network/data policies  
- `opensearch_index` created **before** KB registration (Bedrock prerequisite)  
- Stable OSS data-policy principals (no STS session drift in v1.0.14+)  
- StackGen template bridge: accepts placeholder ES domain ARN in `opensearch_domain_arn`  
- Optional managed OpenSearch cluster mode (`OPENSEARCH_MANAGED_CLUSTER`)  

## Usage

```hcl
module "bedrock" {
  source = "git::https://github.com/swami086/stackgen-eks-databricks-bedrock-platform//bedrock-kb-agent-native?ref=main"

  kb_name                    = "platform_knowledge_base"
  agent_name                 = "platform_bedrock_agent"
  foundation_model_id        = "anthropic.claude-3-haiku-20240307-v1:0"
  embedding_model_arn        = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
  s3_bucket_arn              = "arn:aws:s3:::my-knowledge-docs-bucket"
  vector_store_type          = "OPENSEARCH_SERVERLESS"
  opensearch_serverless_collection_name = "platform-kb-vec"

  # StackGen: ES placeholder only — do NOT use live arn:aws:aoss:... unless external mode
  opensearch_domain_arn = "arn:aws:es:us-east-1:123456789012:domain/placeholder"

  additional_opensearch_data_access_principal_arns = [
    "arn:aws:iam::123456789012:role/StackgenDeployerRole",
  ]

  region = "us-east-1"
}
```

## Key variables

| Variable | Required | Notes |
|----------|----------|-------|
| `kb_name`, `agent_name` | Yes | Bedrock resource names |
| `s3_bucket_arn` | Yes | Document source bucket |
| `embedding_model_arn`, `foundation_model_id` | Yes | Bedrock models |
| `vector_store_type` | No | Default `OPENSEARCH_SERVERLESS` |
| `additional_opensearch_data_access_principal_arns` | No | StackGen deployer IAM role |

## Outputs

`knowledge_base_id`, `knowledge_base_arn`, `agent_id`, `agent_arn`, `agent_alias_arn`, `data_source_id`

## StackGen upload

```bash
stackgen upload custom-modules \
  --scope project \
  --name bedrock-kb-agent-native \
  --repo-url https://github.com/swami086/stackgen-eks-databricks-bedrock-platform \
  --subdir bedrock-kb-agent-native \
  --version 1.0.14
```

## Reference architecture

[`examples/eks-databricks-bedrock-layer-validation`](../examples/eks-databricks-bedrock-layer-validation/)
