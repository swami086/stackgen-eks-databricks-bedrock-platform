# Create the stack

Step-by-step guide to **provision** `eks-databricks-bedrock-layer-validation` on StackGen.

**Estimated time:** 30–60 minutes (EKS node groups dominate).

---

## Step 1 — Prerequisites

- [ ] StackGen project created (example: `workshop-dharani`)
- [ ] Environment profile created (example: `swami_env`, region `us-east-1`)
- [ ] **All credentials configured** — see **[CONFIGURATION.md](./CONFIGURATION.md)** (required before apply)
- [ ] AWS credentials / deployer role configured for the runner (`Stackgen_1` or equivalent)
- [ ] Bedrock model access: Claude (inference) + Titan Embed Text v2 in target region

---

## Step 2 — Upload custom modules

From a machine with StackGen CLI:

```bash
stackgen upload custom-modules \
  --scope project \
  --name bedrock-kb-agent-native \
  --repo-url https://github.com/swami086/stackgen-eks-databricks-bedrock-platform \
  --subdir bedrock-kb-agent-native \
  --version 1.0.14

stackgen upload custom-modules \
  --scope project \
  --name stackgen-databricks-lakehouse \
  --repo-url https://github.com/swami086/stackgen-eks-databricks-bedrock-platform \
  --subdir stackgen-databricks-lakehouse \
  --version 1.0.5
```

**Rebind** canvas resources to catalog versions (Bedrock resource must not stay on template `1.0.0` only).

---

## Step 3 — Canvas configuration locks

Before first apply, confirm these settings on the topology (see [CHECKLIST.md](./CHECKLIST.md) for IDs):

| Resource | Setting | Value |
|----------|---------|-------|
| Bedrock module | `vector_store_type` | `OPENSEARCH_SERVERLESS` |
| Bedrock module | `opensearch_domain_arn` | **ES placeholder only** — e.g. `arn:aws:es:<region>:<account>:domain/kb-opensearch` |
| Bedrock module | `additional_opensearch_data_access_principal_arns` | `arn:aws:iam::<account>:role/<StackGenDeployerRole>` |
| `eks-pod-identity-agent` addon | `pod_identity_association` | **`[]` (empty)** |
| `databricks_uc_role` | `assume_role_policy` | **JSON string** with self-assume + Databricks UC principal |
| Private subnets | Route table | Associated to NAT route table (not VPC main) |
| VPC endpoints | Services | Minimum: `ecr.api`, `ecr.dkr`, `sts`, `eks`, `s3`, Bedrock runtime APIs |

---

## Step 4 — Gate sequence (create)

Run in order. Do **not** skip Plan.

```
1. create_snapshot          → record snapshot ID
2. get_current_violations   → must be 0
3. create_action_run PLAN   → read full diff
4. create_action_run APPLY  → wait until terminal (20–45m typical)
5. create_action_run PLAN   → target 0 add, 0 destroy
6. Post-verify (Step 5)
```

If Apply fails in ~5 seconds, read **`apply_stderr`** logs before retrying — partial resources may already exist.

---

## Step 5 — Post-apply verification

| Check | How |
|-------|-----|
| EKS cluster | `aws eks describe-cluster --name platform_eks` → ACTIVE |
| Addons | `vpc-cni`, `eks-pod-identity-agent` → ACTIVE |
| Node groups | 3 groups ACTIVE, desired capacity reached |
| OSS collection | OpenSearch Serverless console → `platform-knowledge-base-vec` (or configured name) ACTIVE |
| Bedrock KB | `aws bedrock-agent get-knowledge-base --knowledge-base-id <id>` → ACTIVE |
| Bedrock Agent | Agent status PREPARED |
| Databricks | `DESCRIBE EXTERNAL LOCATION \`<name>\`` in SQL warehouse |
| Second Plan | 0 to add, 0 to destroy |

---

## Step 6 — Optional follow-ups

1. **Helm workloads** — deploy the Agentic Helm pack after EKS is healthy (not part of core tfstate).  
2. **Pod Identity for IRSA** — add `aws_eks_pod_identity_association` **after** agent addon is ACTIVE (see [GOTCHAS.md](./GOTCHAS.md) §2).  
3. **Remove legacy OpenSearch domain** from canvas if using Serverless only.

---

## Troubleshooting

See [GOTCHAS.md](./GOTCHAS.md). Common first-apply failures:

- Pod identity inline association on agent addon  
- Live AOSS ARN in `opensearch_domain_arn`  
- Missing NAT route / VPC endpoints → node group `CREATE_FAILED`  
- Databricks trust policy as HCL object instead of JSON string  
- OSS index 403 → deployer role missing from data access policy  

---

## Next

- Operating checklist: [CHECKLIST.md](./CHECKLIST.md)  
- Tear down: [DESTROY.md](./DESTROY.md)
