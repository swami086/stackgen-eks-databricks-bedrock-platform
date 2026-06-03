# stackgen-databricks-lakehouse

Terraform module for **Databricks Unity Catalog** integration with an S3 medallion bucket: storage credential, external location, and SQL warehouse endpoint.

**StackGen catalog version:** `1.0.5+`

## Features

- Databricks provider **embedded in module** (required for StackGen/OpenTofu init)  
- Self-assuming IAM trust pattern for UC storage credentials  
- External location wired to existing lakehouse bucket  

## Usage

```hcl
module "lakehouse" {
  source = "git::https://github.com/swami086/stackgen-eks-databricks-bedrock-platform//stackgen-databricks-lakehouse?ref=main"

  databricks_host  = var.databricks_host
  databricks_token = var.databricks_token
  iam_role_arn     = aws_iam_role.databricks_uc.arn
  lakehouse_bucket = aws_s3_bucket.medallion.bucket
  name_prefix      = "platform"
}
```

## IAM trust (StackGen canvas)

`assume_role_policy` on the UC role must be a **JSON string** with:

1. Self-assume — `arn:aws:iam::<account>:role/<role-name>`  
2. Databricks UC — `arn:aws:iam::414351767826:root`  

## Environment secrets

Set on StackGen environment profile:

- `databricks_host`  
- `databricks_token`  

## StackGen upload

```bash
stackgen upload custom-modules \
  --scope project \
  --name stackgen-databricks-lakehouse \
  --repo-url https://github.com/swami086/stackgen-eks-databricks-bedrock-platform \
  --subdir stackgen-databricks-lakehouse \
  --version 1.0.5
```

## Reference architecture

[`examples/eks-databricks-bedrock-layer-validation`](../examples/eks-databricks-bedrock-layer-validation/)
