# terraform-aurora-patterns

Terraform modules and a **reference architecture** for running a four-plane AWS platform on [StackGen](https://stackgen.com):

- **EKS** — private application cluster with optional Helm workloads  
- **Databricks Unity Catalog** — medallion lakehouse on S3  
- **Amazon Bedrock** — Knowledge Base + Agent with OpenSearch Serverless vectors  

This repository is the **module source** (`bedrock-kb-agent-native`, `stackgen-databricks-lakehouse`) and the **operational documentation** for deploying and tearing down the stack safely.

## Reference architecture

| Item | Location |
|------|----------|
| **Start here** | [`examples/eks-databricks-bedrock-layer-validation/README.md`](examples/eks-databricks-bedrock-layer-validation/README.md) |
| Create the stack | [`docs/CREATE.md`](examples/eks-databricks-bedrock-layer-validation/docs/CREATE.md) |
| Destroy the stack | [`docs/DESTROY.md`](examples/eks-databricks-bedrock-layer-validation/docs/DESTROY.md) |
| Pre-flight checklist | [`docs/CHECKLIST.md`](examples/eks-databricks-bedrock-layer-validation/docs/CHECKLIST.md) |
| Known gotchas | [`docs/GOTCHAS.md`](examples/eks-databricks-bedrock-layer-validation/docs/GOTCHAS.md) |
| Architecture & diagrams | [`docs/ARCHITECTURE.md`](examples/eks-databricks-bedrock-layer-validation/docs/ARCHITECTURE.md) |

**Validated appstack name:** `eks-databricks-bedrock-layer-validation`  
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
  --repo-url https://github.com/swami086/terraform-aurora-patterns \
  --subdir bedrock-kb-agent-native \
  --version 1.0.14
```

Repeat for `stackgen-databricks-lakehouse` at version `1.0.5`.

## Repository layout

```
terraform-aurora-patterns/
├── bedrock-kb-agent-native/          # L4 — Bedrock KB + Agent + OSS
├── stackgen-databricks-lakehouse/    # L3 — Databricks UC wiring
├── examples/
│   └── eks-databricks-bedrock-layer-validation/
│       ├── README.md                 # Project overview
│       ├── docs/                     # Create, destroy, checklist, gotchas
│       └── diagrams/                 # Mermaid topology (GitHub-renderable)
└── README.md                         # This file
```

## Requirements

- AWS account with Bedrock model access (Claude + Titan Embed) in your region  
- StackGen project with OpenTofu runner and S3 remote state  
- Databricks workspace + personal access token for Unity Catalog resources  
- IAM permissions for EKS, VPC, S3, OpenSearch Serverless, Bedrock, IAM  

## License

See upstream [`dharanistack/terraform-aurora-patterns`](https://github.com/dharanistack/terraform-aurora-patterns) for lineage. Module additions in this fork are provided as reference implementations for StackGen workshops.
