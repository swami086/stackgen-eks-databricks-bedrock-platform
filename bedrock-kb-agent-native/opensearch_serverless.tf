# OpenSearch Serverless vector store for Bedrock Knowledge Base (VPC-safe; no public managed domain).

resource "aws_opensearchserverless_security_policy" "encryption" {
  count = local.create_serverless_collection ? 1 : 0

  name = "${local.oss_collection_name}-enc"
  type = "encryption"

  policy = jsonencode({
    Rules = [{
      Resource     = ["collection/${local.oss_collection_name}"]
      ResourceType = "collection"
    }]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  count = local.create_serverless_collection ? 1 : 0

  name = "${local.oss_collection_name}-net"
  type = "network"

  policy = jsonencode([{
    Description = "Bedrock KB access to vector collection"
    Rules = [{
      Resource     = ["collection/${local.oss_collection_name}"]
      ResourceType = "collection"
    }]
    AllowFromPublic = true
  }])
}

resource "aws_opensearchserverless_collection" "vector" {
  count = local.create_serverless_collection ? 1 : 0

  name = local.oss_collection_name
  type = "VECTORSEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
  ]
}

resource "aws_opensearchserverless_access_policy" "bedrock_kb" {
  count = local.use_serverless ? 1 : 0

  name = "${local.oss_collection_name}-data"
  type = "data"

  policy = jsonencode([{
    Description = "Bedrock Knowledge Base role data access"
    Rules = [
      {
        Resource = [
          "collection/${local.oss_collection_name}",
        ]
        Permission = [
          "aoss:CreateCollectionItems",
          "aoss:DeleteCollectionItems",
          "aoss:UpdateCollectionItems",
          "aoss:DescribeCollectionItems",
        ]
        ResourceType = "collection"
      },
      {
        Resource = [
          "index/${local.oss_collection_name}/*",
        ]
        Permission = [
          "aoss:CreateIndex",
          "aoss:DeleteIndex",
          "aoss:UpdateIndex",
          "aoss:DescribeIndex",
          "aoss:ReadDocument",
          "aoss:WriteDocument",
        ]
        ResourceType = "index"
      },
    ]
    Principal = distinct([
      aws_iam_role.knowledge_base.arn,
      data.aws_caller_identity.current.arn,
    ])
  }])

  depends_on = [
    aws_iam_role.knowledge_base,
    aws_opensearchserverless_collection.vector,
  ]
}
