# Configuration — credentials & environment variables

Everything you must configure **before** the first Plan/Apply on appstack `eks-databricks-bedrock-layer-validation`.

> **Never commit real secrets.** Use StackGen environment profile secrets or HCP ephemeral variables. Templates: [`../config/env.example.tfvars`](../config/env.example.tfvars).

---

## Summary table

| Name | Type | Required | Where to set | Used by |
|------|------|----------|--------------|---------|
| `databricks_host` | Secret / TF variable | **Yes** (L3 apply) | StackGen **environment profile** | `stackgen-databricks-lakehouse` |
| `databricks_token` | Secret / TF variable | **Yes** (L3 apply) | StackGen **environment profile** (mark sensitive) | Databricks provider (inside module) |
| `region` | TF variable | **Yes** | Environment profile or default `us-east-1` | AWS provider, Bedrock, OSS |
| `medallion_lakehouse_bucket_name` | TF variable | No | Environment profile; empty → auto name | S3 module |
| `knowledge_documents_bucket_name` | TF variable | No | Environment profile; empty → auto name | S3 + Bedrock KB |
| `mlflow_artifacts_bucket_name` | TF variable | No | Environment profile; empty → auto name | S3 module |
| **AWS deployer credentials** | Platform IAM | **Yes** | StackGen runner / OIDC role | All AWS resources |
| **StackGen deployer role ARN** | Canvas / module input | **Yes** (OSS index) | Bedrock module `additional_opensearch_data_access_principal_arns` | OSS data access policy |
| **S3 remote state backend** | Env profile backend | **Yes** | StackGen environment profile | OpenTofu state |
| **Bedrock model access** | AWS account setting | **Yes** | AWS Console / account policy | KB + Agent |
| **Databricks UC trust** | IAM (in canvas) | **Yes** | `databricks_uc_role` trust policy | External location |

---

## 1. StackGen environment profile

Each **environment profile** (e.g. `swami_env`, `prod`) holds Terraform variables and the remote state backend.

### 1.1 Terraform variables (appstack level)

Set these on the environment profile in StackGen UI: **Appstack → Environment → Variables**, or via `update_env_profile`.

| Variable | Sensitive | Default (if unset) | Example value |
|----------|-----------|-------------------|---------------|
| `databricks_host` | No | `https://placeholder.cloud.databricks.com` | `https://dbc-xxxxxxxx-xxxx.cloud.databricks.com` |
| `databricks_token` | **Yes** | `placeholder-token` | `dapixxxxxxxxxxxxxxxx` (Databricks PAT) |
| `region` | No | `us-east-1` | `us-east-1` |
| `medallion_lakehouse_bucket_name` | No | `""` → `layer-val-medallion-${region}` | `my-co-medallion-us-east-1` |
| `knowledge_documents_bucket_name` | No | `""` → `layer-val-knowledge-docs-${region}` | `my-co-kb-docs-us-east-1` |
| `mlflow_artifacts_bucket_name` | No | `""` → `layer-val-mlflow-${region}` | `my-co-mlflow-us-east-1` |

**Validation:** Apply will **fail on L3** if `databricks_host` / `databricks_token` are still placeholders.

Copy [`../config/env.example.tfvars`](../config/env.example.tfvars) for local OpenTofu runs; map the same keys into StackGen.

### 1.2 Remote state backend (per environment)

Configure on the environment profile (example structure):

```hcl
terraform {
  backend "s3" {
    bucket  = "<account-id>-states"
    key     = "<project>/<appstack>/<env>/terraform.tfstate"
    region  = "us-west-2"   # state bucket region (can differ from workload region)
    encrypt = true
  }
}
```

| Field | Description |
|-------|-------------|
| `bucket` | S3 bucket for Terraform state (must exist; runner needs read/write) |
| `key` | Unique path per appstack + environment |
| `region` | Region where the **state bucket** lives |
| `encrypt` | Enable SSE for state objects |

The StackGen runner role needs `s3:GetObject`, `s3:PutObject`, `s3:ListBucket` on this bucket.

---

## 2. AWS credentials (StackGen runner)

StackGen OpenTofu runs **do not** use access keys in this appstack’s `variables.tf`. AWS auth comes from the **deploy platform**:

| Item | Typical value | Purpose |
|------|---------------|---------|
| Deployer IAM role | `arn:aws:iam::<account-id>:role/Stackgen_1` | Assumed by StackGen runner for Plan/Apply |
| Workshop deploy role (Stacks/HCP) | `arn:aws:iam::<account-id>:role/stackgen-workshop-deploy` | HCP Terraform Stacks OIDC |

**Required IAM permissions (summary):** EKS, EC2/VPC, S3, IAM, KMS, DynamoDB, Route53, OpenSearch Serverless, Bedrock Agent, Bedrock, CloudWatch Logs, plus `sts:GetCallerIdentity`.

