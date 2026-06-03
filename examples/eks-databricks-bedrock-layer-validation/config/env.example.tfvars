# Copy to terraform.tfvars for local OpenTofu runs.
# DO NOT commit this file with real values — use StackGen environment profile secrets in production.

# --- Required for full stack (L3 Databricks) ---
databricks_host  = "https://dbc-xxxxxxxx-xxxx.cloud.databricks.com"
databricks_token = "dapi<your-databricks-personal-access-token>"

# --- AWS region (L1–L4) ---
region = "us-east-1"

# --- Optional S3 bucket overrides (leave "" for default layer-val-* names) ---
medallion_lakehouse_bucket_name   = ""
knowledge_documents_bucket_name   = ""
mlflow_artifacts_bucket_name      = ""

# --- AWS credentials for local runs (not StackGen variables) ---
# Configure via environment or ~/.aws/credentials:
#   export AWS_PROFILE=your-profile
#   export AWS_REGION=us-east-1
