variable "lakehouse_bucket" {
  type        = string
  description = "S3 bucket name for Unity Catalog external location"
}

variable "iam_role_arn" {
  type        = string
  description = "IAM role ARN granted read/write to the lakehouse bucket"
}

variable "databricks_host" {
  type        = string
  description = "Databricks workspace URL, e.g. https://dbc-xxxxx.cloud.databricks.com"
}

variable "databricks_token" {
  type        = string
  description = "Databricks personal access token for Terraform provider"
  sensitive   = true
}