**Bedrock model access:** Enable in the target region (validated models):

- Inference: `anthropic.claude-3-haiku-20240307-v1:0` (or your chosen Claude ID on canvas)
- Embedding: `amazon.titan-embed-text-v2:0`

No separate Bedrock API key — access is via IAM + model entitlement.

---

## 3. Canvas / module inputs (not environment variables)

These are set on **resources** in the topology, not in the env profile:

| Input | Resource | Value |
|-------|----------|-------|
| `additional_opensearch_data_access_principal_arns` | Bedrock module | `["arn:aws:iam::<account-id>:role/Stackgen_1"]` |
| `vector_store_type` | Bedrock module | `OPENSEARCH_SERVERLESS` |
| `opensearch_domain_arn` | Bedrock module | ES **placeholder** ARN only (see [GOTCHAS.md](./GOTCHAS.md)) |
| `assume_role_policy` | `databricks_uc_role` | JSON string — self-assume + Databricks `414351767826` |
| `pod_identity_association` | `eks-pod-identity-agent` addon | `[]` (empty) |

---

## 4. Databricks credentials (detail)

### 4.1 Personal access token (PAT)

| Property | Value |
|----------|-------|
| **Variable** | `databricks_token` |
| **Format** | Starts with `dapi` |
| **Scopes** | Workspace admin or permissions to create storage credentials, external locations, SQL warehouses |
| **Rotation** | Update env profile → Plan → Apply if resources depend on provider auth |

### 4.2 Workspace URL

| Property | Value |
|----------|-------|
| **Variable** | `databricks_host` |
| **Format** | `https://dbc-<workspace-id>.cloud.databricks.com` (AWS) |
| **No trailing slash** | Use workspace root URL only |

### 4.3 Unity Catalog IAM trust (AWS side)

The `databricks_uc_role` IAM role trust policy must allow:

1. **Self-assume:** `arn:aws:iam::<your-account-id>:role/databricks_uc_role`
2. **Databricks UC:** `arn:aws:iam::414351767826:root` (Databricks AWS account for UC)

This is **not** a secret — it is IAM configuration on the canvas.

---

## 5. Optional bucket name overrides

If left empty, buckets are created with env-suffixed defaults:

| Variable | Default pattern |
|----------|-----------------|
| `medallion_lakehouse_bucket_name` | `layer-val-medallion-${region}` |
| `knowledge_documents_bucket_name` | `layer-val-knowledge-docs-${region}` |
| `mlflow_artifacts_bucket_name` | `layer-val-mlflow-${region}` |

Set explicit names when deploying **multiple environments** in one account to avoid collisions.

---

## 6. HCP Terraform Stacks (optional parallel track)

If using `stacks/eks-databricks-bedrock-platform/` instead of StackGen Apply:

| Input | Secret? | Source |
|-------|---------|--------|
| `identity_token` | Yes (ephemeral) | HCP workload identity OIDC |
| `role_arn` | No | AWS IAM role for Stacks runner |
| `databricks_host` | No | HCP variable / varset |
| `databricks_token` | **Yes** | HCP **ephemeral** varset — never in VCS |
| `stackgen_deployer_role_arn` | No | OSS data policy principal |
| `vpc_id`, subnet IDs, bucket ARNs | No | From StackGen apply outputs or upstream stack |

See deployment template in the Stacks repo path (if copied into your org).

---

## 7. Setup checklist

- [ ] Create StackGen **project** and **environment profile**
- [ ] Configure **S3 backend** on the profile
- [ ] Set `region` on the profile
- [ ] Create Databricks **PAT**; set `databricks_host` + `databricks_token` on profile
- [ ] Confirm runner can **assume** deployer IAM role
- [ ] Enable **Bedrock models** in AWS account/region
- [ ] Upload custom modules; set Bedrock **`additional_opensearch_data_access_principal_arns`**
- [ ] Run [CHECKLIST.md](./CHECKLIST.md) → Plan → Apply

---

## 8. Local development (OpenTofu)

For offline plan/apply against exported IaC:

```bash
cp config/env.example.tfvars terraform.tfvars
# Edit terraform.tfvars — do NOT commit
export AWS_PROFILE=<your-profile>   # or AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY
tofu init
tofu plan
```

Add `terraform.tfvars` to `.gitignore` (already ignored if named `*.local.tfvars` — use `terraform.tfvars.local` or never commit).

---

## Related

- [CREATE.md](./CREATE.md) — provisioning steps  
- [CHECKLIST.md](./CHECKLIST.md) — pre-apply gates  
- [GOTCHAS.md](./GOTCHAS.md) — credential-related failures  
