# stackgen-eks-databricks-bedrock-platform

Terraform modules and a **reference architecture** for running a four-plane AWS platform on [StackGen](https://stackgen.com):

- **EKS** — private application cluster with optional Helm workloads  
- **Databricks Unity Catalog** — medallion lakehouse on S3  
- **Amazon Bedrock** — Knowledge Base + Agent with OpenSearch Serverless vectors  

This repository is the **module source** (`bedrock-kb-agent-native`, `stackgen-databricks-lakehouse`) and the **operational documentation** for deploying and tearing down the stack safely.

---

## Architecture

### Platform context (StackGen + four planes)

```mermaid
flowchart TB
  subgraph stackgen["StackGen control plane"]
    SG_UI["Topology / IaC UI"]
    SG_POL["Policy engine"]
    SG_PLAN["OpenTofu plan / apply / destroy"]
    SG_CAT["Module catalog"]
    SG_UI --> SG_POL --> SG_PLAN
    SG_CAT --> SG_UI
  end

  subgraph users["Users"]
    WEB["Web / API clients"]
    ANALYSTS["Data scientists"]
  end

  subgraph eks_plane["L2 — EKS"]
    INGRESS["Helm Ingress"]
    APPS["Workloads"]
    INGRESS --> APPS
  end

  subgraph data_plane["L3 — Databricks"]
    DBX_UC["Unity Catalog"]
    DBX_SPARK["Spark / Delta on S3"]
    DBX_UC --> DBX_SPARK
  end

  subgraph ai_plane["L4 — Bedrock"]
    BEDROCK["KB + Agent + OSS vectors"]
    FM["Claude + Titan Embed"]
    BEDROCK --> FM
  end

  subgraph aws_core["L1 — AWS foundation"]
    NET["VPC · NAT · endpoints"]
    STORE["S3 medallion · docs · mlflow"]
    IAM["IAM roles"]
    NET --> STORE
  end

  WEB --> INGRESS
  ANALYSTS --> DBX_UC
  APPS -->|InvokeAgent| BEDROCK
  APPS --> DBX_SPARK
  BEDROCK --> STORE
  DBX_SPARK --> STORE
  eks_plane & data_plane & ai_plane --> aws_core
  stackgen -.->|manages| aws_core & eks_plane & data_plane & ai_plane
```

### Infrastructure topology (L1–L4, Terraform-managed)

Validated appstack: **`eks-databricks-bedrock-layer-validation`**. Bedrock uses **OpenSearch Serverless** (not a managed OpenSearch domain).

```mermaid
flowchart TB
  subgraph L1["L1 aws_core"]
    VPC["VPC 10.30.0.0/16"]
    NAT["NAT Gateway"]
    VPCE["VPC endpoints"]
    S3L["S3 medallion"]
    S3K["S3 knowledge docs"]
    S3M["S3 mlflow"]
    IAM1["platform_iam_role"]
    IAM2["platform_irsa_role"]
    IAM3["databricks_uc_role"]
    VPC --> NAT --> VPCE
  end

  subgraph L2["L2 eks_plane"]
    EKS["EKS platform_eks"]
    NG["3x node groups"]
    CNI["vpc-cni"]
    PIA["eks-pod-identity-agent"]
    EKS --> NG & CNI & PIA
  end

  subgraph L3["L3 data_plane"]
    DBX["stackgen-databricks-lakehouse"]
    DBX --> IAM3 & S3L
  end

  subgraph L4["L4 ai_plane"]
    MOD["bedrock-kb-agent-native"]
    OSS["OSS collection + index"]
    KB["Bedrock KB"]
    AGT["Bedrock Agent"]
    MOD --> OSS --> KB --> AGT
    MOD --> S3K
  end

  L2 --> L1
  L3 --> L1
  L4 --> L1
  EKS --> VPC
```

### Network layout (private EKS)

```mermaid
flowchart LR
  subgraph internet["Internet"]
    USERS["Users"]
  end

  subgraph vpc["VPC 10.30.0.0/16"]
    subgraph pub["Public subnet"]
      NAT["NAT + IGW"]
      ALB["Ingress / ALB"]
    end

    subgraph priv["Private subnets"]
      EKS["EKS nodes"]
      VPCE["VPC endpoints"]
    end
  end

  USERS --> ALB --> EKS
  pub --> NAT --> priv
  priv --> VPCE
```

Source files (editable): [`examples/eks-databricks-bedrock-layer-validation/diagrams/`](examples/eks-databricks-bedrock-layer-validation/diagrams/)  
Deep dive: [`docs/ARCHITECTURE.md`](examples/eks-databricks-bedrock-layer-validation/docs/ARCHITECTURE.md)

---

## Reference architecture docs

| Item | Location |
|------|----------|
| **Start here** | [`examples/eks-databricks-bedrock-layer-validation/README.md`](examples/eks-databricks-bedrock-layer-validation/README.md) |
| Create the stack | [`docs/CREATE.md`](examples/eks-databricks-bedrock-layer-validation/docs/CREATE.md) |
| Destroy the stack | [`docs/DESTROY.md`](examples/eks-databricks-bedrock-layer-validation/docs/DESTROY.md) |
| Pre-flight checklist | [`docs/CHECKLIST.md`](examples/eks-databricks-bedrock-layer-validation/docs/CHECKLIST.md) |
| Known gotchas | [`docs/GOTCHAS.md`](examples/eks-databricks-bedrock-layer-validation/docs/GOTCHAS.md) |

**Example StackGen project:** `workshop-dharani`

## Custom modules

| Module | Version | Purpose |
|--------|---------|---------|
| [`bedrock-kb-agent-native`](bedrock-kb-agent-native/) | **1.0.14+** | Bedrock KB, Agent, OSS collection + vector index, IAM |
| [`stackgen-databricks-lakehouse`](stackgen-databricks-lakehouse/) | **1.0.5+** | UC storage credential, external location, SQL endpoint |

Upload to StackGen (project scope):

```bash
stackgen upload custom-modules \
  --scope project \
  --name bedrock-kb-agent-native \
  --repo-url https://github.com/swami086/stackgen-eks-databricks-bedrock-platform \
  --subdir bedrock-kb-agent-native \
  --version 1.0.14
```

Repeat for `stackgen-databricks-lakehouse` at version `1.0.5`.

## Repository layout

```
stackgen-eks-databricks-bedrock-platform/
├── bedrock-kb-agent-native/          # L4 — Bedrock KB + Agent + OSS
├── stackgen-databricks-lakehouse/    # L3 — Databricks UC wiring
├── examples/
│   └── eks-databricks-bedrock-layer-validation/
│       ├── README.md                 # Project overview + diagrams
│       ├── docs/                     # Create, destroy, checklist, gotchas
│       └── diagrams/                 # Mermaid source (.mmd)
└── README.md                         # This file
```

## Requirements

- AWS account with Bedrock model access (Claude + Titan Embed) in your region  
- StackGen project with OpenTofu runner and S3 remote state  
- Databricks workspace + personal access token for Unity Catalog resources  
- IAM permissions for EKS, VPC, S3, OpenSearch Serverless, Bedrock, IAM  

## License

Forked from [`dharanistack/terraform-aurora-patterns`](https://github.com/dharanistack/terraform-aurora-patterns). Formerly published as `swami086/terraform-aurora-patterns`.
