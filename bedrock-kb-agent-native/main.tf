data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
}

resource "aws_iam_role" "knowledge_base" {
  name = "${var.kb_name}-kb-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy" "knowledge_base" {
  name = "${var.kb_name}-kb-policy"
  role = aws_iam_role.knowledge_base.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [var.embedding_model_arn]
      },
      {
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
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll"
        ]
        Resource = [var.opensearch_domain_arn]
      },
      {
        Effect = "Allow"
        Action = [
          "es:DescribeDomain",
          "es:DescribeDomains",
          "es:ESHttpGet",
          "es:ESHttpPut",
          "es:ESHttpPost",
          "es:ESHttpDelete"
        ]
        Resource = [
          var.opensearch_domain_arn,
          "${var.opensearch_domain_arn}/*"
        ]
      }
    ]
  })
}

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
    type = "OPENSEARCH_MANAGED_CLUSTER"

    opensearch_managed_cluster_configuration {
      domain_arn      = var.opensearch_domain_arn
      domain_endpoint = var.opensearch_domain_endpoint

      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }

      vector_index_name = "bedrock-knowledge-base-default-index"
    }
  }

  tags = var.tags
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
}

resource "aws_iam_role" "agent" {
  name = "${var.agent_name}-agent-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy" "agent" {
  name = "${var.agent_name}-agent-policy"
  role = aws_iam_role.agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:${local.partition}:bedrock:${var.region}::foundation-model/${var.foundation_model_id}"
        ]
      },
      {
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

resource "aws_bedrockagent_agent" "this" {
  agent_name              = var.agent_name
  agent_resource_role_arn = aws_iam_role.agent.arn
  foundation_model        = var.foundation_model_id
  instruction             = var.agent_instruction
  prepare_agent           = true

  tags = var.tags
}

resource "aws_bedrockagent_agent_alias" "this" {
  agent_alias_name = "live"
  agent_id         = aws_bedrockagent_agent.this.id
}

resource "aws_bedrockagent_agent_knowledge_base_association" "this" {
  agent_id             = aws_bedrockagent_agent.this.id
  description          = "Platform knowledge base association"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.this.id
  knowledge_base_state = "ENABLED"
}
