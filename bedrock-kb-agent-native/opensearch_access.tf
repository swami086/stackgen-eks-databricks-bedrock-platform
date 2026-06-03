# Domain access policy for Bedrock KB IAM role (replaces IP-only policies from StackGen OpenSearch).
# Set enable_access_policies=false on the OpenSearch resource to avoid duplicate aws_opensearch_domain_policy.

data "aws_iam_policy_document" "opensearch_kb_access" {
  count = local.use_managed && var.manage_opensearch_domain_access_policy ? 1 : 0

  statement {
    sid    = "BedrockKBRoleDomainAccess"
    effect = "Allow"
    actions = [
      "es:DescribeDomain",
      "es:ESHttpGet",
      "es:ESHttpHead",
      "es:ESHttpPost",
      "es:ESHttpPut",
      "es:ESHttpDelete",
    ]
    resources = [
      var.opensearch_domain_arn,
      "${var.opensearch_domain_arn}/${local.vector_index_name}",
      "${var.opensearch_domain_arn}/${local.vector_index_name}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.knowledge_base.arn]
    }
  }
}

resource "aws_opensearch_domain_policy" "bedrock_kb" {
  count           = local.use_managed && var.manage_opensearch_domain_access_policy ? 1 : 0
  domain_name     = local.opensearch_domain_name
  access_policies = data.aws_iam_policy_document.opensearch_kb_access[0].json

  depends_on = [aws_iam_role.knowledge_base]
}
