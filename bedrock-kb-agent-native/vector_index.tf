# Bedrock requires the vector index on the Serverless collection before KB creation.

locals {
  oss_collection_id = local.use_serverless ? (
    trimspace(var.opensearch_collection_arn) != ""
    ? element(split("/", var.opensearch_collection_arn), length(split("/", var.opensearch_collection_arn)) - 1)
    : aws_opensearchserverless_collection.vector[0].id
  ) : ""

  oss_collection_endpoint = (
    local.use_serverless
    ? "https://${local.oss_collection_id}.${var.region}.aoss.amazonaws.com"
    : "https://127.0.0.1"
  )
}

provider "opensearch" {
  url               = local.oss_collection_endpoint
  healthcheck       = false
  aws_region        = var.region
  sign_aws_requests = true
}

resource "opensearch_index" "bedrock_kb" {
  count = local.use_serverless ? 1 : 0

  name               = local.vector_index_name
  index_knn          = true
  number_of_shards   = 2
  number_of_replicas = 0

  mappings = jsonencode({
    properties = {
      "bedrock-knowledge-base-default-vector" = {
        type      = "knn_vector"
        dimension = var.embedding_vector_dimension
        method = {
          name       = "hnsw"
          space_type = "l2"
          engine     = "faiss"
          parameters = {
            ef_construction = 512
            m               = 16
          }
        }
      }
      "AMAZON_BEDROCK_TEXT_CHUNK" = {
        type = "text"
      }
      "AMAZON_BEDROCK_METADATA" = {
        type  = "text"
        index = false
      }
    }
  })

  lifecycle {
    precondition {
      condition     = local.use_serverless
      error_message = "opensearch_index is only created for OPENSEARCH_SERVERLESS."
    }
  }

  depends_on = [
    aws_opensearchserverless_access_policy.bedrock_kb,
    time_sleep.oss_data_policy_settle,
  ]
}

resource "time_sleep" "oss_data_policy_settle" {
  count = local.use_serverless ? 1 : 0

  create_duration = "60s"

  depends_on = [
    aws_opensearchserverless_access_policy.bedrock_kb,
  ]
}
