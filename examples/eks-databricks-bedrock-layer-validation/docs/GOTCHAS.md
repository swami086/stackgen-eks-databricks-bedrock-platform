# Known gotchas (workshop-validated)

Failures observed during layer validation of `eks-databricks-bedrock-layer-validation`. Each entry includes a **permanent fix** for the next create/destroy cycle.

---

## 1. Live AOSS ARN in `opensearch_domain_arn`

**Symptom:** OpenSearch Serverless collection destroyed on apply.  
**Fix:** Use **ES placeholder** ARN only. Let module v1.0.13+ create Serverless. Never set `arn:aws:aoss:...` unless importing external collection.

---

## 2. Inline `pod_identity_association` on `eks-pod-identity-agent`

**Symptom:** Apply fails immediately — Pod Identity not supported for addon version.  
**Fix:** `pod_identity_association = []`. Add separate `aws_eks_pod_identity_association` after addon is ACTIVE.

[AWS EKS Pod Identity setup](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-agent-setup.html)

---

## 3. OSS data policy used STS session ARN

**Symptom:** `opensearch_index` 403 during apply.  
**Fix:** Module **v1.0.14** uses stable IAM role ARN only. Set `additional_opensearch_data_access_principal_arns` to deployer role (e.g. `arn:aws:iam::<account>:role/Stackgen_1`).

---

## 4. Bedrock KB before vector index exists

**Symptom:** KB creation 404 on index.  
**Fix:** Module **v1.0.8+** creates `opensearch_index` with 60s settle after data policy.

---

## 5. Databricks UC trust policy as HCL object

**Symptom:** Plan/apply errors on IAM role.  
**Fix:** `assume_role_policy` must be **JSON string** with self-assume + Databricks principal (`414351767826`).

---

## 6. StackGen UI shows failed while AWS partially created

**Symptom:** ~5s failed apply; resources exist in console.  
**Fix:** Read logs, verify state, Plan → Apply → Plan. Do not trust UI status alone.

---

## 7. Helm not in Terraform state

**Symptom:** Recreate does not restore pods/ingress.  
**Fix:** Deploy Helm pack separately after EKS ACTIVE.

---

## 8. Legacy managed OpenSearch still provisioned

**Symptom:** Extra cost; KB uses Serverless anyway.  
**Fix:** Remove managed OpenSearch resource from canvas when Serverless-only.

---

## 9. S3 blocks destroy

**Symptom:** Destroy fails on non-empty buckets.  
**Fix:** Empty buckets or `force_destroy = true` (dev only).

---

## 10. kubectl timeout from laptop

**Symptom:** Cannot reach private EKS API.  
**Fix:** Expected with private endpoint. Use in-VPC access; not an apply blocker.

---

## 11. OSS policy plan drift every run

**Symptom:** Plan always shows 1 update on access policy.  
**Fix:** Upgrade to module **v1.0.14** + pin deployer role in `additional_opensearch_data_access_principal_arns`.

---

## 12. Node groups CREATE_FAILED

**Symptom:** Workers cannot join cluster.  
**Fix:** Private subnets must route `0.0.0.0/0` via NAT; add ECR/STS/EKS VPC endpoints.

---

Before every run: [CHECKLIST.md](./CHECKLIST.md)
