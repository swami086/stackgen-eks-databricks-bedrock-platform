terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.52"
    }
  }
}

variable "lakehouse_bucket" {
  type        = string
  description = "S3 bucket name for Unity Catalog external location"
}

variable "iam_role_arn" {
  type        = string
  description = "IAM role ARN granted read/write to the lakehouse bucket"
}

resource "databricks_sql_endpoint" "lakehouse_sql" {
  name                      = "eks-databricks-claude-sql"
  cluster_size              = "Small"
  max_num_clusters          = 1
  auto_stop_mins            = 30
  enable_serverless_compute = true
}

resource "databricks_storage_credential" "lakehouse_s3" {
  name = "eks-databricks-claude-s3-credential"
  aws_iam_role {
    role_arn = var.iam_role_arn
  }
  comment = "S3 credential for sample lakehouse (StackGen eks-databricks-claude-bedrock-sample)"
}

resource "databricks_external_location" "lakehouse" {
  name            = "eks-databricks-claude-lakehouse"
  url             = "s3://${var.lakehouse_bucket}"
  credential_name = databricks_storage_credential.lakehouse_s3.name
  comment         = "Lakehouse root external location"
}

output "sql_endpoint_id" {
  value = databricks_sql_endpoint.lakehouse_sql.id
}

output "external_location_name" {
  value = databricks_external_location.lakehouse.name
}
