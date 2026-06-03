data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_opensearch_domain" "selected" {
  domain_name = local.opensearch_domain_name
}
