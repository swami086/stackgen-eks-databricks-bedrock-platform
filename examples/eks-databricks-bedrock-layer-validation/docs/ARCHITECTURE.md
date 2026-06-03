# Architecture

Technical reference for **eks-databricks-bedrock-layer-validation**: four planes, network layout, data flows, and module boundaries.

---

## Platform context

StackGen manages IaC; four planes share AWS foundation resources.

```mermaid
flowchart TB
  subgraph stackgen["StackGen control plane"]
    SG_UI["Topology / IaC UI"]
    SG_POL["Policy engine"]
    SG_PLAN["OpenTofu plan / apply / destroy"]
    SG_UI --> SG_POL --> SG_PLAN
  end

  subgraph users["Users"]
    WEB["Web / API clients"]
    ANALYSTS["Data scientists"]
  end

  subgraph eks_plane["L2 — EKS"]
    INGRESS["Helm Ingress"]
    APPS["Workloads"]
  end

  subgraph data_plane["L3 — Databricks"]
    DBX_UC["Unity Catalog"]
    DBX_SPARK["Spark / Delta"]
  end

  subgraph ai_plane["L4 — Bedrock"]
    KB["Knowledge Base"]
    AGT["Agent"]
    OSS["OpenSearch Serverless"]
  end

  subgraph aws_core["L1 — AWS foundation"]
    NET["VPC · NAT · endpoints"]
    STORE["S3 × 3"]
    IAM["IAM roles"]
  end

  WEB --> INGRESS --> APPS
  APPS -->|InvokeAgent| AGT
  APPS --> DBX_SPARK
  AGT --> KB --> OSS
  KB --> STORE
  DBX_UC --> STORE
  eks_plane & data_plane & ai_plane --> aws_core
  stackgen -.-> aws_core & eks_plane & data_plane & ai_plane
```

Source: [`../diagrams/platform-context.mmd`](../diagrams/platform-context.mmd)

---

## Full topology (Terraform-managed)

Post-apply resource graph (~76 managed resources in validated deployment). Bedrock vector store uses **OpenSearch Serverless** (not the optional legacy managed domain).

```mermaid
flowchart TB
  subgraph L1["L1 aws_core"]
    VPC["VPC 10.30.0.0/16"]
    NAT["NAT Gateway"]
    VPCE["VPC endpoints<br/>s3 · ddb · ecr · sts · eks · bedrock"]
    S3L["S3 medallion"]
    S3K["S3 knowledge docs"]
    S3M["S3 mlflow"]
    IAM1["platform_iam_role"]
    IAM2["platform_irsa_role"]
    IAM3["databricks_uc_role"]
    VPC --> NAT --> VPCE
  end

  subgraph L2["L2 eks_plane"]
    EKS["EKS platform_eks<br/>private API"]
    NG["3× node groups"]
    CNI["vpc-cni addon"]
    PIA["eks-pod-identity-agent<br/>no inline associations"]
    EKS --> NG & CNI & PIA
  end

  subgraph L3["L3 data_plane"]
    DBX["module stackgen-databricks-lakehouse"]
    DBX --> IAM3
    DBX --> S3L
  end

  subgraph L4["L4 ai_plane"]
    FM1["Claude FM data"]
    FM2["Titan embed data"]
    MOD["module bedrock-kb-agent-native v1.0.14+"]
    OSS["OSS collection + index"]
    KB["Bedrock KB"]
    AGT["Bedrock Agent"]
    MOD --> OSS --> KB --> AGT
    MOD --> S3K
    FM1 & FM2 --> MOD
  end

  L2 --> L1
  L3 --> L1
  L4 --> L1
  EKS --> VPC
```

Source: [`../diagrams/topology.mmd`](../diagrams/topology.mmd)

---

## Network layout

Private EKS and workloads; public subnet for NAT and ingress path.

```mermaid
flowchart LR
  subgraph internet["Internet"]
    USERS["Users"]
  end

  subgraph vpc["VPC 10.30.0.0/16"]
    subgraph pub["Public 10.30.0.0/24"]
      NAT["NAT + IGW"]
      ALB["Ingress / ALB"]
    end

    subgraph priv["Private subnets"]
      EKS["EKS nodes + CP ENIs"]
      VPCE["Interface endpoints"]
    end
  end

  USERS --> ALB --> EKS
  pub --> NAT --> priv
  priv --> VPCE
```

Source: [`../diagrams/network.mmd`](../diagrams/network.mmd)

---

## RAG request flow (runtime)

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
  Agent->>KB: Retrieve (embed query)
  KB->>OSS: Vector search
  KB->>S3: Fetch source chunks
  Agent->>User: Generated response
```

---

## Module boundaries

| Module | Creates | Depends on |
|--------|---------|------------|
| `bedrock-kb-agent-native` | OSS policies/collection/index, KB IAM, KB, data source, Agent, alias | S3 ARN, FM ARNs, deployer principal for OSS |
| `stackgen-databricks-lakehouse` | Storage credential, external location, SQL endpoint | UC IAM role ARN, lakehouse bucket name, Databricks provider config |

Both modules embed required providers (`databricks` inside lakehouse module; `opensearch` + `time` inside Bedrock module).

---

## State and environments

- **Remote state:** S3 backend per StackGen project/environment  
- **One appstack, many envs:** duplicate environment profile; suffix bucket names via tfvars  
- **Snapshots:** topology rollback only — not AWS resource restore  

---

## Diagram files

| File | Description |
|------|-------------|
| [`platform-context.mmd`](../diagrams/platform-context.mmd) | StackGen + four planes |
| [`topology.mmd`](../diagrams/topology.mmd) | L1–L4 resource graph |
| [`network.mmd`](../diagrams/network.mmd) | VPC subnets and NAT |

Render on [Mermaid Live Editor](https://mermaid.live) or GitHub Markdown preview.
