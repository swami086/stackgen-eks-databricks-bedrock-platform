check "managed_cluster_requires_domain_arn" {
  assert {
    condition = (
      var.vector_store_type != "OPENSEARCH_MANAGED_CLUSTER"
      || can(regex("^arn:aws[a-z-]*:es:", var.opensearch_domain_arn))
    )
    error_message = "opensearch_domain_arn is required when vector_store_type is OPENSEARCH_MANAGED_CLUSTER."
  }
}

check "serverless_collection_name_when_external_arn" {
  assert {
    condition = (
      local.opensearch_collection_arn_input == ""
      || length(local.oss_collection_name) >= 3
    )
    error_message = "opensearch_serverless_collection_name (or kb_name for default {kb_name}-vec) is required when using an existing OpenSearch Serverless collection ARN."
  }
}
