locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  foundation_model_arn = "arn:${local.partition}:bedrock:${var.region}::foundation-model/${var.foundation_model_id}"

  kb_role_name    = "${var.kb_name}-kb-role"
  agent_role_name = "${var.agent_name}-agent-role"

  vector_index_name = "bedrock-knowledge-base-default-index"

  use_serverless = var.vector_store_type == "OPENSEARCH_SERVERLESS"
  use_managed    = var.vector_store_type == "OPENSEARCH_MANAGED_CLUSTER"

  oss_collection_name = substr(
    lower(replace(
      trimspace(var.opensearch_serverless_collection_name) != ""
      ? var.opensearch_serverless_collection_name
      : "${var.kb_name}-vec",
      "_",
      "-",
    )),
    0,
    32,
  )

  create_serverless_collection = (
    local.use_serverless
    && trimspace(var.opensearch_collection_arn) == ""
  )

  opensearch_collection_arn = (
    local.use_serverless
    ? (
      trimspace(var.opensearch_collection_arn) != ""
      ? trimspace(var.opensearch_collection_arn)
      : aws_opensearchserverless_collection.vector[0].arn
    )
    : ""
  )

  # Managed cluster (legacy) — ARN format: arn:aws:es:region:account:domain/domain-name
  opensearch_domain_name = (
    local.use_managed ? element(split("/", var.opensearch_domain_arn), 1) : ""
  )

  opensearch_endpoint_override = trimspace(var.opensearch_domain_endpoint)
  opensearch_use_derived_endpoint = (
    local.opensearch_endpoint_override == ""
    || lower(local.opensearch_endpoint_override) == "auto"
  )

  opensearch_domain_endpoint = (
    local.use_managed
    ? (
      local.opensearch_use_derived_endpoint
      ? "https://${data.aws_opensearch_domain.selected[0].endpoint}"
      : (
        startswith(local.opensearch_endpoint_override, "https://")
        ? local.opensearch_endpoint_override
        : "https://${local.opensearch_endpoint_override}"
      )
    )
    : null
  )

  common_tags = merge(
    {
      ManagedBy = "terraform"
      Module    = "bedrock-kb-agent-native"
    },
    var.tags,
  )

  # StackGen/OpenTofu often runs via sts:AssumeRole; AOSS data policies need the stable IAM role ARN.
  deployer_arn              = data.aws_caller_identity.current.arn
  deployer_is_assumed_role  = startswith(local.deployer_arn, "arn:aws:sts:")
  deployer_iam_role_arn = (
    local.deployer_is_assumed_role
    ? "arn:aws:iam::${local.account_id}:role/${element(split("/", local.deployer_arn), 1)}"
    : local.deployer_arn
  )

  oss_data_access_principals = distinct(compact(concat(
    [
      aws_iam_role.knowledge_base.arn,
      local.deployer_arn,
      local.deployer_iam_role_arn,
    ],
    var.additional_opensearch_data_access_principal_arns,
  )))
}
