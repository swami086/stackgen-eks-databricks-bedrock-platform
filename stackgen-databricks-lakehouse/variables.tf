variable "databricks_host" {
  description = "Databricks workspace URL, e.g. https://dbc-xxxxx.cloud.databricks.com"
  type        = string

  validation {
    condition     = can(regex("^https://", var.databricks_host))
    error_message = "databricks_host must be an HTTPS workspace URL."
  }
}

variable "databricks_token" {
  description = "Databricks personal access token for the Terraform provider"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.databricks_token) > 0
    error_message = "databricks_token must not be empty."
  }
}

variable "iam_role_arn" {
  description = "IAM role ARN granted read/write to the lakehouse bucket"
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam:", var.iam_role_arn))
    error_message = "iam_role_arn must be an IAM role ARN."
  }
}

variable "lakehouse_bucket" {
  description = "S3 bucket name for the Unity Catalog external location"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.lakehouse_bucket))
    error_message = "lakehouse_bucket must be a valid S3 bucket name."
  }
}

variable "name_prefix" {
  description = "Prefix for Databricks resource names. Use platform for new templates; keep eks-databricks-claude if upgrading an existing workshop appstack without renaming resources."
  type        = string
  default     = "eks-databricks-claude"

  validation {
    condition     = can(regex("^[0-9a-zA-Z_-]{1,32}$", var.name_prefix))
    error_message = "name_prefix must be 1-32 characters (letters, numbers, hyphen, underscore)."
  }
}

variable "ensure_storage_credential_self_assume" {
  description = "Update the storage credential IAM role trust policy to include Unity Catalog self-assume before creating the external location."
  type        = bool
  default     = true
}
