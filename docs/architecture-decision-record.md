# Architecture Decision Records (ADR)

> This document captures the key architectural decisions made during the design and implementation of the Azure Landing Zone. Each ADR follows the standard format: Context → Decision → Consequences.

---

## ADR-001: Infrastructure-as-Code Tool — Bicep over Terraform

**Status:** Accepted  
**Date:** 2026-04-06  
**Decision Maker:** Ricardo Garcia

### Context

The Landing Zone requires an Infrastructure-as-Code (IaC) tool to define, version, and deploy Azure resources consistently across Dev, QA, and Prod environments. The two leading options are:

- **HashiCorp Terraform** — the industry-standard multi-cloud IaC tool with HCL syntax, state file management, and a massive provider ecosystem.
- **Azure Bicep** — Microsoft's domain-specific language (DSL) that compiles to ARM templates, with native Azure integration and zero state management overhead.

### Decision

**Use Azure Bicep as the primary IaC tool for this Landing Zone.**

### Consequences

| Aspect | Positive | Negative |
|--------|----------|----------|
| Azure Integration | First-class support in Azure CLI, Azure DevOps, and GitHub Actions. No provider version drift. | Azure-only — cannot manage AWS/GCP resources. |
| State Management | No state file to manage, lock, or accidentally corrupt. Deployments are idempotent by design. | Cannot detect drift as easily as Terraform (mitigated by `az deployment what-if` and scheduled drift-detection workflows). |
| IntelliSense | VS Code Bicep extension provides real-time validation, auto-complete for all Azure resource types and API versions. | Terraform has broader community snippets and modules on the Terraform Registry. |
| Learning Curve | Familiar to anyone with ARM template experience. Simpler syntax than HCL for Azure-only shops. | Engineers with Terraform experience will need to learn a new syntax. |
| Team Adoption | Microsoft actively develops Bicep; it is the recommended IaC tool in the Cloud Adoption Framework. | Terraform is more commonly requested in multi-cloud job postings. |
| Cost | Free, open-source, no backend infrastructure required. | Terraform is also free (open-source), but Terraform Cloud/Enterprise has paid tiers. |

### Notes

For consulting engagements where the client uses AWS or multi-cloud, Terraform would be the correct choice. This ADR applies specifically to Microsoft-stack organizations — which represents the majority of PwC's Azure consulting work.

---

## ADR-002: Network Topology — Hub-Spoke over Flat VNet

**Status:** Accepted  
**Date:** 2026-04-06  
**Decision Maker:** Ricardo Garcia

### Context

The Landing Zone must support multiple environments (Dev, QA, Prod) with network isolation between workloads while providing shared services (DNS resolution, monitoring, bastion access). The primary options are:

- **Flat VNet** — all resources in a single VNet with subnet-level isolation via NSGs.
- **Hub-Spoke** — a central hub VNet for shared services, with peered spoke VNets for each workload or environment.
- **Azure Virtual WAN** — a Microsoft-managed hub that automates peering, VPN, and ExpressRoute connectivity.

### Decision

**Use Hub-Spoke topology with VNet peering.**

### Consequences

| Aspect | Positive | Negative |
|--------|----------|----------|
| Isolation | Strong blast radius containment — a misconfigured NSG in the dev spoke cannot affect prod traffic. | More complex than a flat VNet; requires managing peering relationships. |
| Scalability | Adding a new workload = adding a new spoke. No re-addressing existing VNets. | Each spoke requires a peering to the hub (~$0.01/GB transferred, negligible for dev). |
| Shared Services | Bastion, DNS, monitoring agents live in the hub and serve all spokes. Single point of management. | Hub becomes a single point of failure (mitigated by Azure SLA on VNets: 99.95%). |
| Cost | VNets and peering are free. Only data transfer across peering incurs cost. | Azure Virtual WAN would simplify management at scale but costs ~$0.05/hr per hub — unnecessary for this scope. |
| Enterprise Alignment | This is the topology recommended by the Microsoft Cloud Adoption Framework and Azure Well-Architected Framework. | Smaller organizations (< 50 resources) may find a flat VNet sufficient. |

