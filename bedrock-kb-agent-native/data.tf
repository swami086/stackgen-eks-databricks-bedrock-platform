data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_opensearch_domain" "selected" {
  count = local.use_managed ? 1 : 0

  domain_name = local.opensearch_domain_name
}
