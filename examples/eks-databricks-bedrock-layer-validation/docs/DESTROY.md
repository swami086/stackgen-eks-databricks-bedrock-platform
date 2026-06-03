# Destroy the stack

Step-by-step guide to **tear down** `eks-databricks-bedrock-layer-validation` safely on StackGen.

**Warning:** Destroy is irreversible for data in S3 buckets, Bedrock KB indices, and Databricks UC objects unless you back up first.

---

## Step 1 — Before you destroy

- [ ] **Snapshot** the topology (`create_snapshot`) — you can restore canvas layout, not AWS data
- [ ] Confirm you are targeting the correct **environment profile**
- [ ] Export any data you need from:
  - Medallion S3 bucket  
  - Knowledge documents bucket  
  - MLflow artifacts bucket  
  - Bedrock KB documents in S3  
- [ ] Note: **Helm releases** are not in Terraform state — delete manually from cluster if deployed

---

## Step 2 — S3 bucket preparation

Terraform cannot delete non-empty buckets unless `force_destroy = true`.

**Option A — Empty buckets (safest for shared accounts)**

```bash
aws s3 rm s3://<medallion-bucket> --recursive
aws s3 rm s3://<knowledge-docs-bucket> --recursive
aws s3 rm s3://<mlflow-bucket> --recursive
```

**Option B — Dev environments**

Set `force_destroy = true` on S3 module resources before destroy (workshop export pattern).

Buckets in this architecture (default naming):

- `layer-val-medallion-<region>`
- `layer-val-knowledge-docs-<region>`
- `layer-val-mlflow-<region>`

---

## Step 3 — Destroy gate sequence

```
1. create_snapshot
2. get_current_violations → 0
3. create_action_run PLAN (Destroy)  → review destroy order
4. create_action_run DESTROY         → wait until terminal
5. create_action_run PLAN            → confirm empty / no managed resources
```

Review the destroy plan for:

- EKS node groups before cluster  
- Bedrock KB before OSS collection (module handles dependencies)  
- Databricks external location before IAM role (provider order)  
- OpenSearch Serverless policies before collection  

---

## Step 4 — Post-destroy verification

| Check | Expected |
|-------|----------|
| StackGen state | No remaining managed resources (or empty state) |
| EKS | Cluster deleted |
| OSS | Collection and policies removed |
| Bedrock | KB and Agent deleted |
| S3 | Buckets deleted or empty |
| Databricks | External location / credential removed (or orphaned — clean in workspace UI) |
| VPC | VPC and subnets deleted |

---

## Step 5 — Partial destroy / stuck resources

If destroy fails mid-way:

1. Read **`apply_stderr`** / destroy logs in StackGen  
2. Fix blockers (non-empty S3, ENI dependencies, log groups)  
3. Re-run **Destroy Plan** → **Destroy**  
4. For orphaned AWS resources, use console or targeted `terraform destroy` against exported IaC  

**Rollback topology only:** `restore_snapshot` — does **not** recreate AWS resources.

---

## Step 6 — Recreate after destroy

Follow [CREATE.md](./CREATE.md) from Step 2 (module versions) onward.

Use [CHECKLIST.md](./CHECKLIST.md) and [GOTCHAS.md](./GOTCHAS.md) to avoid repeating workshop failures.

**Expect new resource IDs** — ARNs and Bedrock IDs will differ from the previous deployment.

---

## Private EKS note

With `endpoint_public_access = false`, you cannot use `kubectl` from a laptop without VPC connectivity. Destroy does not require kubectl — StackGen/OpenTofu drives teardown via AWS APIs.

---

## Related

- Pre-flight: [CHECKLIST.md](./CHECKLIST.md)  
- Known issues: [GOTCHAS.md](./GOTCHAS.md)
