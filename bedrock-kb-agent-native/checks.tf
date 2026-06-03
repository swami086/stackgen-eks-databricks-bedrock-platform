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
      trimspace(var.opensearch_collection_arn) == ""
      || trimspace(var.opensearch_serverless_collection_name) != ""
    )
    error_message = "opensearch_serverless_collection_name is required when opensearch_collection_arn is set (for data access policy resource names)."
  }
}
