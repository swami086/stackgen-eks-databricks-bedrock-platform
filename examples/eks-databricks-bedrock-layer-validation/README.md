# EKS + Databricks + Bedrock — Reference Architecture

A **layer-validated** AWS reference stack for interactive RAG and lakehouse analytics. Infrastructure is defined on a [StackGen](https://stackgen.com) canvas and applied with OpenTofu; reusable logic lives in this repository’s custom modules.

## What this project is

This stack proves that four planes can be composed **deterministically** from a single topology:

| Layer | Plane | What gets created |
|-------|-------|-------------------|
| **L1** | `aws_core` | VPC `10.30.0.0/16`, private/public subnets, NAT, VPC endpoints (S3, DynamoDB, ECR, STS, EKS, Bedrock), three KMS-encrypted S3 buckets, DynamoDB, Route53 private zone, IAM roles |
| **L2** | `eks_plane` | Private EKS cluster `platform_eks`, three `t3.medium` node groups, `vpc-cni` + `eks-pod-identity-agent` addons; optional Helm workload pack (separate from core Terraform state) |
| **L3** | `data_plane` | Databricks storage credential, external location on medallion bucket, SQL warehouse endpoint |
| **L4** | `ai_plane` | Bedrock Knowledge Base + Agent, **OpenSearch Serverless** vector collection, S3 document source, embedding + inference models |

**Primary use cases**

1. **Interactive RAG** — EKS (or external) clients invoke a Bedrock Agent backed by a Knowledge Base.  
2. **Lakehouse analytics** — Databricks reads/writes the medallion S3 bucket via Unity Catalog.  
3. **Workshop / CI validation** — repeatable create → verify → destroy cycles with policy gates and snapshots.

---

## Architecture diagrams

### 1. Platform context

StackGen manages IaC across four planes.

```mermaid
flowchart TB
  subgraph stackgen["StackGen control plane"]
    SG_UI["Topology / IaC UI"]
    SG_POL["Policy engine · 0 violations target"]
    SG_PLAN["OpenTofu plan / apply / destroy"]
    SG_CAT["Module catalog"]
    SG_UI --> SG_POL --> SG_PLAN
    SG_CAT --> SG_UI
  end

  subgraph users["Users"]
    WEB["Web / API clients"]
    ANALYSTS["Data scientists"]
    BIZ["Business users"]
  end

  subgraph eks_plane["L2 — EKS application plane"]
    INGRESS["Helm Ingress"]
    APPS["Helm Workloads"]
    INGRESS --> APPS
  end

  subgraph data_plane["L3 — Databricks data plane"]
    DBX_UC["Unity Catalog"]
    DBX_SPARK["Spark / Delta on S3"]
    DBX_UC --> DBX_SPARK
  end

  subgraph ai_plane["L4 — Amazon Bedrock AI plane"]
    BEDROCK["bedrock-kb-agent-native"]
    FM["Claude + Titan Embed"]
    BEDROCK --> FM
  end

  subgraph aws_core["L1 — AWS foundation"]
    NET["VPC · NAT · endpoints"]
    STORE["S3 medallion · docs · mlflow"]
    IAM["IAM · IRSA · UC role"]
    NET --> STORE
  end

  WEB & ANALYSTS & BIZ --> INGRESS
  APPS -->|InvokeAgent| BEDROCK
  APPS --> DBX_SPARK
  ANALYSTS --> DBX_UC
  BEDROCK --> STORE
  DBX_SPARK --> STORE
  eks_plane & data_plane & ai_plane --> aws_core
  stackgen -.->|manages| aws_core & eks_plane & data_plane & ai_plane
```

### 2. Full infrastructure topology (Terraform)

Post-apply resource graph. Vector store = **OpenSearch Serverless** (`bedrock-kb-agent-native` v1.0.14+).

```mermaid
flowchart TB
  subgraph tfvars["Inputs"]
    VAR_REGION["var.region"]
    VAR_DBX["var.databricks_host / token"]
  end

  subgraph L1["L1 aws_core"]
    VPC["aws_vpc · 10.30.0.0/16"]
    NAT["NAT + EIP"]
    VPCE["VPC endpoints · s3 ddb ecr sts eks bedrock"]
    S3L["S3 medallion + KMS"]
    S3K["S3 knowledge docs + KMS"]
    S3M["S3 mlflow + KMS"]
    IAM_EKS["platform_iam_role"]
    IAM_IRSA["platform_irsa_role"]
    IAM_UC["databricks_uc_role"]
    DDB["DynamoDB metadata"]
    R53["Route53 private zone"]
    VPC --> NAT & VPCE
  end

  subgraph L2["L2 eks_plane"]
    EKS["aws_eks · platform_eks · private API"]
    NG1["node group primary"]
    NG2["node group secondary"]
    NG3["node group tertiary"]
    CNI["addon vpc-cni"]
    PIA["addon eks-pod-identity-agent"]
    EKS --> NG1 & NG2 & NG3 & CNI & PIA
  end

  subgraph L3["L3 data_plane"]
    DBX["stackgen-databricks-lakehouse"]
    DBX --> IAM_UC & S3L & VAR_DBX
  end

  subgraph L4["L4 ai_plane"]
    FM_I["data FM Claude"]
    FM_E["data FM Titan embed"]
    subgraph bedrock["bedrock-kb-agent-native v1.0.14+"]
      OSS_POL["OSS security + data policies"]
      OSS_COL["OSS VECTORSEARCH collection"]
      OSS_IDX["opensearch_index"]
      KB_ROLE["KB IAM role"]
      KB["Knowledge Base"]
      DS["S3 data source"]
      AGT["Agent + alias"]
      OSS_POL --> OSS_COL --> OSS_IDX --> KB
      KB_ROLE --> KB --> DS
      KB --> AGT
    end
    S3K --> DS
    FM_I & FM_E --> bedrock
    VAR_REGION --> bedrock
  end

  VPC --> EKS
  IAM_EKS --> EKS & NG1 & NG2 & NG3
  IAM_IRSA -.->|Pod Identity| EKS
```

### 3. Network layout

Private EKS API; egress via NAT; AWS APIs via VPC endpoints.

```mermaid
flowchart LR
  subgraph internet["Internet"]
    USERS["Users"]
  end

  subgraph vpc["VPC 10.30.0.0/16"]
    subgraph pub["Public 10.30.0.0/24"]
      IGW["Internet Gateway"]
      NAT["NAT Gateway + EIP"]
      IGW --- NAT
    end

    subgraph priv_a["Private 10.30.1.0/24"]
      EKS_A["EKS nodes / CP ENIs"]
    end

    subgraph priv_b["Private 10.30.2.0/24"]
      EKS_B["EKS nodes"]
    end

    VPCE["VPC endpoints · s3 · ddb · ecr · sts · eks · bedrock"]
  end

  USERS -.->|443 via Ingress| EKS_A
  pub --> NAT
  NAT --> priv_a & priv_b
  priv_a & priv_b --> VPCE
  EKS_A & EKS_B -.->|AWS APIs| VPCE
```

### 4. RAG request flow (runtime)

```mermaid
sequenceDiagram
  participant User
  participant EKS as EKS workload
  participant Agent as Bedrock Agent
  participant KB as Knowledge Base
  participant OSS as OpenSearch Serverless
  participant S3 as S3 documents

  User->>EKS: HTTPS request
  EKS->>Agent: InvokeAgent
  Agent->>KB: Retrieve
  KB->>OSS: Vector search
  KB->>S3: Fetch chunks
  Agent->>User: Response
```

Editable source: [`diagrams/`](diagrams/) (`.mmd` files) · Written guide: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

---

## Module versions (pin before apply)

| Module | Minimum version | Notes |
|--------|-----------------|-------|
| `bedrock-kb-agent-native` | **1.0.14** | OSS index before KB; stable OSS data-policy principals |
| `stackgen-databricks-lakehouse` | **1.0.5** | Self-assuming UC IAM trust |

Source: this repo (`main` branch or tagged release).

## Prerequisites

1. **StackGen** project with an environment profile and S3 remote state.  
2. **AWS** — Bedrock foundation models enabled in target region (validated in **us-east-1**).  
3. **Databricks** — workspace URL and token as environment secrets.  
4. **Catalog upload** — both custom modules uploaded and bound on the canvas.

## Quick start

| Action | Doc |
|--------|-----|
| **Create** | [docs/CREATE.md](docs/CREATE.md) |
| **Destroy** | [docs/DESTROY.md](docs/DESTROY.md) |
| **Every run** | [docs/CHECKLIST.md](docs/CHECKLIST.md) |
| **Failures** | [docs/GOTCHAS.md](docs/GOTCHAS.md) |

## What is *not* in Terraform state

| Component | Behavior |
|-----------|----------|
| **Helm pack** | On canvas; deploy separately after EKS is ACTIVE |
| **Legacy managed OpenSearch** | Optional; Bedrock uses **Serverless** |
| **kubectl from laptop** | Private EKS API — VPC access required |

## Related links

- Module: [`bedrock-kb-agent-native`](../../bedrock-kb-agent-native/)  
- Module: [`stackgen-databricks-lakehouse`](../../stackgen-databricks-lakehouse/)  
- Root repo README: [`../../README.md`](../../README.md)
