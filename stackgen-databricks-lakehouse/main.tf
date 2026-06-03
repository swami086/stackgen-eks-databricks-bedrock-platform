resource "databricks_sql_endpoint" "lakehouse_sql" {
  name                      = "${var.name_prefix}-lakehouse-sql"
  cluster_size              = "Small"
  max_num_clusters          = 1
  auto_stop_mins            = 30
  enable_serverless_compute = true
}

resource "databricks_storage_credential" "lakehouse_s3" {
  name = "${var.name_prefix}-lakehouse-s3-credential"

  aws_iam_role {
    role_arn = var.iam_role_arn
  }

  comment = "S3 credential for platform lakehouse (StackGen stackgen-databricks-lakehouse)"
}

resource "databricks_external_location" "lakehouse" {
  name            = "${var.name_prefix}-lakehouse"
  url             = "s3://${var.lakehouse_bucket}"
  credential_name = databricks_storage_credential.lakehouse_s3.name
  comment         = "Lakehouse root external location"
}
