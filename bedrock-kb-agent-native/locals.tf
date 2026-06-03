locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  foundation_model_arn = "arn:${local.partition}:bedrock:${var.region}::foundation-model/${var.foundation_model_id}"

  kb_role_name    = "${var.kb_name}-kb-role"
  agent_role_name = "${var.agent_name}-agent-role"

  vector_index_name = "bedrock-knowledge-base-default-index"

  # ARN format: arn:aws:es:region:account:domain/domain-name
  opensearch_domain_name = element(split("/", var.opensearch_domain_arn), 1)

  opensearch_endpoint_override = trimspace(var.opensearch_domain_endpoint)
  opensearch_use_derived_endpoint = (
    local.opensearch_endpoint_override == ""
    || lower(local.opensearch_endpoint_override) == "auto"
  )

  opensearch_domain_endpoint = (
    local.opensearch_use_derived_endpoint
    ? "https://${data.aws_opensearch_domain.selected.endpoint}"
    : (
      startswith(local.opensearch_endpoint_override, "https://")
      ? local.opensearch_endpoint_override
      : "https://${local.opensearch_endpoint_override}"
    )
  )

  common_tags = merge(
    {
      ManagedBy = "terraform"
      Module    = "bedrock-kb-agent-native"
    },
    var.tags,
  )
}
