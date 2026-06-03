# ------------------------------------------------------------------------------
# Knowledge Base — IAM
# ------------------------------------------------------------------------------

resource "aws_iam_role" "knowledge_base" {
  name = local.kb_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "bedrock.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = local.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:${local.partition}:bedrock:${var.region}:${local.account_id}:knowledge-base/*"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "knowledge_base" {
  name = "${var.kb_name}-kb-policy"
  role = aws_iam_role.knowledge_base.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "InvokeEmbeddingModel"
          Effect = "Allow"
          Action = [
            "bedrock:InvokeModel"
          ]
          Resource = [var.embedding_model_arn]
        },
        {
          Sid    = "ReadKnowledgeDocuments"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:ListBucket"
          ]
          Resource = [
            var.s3_bucket_arn,
            "${var.s3_bucket_arn}/*"
          ]
        },
      ],
      local.use_serverless ? [
        {
          Sid    = "OpenSearchServerlessCollection"
          Effect = "Allow"
          Action = [
            "aoss:APIAccessAll"
          ]
          Resource = [
            local.opensearch_collection_arn,
            "${local.opensearch_collection_arn}/*",
          ]
        },
      ] : [],
      local.use_managed ? [
        {
          Sid    = "OpenSearchManagedCluster"
          Effect = "Allow"
          Action = [
            "es:DescribeDomain",
            "es:DescribeDomains",
            "es:DescribeElasticsearchDomain",
            "es:ESHttpGet",
            "es:ESHttpPut",
            "es:ESHttpPost",
            "es:ESHttpDelete"
          ]
          Resource = [
            var.opensearch_domain_arn,
            "${var.opensearch_domain_arn}/*"
          ]
        },
      ] : [],
    )
  })
}

# ------------------------------------------------------------------------------
# Knowledge Base — Bedrock resources
# ------------------------------------------------------------------------------

resource "aws_bedrockagent_knowledge_base" "this" {
  name     = var.kb_name
  role_arn = aws_iam_role.knowledge_base.arn

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = var.embedding_model_arn
    }
  }

  storage_configuration {
    type = var.vector_store_type

    dynamic "opensearch_serverless_configuration" {
      for_each = local.use_serverless ? [1] : []

      content {
        collection_arn    = local.opensearch_collection_arn
        vector_index_name = local.vector_index_name

        field_mapping {
          vector_field   = "bedrock-knowledge-base-default-vector"
          text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
          metadata_field = "AMAZON_BEDROCK_METADATA"
        }
      }
    }

    dynamic "opensearch_managed_cluster_configuration" {
      for_each = local.use_managed ? [1] : []

      content {
        domain_arn      = var.opensearch_domain_arn
        domain_endpoint = local.opensearch_domain_endpoint

        field_mapping {
          vector_field   = "bedrock-knowledge-base-default-vector"
          text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
          metadata_field = "AMAZON_BEDROCK_METADATA"
        }

        vector_index_name = local.vector_index_name
      }
    }
  }

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy.knowledge_base,
    aws_opensearchserverless_access_policy.bedrock_kb,
  ]
}

resource "aws_bedrockagent_data_source" "s3" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.this.id
  name              = "${var.kb_name}-s3-source"

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn = var.s3_bucket_arn
    }
  }

  depends_on = [aws_bedrockagent_knowledge_base.this]
}

# ------------------------------------------------------------------------------
# Agent — IAM
# ------------------------------------------------------------------------------

resource "aws_iam_role" "agent" {
  name = local.agent_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "bedrock.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = local.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:${local.partition}:bedrock:${var.region}:${local.account_id}:agent/*"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "agent" {
  name = "${var.agent_name}-agent-policy"
  role = aws_iam_role.agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeFoundationModel"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [local.foundation_model_arn]
      },
      {
        Sid    = "RetrieveFromKnowledgeBase"
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ]
        Resource = [aws_bedrockagent_knowledge_base.this.arn]
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# Agent — Bedrock resources
# ------------------------------------------------------------------------------

resource "aws_bedrockagent_agent" "this" {
  agent_name              = var.agent_name
  agent_resource_role_arn = aws_iam_role.agent.arn
  foundation_model        = var.foundation_model_id
  instruction             = var.agent_instruction
  prepare_agent           = true

  tags = local.common_tags

  depends_on = [aws_iam_role_policy.agent]
}

resource "aws_bedrockagent_agent_alias" "this" {
  agent_alias_name = "live"
  agent_id         = aws_bedrockagent_agent.this.id

  depends_on = [aws_bedrockagent_agent.this]
}

resource "aws_bedrockagent_agent_knowledge_base_association" "this" {
  agent_id             = aws_bedrockagent_agent.this.id
  description          = "Platform knowledge base association"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.this.id
  knowledge_base_state = "ENABLED"

  depends_on = [
    aws_bedrockagent_agent.this,
    aws_bedrockagent_agent_alias.this,
    aws_bedrockagent_data_source.s3,
  ]
}