### CIDR Allocation

| VNet | CIDR | Environment |
|------|------|-------------|
| Hub | 10.0.0.0/16 | Shared |
| Spoke-Dev | 10.1.0.0/16 | Development |
| Spoke-QA | 10.2.0.0/16 | Quality Assurance |
| Spoke-Prod | 10.3.0.0/16 | Production |

### Notes

Virtual WAN is the correct choice for organizations with 10+ spokes, multiple regions, or VPN/ExpressRoute requirements. For this Landing Zone with 3 spokes in a single region, hub-spoke with manual peering provides equivalent functionality at zero additional cost.

---

## ADR-003: Key Vault Authorization — RBAC over Access Policies

**Status:** Accepted  
**Date:** 2026-04-06  
**Decision Maker:** Ricardo Garcia

### Context

Azure Key Vault supports two authorization models:

- **Vault Access Policies** — legacy model where permissions are assigned per-vault as a flat list of users/apps with specific key/secret/certificate permissions.
- **Azure RBAC** — uses the standard Azure role-based access control model with built-in roles (Key Vault Secrets Officer, Key Vault Reader, etc.).

### Decision

**Use Azure RBAC authorization for all Key Vaults (`enableRbacAuthorization: true`).**

### Consequences

| Aspect | Positive | Negative |
|--------|----------|----------|
| Unified Management | Same RBAC model used for all Azure resources. One place to audit who has access to what. | Slightly more complex initial setup (must assign roles, not just add access policies). |
| PIM Integration | Supports Privileged Identity Management (Entra ID P1 feature) for just-in-time access to secrets. | Access Policies do not support PIM at all. |
| Scope Flexibility | Can grant access at management group, subscription, resource group, or individual vault level. | Access Policies only work at the individual vault level. |
| Audit | Full integration with Entra ID sign-in and audit logs. | Access Policy changes are logged differently and harder to correlate. |
| Microsoft Recommendation | RBAC is the recommended model as of 2024. New vaults default to RBAC in the Azure Portal. | Some legacy documentation and tutorials still show Access Policies. |

### Notes

This decision leverages our Entra ID P1 license, which provides Conditional Access and PIM. Access Policies would waste this capability.

---

## ADR-004: Environment Strategy — Single Subscription with RG Isolation

**Status:** Accepted  
**Date:** 2026-04-06  
**Decision Maker:** Ricardo Garcia

### Context

Enterprise best practice recommends one Azure subscription per environment (Dev, QA, Prod) to provide hard billing and access boundaries. However, this Landing Zone is deployed in a personal learning tenant with a $15/month budget constraint.

### Decision

**Use a single Azure subscription with resource group-level isolation for Dev, QA, and Prod. Migrate to multi-subscription when budget allows or when preparing for a production consulting engagement.**

### Consequences

| Aspect | Positive | Negative |
|--------|----------|----------|
| Simplicity | Single subscription to manage, single billing view, single service principal for pipelines. | No hard billing boundary between environments — a runaway dev resource could consume prod budget. |
| Cost | Zero overhead. No additional subscription management. | Cannot leverage per-subscription spending caps (mitigated by Azure Budgets and resource group tags). |
| RBAC | Can still isolate access at RG level using RBAC role assignments. | A subscription-level Owner could accidentally modify prod RGs (mitigated by pipeline-only deployment + branch protection). |
| Naming Convention | The naming convention (`rg-{env}-{region}-{workload}`) clearly separates resources even within a single subscription. | Requires discipline — no automated subscription-level boundary enforcement. |
| Migration Path | The Bicep modules are subscription-agnostic. Moving to multi-subscription requires only changing the `az account set` or pipeline service connection — zero code changes. | Must remember to update documentation when migrating. |

### Notes

For client-facing work at PwC, always recommend multi-subscription architecture aligned with the Cloud Adoption Framework. This ADR documents the pragmatic decision for a learning environment.

---

## ADR-005: Azure Policy Enforcement — Audit-First, Then Deny

**Status:** Accepted  
**Date:** 2026-04-06  
**Decision Maker:** Ricardo Garcia

