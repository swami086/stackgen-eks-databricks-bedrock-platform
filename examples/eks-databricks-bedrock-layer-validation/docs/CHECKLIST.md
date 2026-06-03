# Pre-apply / pre-destroy checklist

Use before **every** Plan, Apply, or Destroy on environment profile `<your-env>` (validated example: `swami_env`).

Appstack: **`eks-databricks-bedrock-layer-validation`**

---

## Gate sequence

1. [ ] **Snapshot** — record ID for rollback  
2. [ ] **Violations** — `get_current_violations` → **0**  
3. [ ] **Plan** — read full diff (not just counts)  
4. [ ] **Apply** or **Destroy** only if Plan matches expectations  
5. [ ] **Plan again** after Apply — target **0 add / 0 destroy**  
6. [ ] **Post-verify** — table at bottom  

---

## Module pins

| Module | Min version |
|--------|-------------|
| `bedrock-kb-agent-native` | **1.0.14** |
| `stackgen-databricks-lakehouse` | **1.0.5** |

Catalog uploaded and canvas resources **rebound** off legacy template-only bindings.

## Credentials (before Plan)

See **[CONFIGURATION.md](./CONFIGURATION.md)** — at minimum set on environment profile:

- [ ] `databricks_host` + `databricks_token` (not placeholders)
- [ ] `region`
- [ ] S3 state backend on profile
- [ ] Runner IAM role + Bedrock model access
- [ ] Bedrock module `additional_opensearch_data_access_principal_arns`

---

## Configuration locks

### Bedrock (`bedrock-kb-agent-native`)

- [ ] `vector_store_type` = `OPENSEARCH_SERVERLESS`  
- [ ] `opensearch_domain_arn` = **ES placeholder only** — never live `arn:aws:aoss:...` unless external-collection mode  
- [ ] `additional_opensearch_data_access_principal_arns` includes StackGen deployer IAM role  
- [ ] Collection name set (default `{kb_name}-vec`)  

### EKS Pod Identity addon

- [ ] `pod_identity_association` = **`[]`** on `eks-pod-identity-agent`  
- [ ] IRSA associations added separately after addon ACTIVE  

### Databricks UC role

- [ ] `assume_role_policy` = **JSON string** (self-assume + Databricks UC AWS account principal)  
- [ ] `databricks_host` + `databricks_token` valid on environment profile  

### Networking (L1)

- [ ] Private subnets → NAT route table (not VPC main)  
- [ ] VPC endpoints: ecr.api, ecr.dkr, sts, eks, s3 (+ Bedrock as configured)  
- [ ] EKS subnet tags: `kubernetes.io/cluster/<cluster>=shared`, internal-elb  

### Destroy-only

- [ ] S3 buckets empty or `force_destroy = true`  
- [ ] Destroy Plan reviewed  
- [ ] Snapshot ID recorded  

### Optional cleanup

- [ ] Remove legacy managed OpenSearch domain if Serverless-only  
- [ ] Helm — separate deploy or explicitly skipped  

---

## Post-apply verification

| Check | Target |
|-------|--------|
| EKS addons | `vpc-cni`, `eks-pod-identity-agent` → ACTIVE |
| Node groups | ACTIVE |
| OSS collection | ACTIVE |
| Bedrock KB | ACTIVE (OSS storage) |
| Bedrock Agent | PREPARED |
| Databricks external location | DESCRIBE succeeds |
| Follow-up Plan | 0 add, 0 destroy |

---

## Fast failure triage

Apply failed in ~5s → read **`apply_stderr`**, verify AWS console, fix config, Plan again.

See [GOTCHAS.md](./GOTCHAS.md) for root causes.
