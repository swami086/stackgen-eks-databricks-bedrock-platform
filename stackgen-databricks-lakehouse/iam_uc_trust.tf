# Unity Catalog storage credentials require the IAM role to trust itself (self-assume).

locals {
  storage_credential_role_name = element(
    split("/"),
    var.iam_role_arn,
    length(split("/", var.iam_role_arn)) - 1,
  )

  storage_credential_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "UnityCatalogSelfAssume"
        Effect = "Allow"
        Principal = {
          AWS = var.iam_role_arn
        }
        Action = "sts:AssumeRole"
      },
      {
        Sid    = "DatabricksUnityCatalogAssume"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::414351767826:root"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "terraform_data" "ensure_storage_credential_self_assume" {
  count = var.ensure_storage_credential_self_assume ? 1 : 0

  input = sha256(local.storage_credential_trust_policy)

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      ROLE_NAME    = local.storage_credential_role_name
      TRUST_POLICY = local.storage_credential_trust_policy
    }
    command     = <<-EOT
      set -euo pipefail
      tmp="$(mktemp)"
      printf '%s' "$TRUST_POLICY" > "$tmp"
      aws iam update-assume-role-policy --role-name "$ROLE_NAME" --policy-document "file://$tmp"
      rm -f "$tmp"
    EOT
  }
}