### Context

Azure Policy can enforce governance rules with two primary effects:

- **Audit** — flags non-compliant resources but allows creation.
- **Deny** — blocks non-compliant resource creation entirely.

### Decision

**Deploy all policies with `effect: Audit` initially. After 1–2 weeks of compliance data review, upgrade critical policies to `effect: Deny`.**

### Consequences

| Aspect | Positive | Negative |
|--------|----------|----------|
| Safety | No risk of accidentally blocking legitimate deployments during initial rollout. | Non-compliant resources can still be created during the audit period. |
| Visibility | Compliance dashboard in Azure Portal shows exactly which resources would be blocked. | Requires manual review to identify false positives before switching to Deny. |
| Enterprise Pattern | This is the standard enterprise rollout: Audit → Review → Deny. Demonstrates governance maturity. | Takes 1–2 weeks longer than a Deny-first approach. |

### Policies Deployed

| Policy | Current Effect | Target Effect | Scope |
|--------|---------------|---------------|-------|
| Naming Convention (resource groups) | Audit | Deny | Subscription |
| Required Tag: Environment | Audit | Deny | Subscription |
| Required Tag: CostCenter | Audit | Deny | Subscription |
| Required Tag: Owner | Audit | Deny | Subscription |
| Required Tag: Project | Audit | Deny | Subscription |

---

## ADR-006: Monitoring Strategy — Centralized Log Analytics with Daily Cap

**Status:** Accepted  
**Date:** 2026-04-06  
**Decision Maker:** Ricardo Garcia

### Context

Azure Monitor and Log Analytics provide centralized logging and monitoring. The key design decisions are:

- **Centralized vs. Decentralized workspaces** — one workspace for all environments vs. one per environment.
- **Data retention** — how long to keep logs (30 days free, then $0.10/GB/month per extra day).
- **Daily ingestion cap** — whether to cap daily log volume to control costs.

### Decision

**Use a single centralized Log Analytics workspace (per environment) with 30-day retention and a 1 GB/day ingestion cap for Dev.**

### Consequences

| Aspect | Positive | Negative |
|--------|----------|----------|
| Centralization | Single pane of glass for all resources in the environment. Easier to write cross-resource queries. | Cross-environment queries require workspace-level permissions (acceptable for a single-person tenant). |
| Cost Control | 1 GB/day cap prevents runaway logging costs. First 5 GB/month is free for 31 days. | If the cap is hit, logs are dropped for the rest of the day (acceptable for dev, NOT for prod). |
| Retention | 30 days is free and sufficient for development troubleshooting. | Prod should increase to 90+ days for compliance. Adjust in prod parameter file. |

### Notes

For production, remove the daily cap and increase retention to 90 days. Consider adding Azure Sentinel (now Microsoft Sentinel) for security monitoring in enterprise deployments.

---

## ADR-007: Soft Delete & Purge Protection — Environment-Differentiated

**Status:** Accepted  
**Date:** 2026-04-06  
**Decision Maker:** Ricardo Garcia

### Context

Azure Key Vault supports soft delete (recoverable deletion) and purge protection (prevents permanent deletion during retention period). These features protect against accidental or malicious data loss.

### Decision

**Enable soft delete in all environments. Set retention to 7 days (minimum) for Dev and 90 days for Prod. Enable purge protection only in Prod.**

### Consequences

| Setting | Dev | QA | Prod | Rationale |
|---------|-----|----|----|-----------|
| Soft Delete | Enabled | Enabled | Enabled | Microsoft requires soft delete on all vaults since 2/2025. |
| Retention Days | 7 | 30 | 90 | Dev needs fast cleanup; Prod needs long recovery window. |
| Purge Protection | Disabled | Disabled | Enabled | Dev/QA vaults need to be fully deletable for teardown scripts. Prod vaults must survive even admin mistakes. |

### Notes

With purge protection disabled in Dev, the teardown script can fully remove Key Vaults. With purge protection enabled in Prod, a deleted vault enters a recoverable state for 90 days and cannot be permanently purged — even by a subscription Owner.
