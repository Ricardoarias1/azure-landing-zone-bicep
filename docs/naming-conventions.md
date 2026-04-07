# Naming Conventions

> Standard naming conventions for all Azure resources in this Landing Zone. Based on the [Microsoft Cloud Adoption Framework naming rules](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming).

---

## Master Pattern

```
{resourceType}-{environment}-{region}-{workload}-{instance}
```

### Token Definitions

| Token | Description | Values | Example |
|-------|-------------|--------|---------|
| `resourceType` | CAF abbreviation for the Azure resource type | See table below | `rg`, `vnet`, `kv` |
| `environment` | Deployment environment | `dev`, `qa`, `prod` | `dev` |
| `region` | Azure region short code | `eus`, `eus2`, `cus` | `eus` |
| `workload` | Logical workload or project name | Free-form, lowercase | `landing`, `expense` |
| `instance` | Numeric instance identifier (zero-padded) | `001`–`999` | `001` |

### Special Cases

| Resource Type | Rule | Example | Reason |
|--------------|------|---------|--------|
| Storage Account | No hyphens, lowercase only, max 24 chars | `stdeveuslanding001` → too long → `stdeveusdiag001` | Azure enforces `^[a-z0-9]{3,24}$` |
| Key Vault | Max 24 chars, must start with letter | `kv-dev-eus-lz-001` | Abbreviate workload to stay under 24 |
| AzureBastionSubnet | Fixed name, cannot be customized | `AzureBastionSubnet` | Azure Bastion requires this exact name |
| GatewaySubnet | Fixed name for VPN/ER gateways | `GatewaySubnet` | Azure VPN Gateway requires this exact name |

---

## Resource Type Abbreviations

| Resource | Abbreviation | Max Length | Allowed Characters |
|----------|-------------|------------|-------------------|
| Resource Group | `rg` | 90 | Alphanumeric, hyphens, underscores, periods |
| Virtual Network | `vnet` | 64 | Alphanumeric, hyphens, underscores, periods |
| Subnet | `snet` | 80 | Alphanumeric, hyphens, underscores, periods |
| Network Security Group | `nsg` | 80 | Alphanumeric, hyphens, underscores, periods |
| VNet Peering | `peer` | 80 | Alphanumeric, hyphens, underscores, periods |
| Public IP Address | `pip` | 80 | Alphanumeric, hyphens, underscores, periods |
| Azure Bastion | `bas` | 80 | Alphanumeric, hyphens, underscores, periods |
| Key Vault | `kv` | 24 | Alphanumeric, hyphens. Must start with letter. |
| Log Analytics Workspace | `log` | 63 | Alphanumeric, hyphens |
| Storage Account | `st` | 24 | Lowercase alphanumeric ONLY |
| Azure Policy Definition | `pol` | 128 | Alphanumeric, hyphens |
| Azure Policy Assignment | `pola` | 128 | Alphanumeric, hyphens |
| Application Insights | `appi` | 260 | Alphanumeric, hyphens, underscores, periods |
| Azure Kubernetes Service | `aks` | 63 | Alphanumeric, hyphens |
| Container Registry | `cr` | 50 | Alphanumeric ONLY |
| Azure SQL Server | `sql` | 63 | Lowercase alphanumeric, hyphens |
| Azure SQL Database | `sqldb` | 128 | Alphanumeric, hyphens, underscores, periods |
| Cosmos DB Account | `cosmos` | 44 | Lowercase alphanumeric, hyphens |
| Service Bus Namespace | `sb` | 50 | Alphanumeric, hyphens |
| Event Hub Namespace | `evh` | 50 | Alphanumeric, hyphens |
| Azure Function App | `func` | 60 | Alphanumeric, hyphens |
| App Service | `app` | 60 | Alphanumeric, hyphens |
| Logic App | `la` | 80 | Alphanumeric, hyphens |
| API Management | `apim` | 50 | Alphanumeric, hyphens. Must start with letter. |
| Azure Data Factory | `adf` | 63 | Alphanumeric, hyphens |
| Databricks Workspace | `dbw` | 64 | Alphanumeric, hyphens, underscores |

---

## Environment Codes

| Full Name | Code | Usage |
|-----------|------|-------|
| Development | `dev` | Feature development, personal testing |
| Quality Assurance | `qa` | Integration testing, UAT, pre-production validation |
| Production | `prod` | Live workloads, customer-facing services |
| Shared | `shared` | Resources used across environments (hub VNet, DNS) |

---

## Region Codes

| Azure Region | Code | Notes |
|-------------|------|-------|
| East US | `eus` | Primary region (lowest cost for US East) |
| East US 2 | `eus2` | DR/secondary region |
| Central US | `cus` | Alternative if capacity issues in East US |
| West US 2 | `wus2` | West coast workloads |
| West Europe | `weu` | European workloads |
| North Europe | `neu` | European DR |

---

## Concrete Examples

### This Landing Zone (Dev)

```
Resource Groups:
  rg-dev-eus-landing-network-001
  rg-dev-eus-landing-security-001
  rg-dev-eus-landing-monitor-001
  rg-dev-eus-landing-shared-001

Networking:
  vnet-dev-eus-landing-hub-001
  vnet-dev-eus-landing-spoke-001
  snet-dev-eus-landing-web-001
  snet-dev-eus-landing-app-001
  snet-dev-eus-landing-data-001
  nsg-dev-eus-landing-web-001
  nsg-dev-eus-landing-app-001
  nsg-dev-eus-landing-data-001
  peer-vnet-dev-eus-landing-hub-001-to-vnet-dev-eus-landing-spoke-001

Security:
  kv-dev-eus-lz-001

Monitoring:
  log-dev-eus-landing-central-001
  stdeveusdiag001
```

### Future Projects (Examples)

```
Project 2 — Microservices:
  aks-dev-eus-expense-001
  crdeveusexpense001        (Container Registry, no hyphens)
  cosmos-dev-eus-expense-001
  sb-dev-eus-expense-001

Project 4 — Data Platform:
  adf-dev-eus-medallion-001
  dbw-dev-eus-medallion-001
  stdeveusmedallion001      (ADLS Gen2)

Project 5 — RAG Application:
  appi-dev-eus-rag-001
  func-dev-eus-rag-001
```

---

## Bicep Implementation

In the orchestrator (`main.bicep`), names are derived from a common prefix:

```bicep
var prefix = '${env}-${regionCode}-${workload}'

var rgNetworkName  = 'rg-${prefix}-network-001'
var hubVnetName    = 'vnet-${prefix}-hub-001'
var nsgWebName     = 'nsg-${prefix}-web-001'
var kvName         = 'kv-${env}-${regionCode}-lz-001'     // Shortened for 24-char limit
var stDiagName     = 'st${env}${regionCode}diag001'        // No hyphens
```

**Rule:** Never hardcode resource names inside modules. Always pass them as parameters from the orchestrator. This ensures the naming convention is centralized in exactly one place.

---

## Tagging Strategy

Every resource group and every resource must carry these tags:

| Tag Key | Required? | Example Value | Purpose |
|---------|-----------|---------------|---------|
| `Environment` | **Yes** (policy-enforced) | `dev` | Environment identification |
| `CostCenter` | **Yes** (policy-enforced) | `IT-RGarcia` | Finance cost allocation |
| `Owner` | **Yes** (policy-enforced) | `ricardo@domain.com` | Accountability |
| `Project` | **Yes** (policy-enforced) | `landing` | Workload mapping |
| `ManagedBy` | Recommended | `Bicep` | Identifies IaC-managed resources (prevents manual drift) |
| `CreatedDate` | Recommended | `2026-04-06` | Resource age tracking |
| `ExpirationDate` | Optional | `2026-06-30` | For temporary dev/test resources |

---

## Enforcement

These conventions are enforced through:

1. **Azure Policy** — `policy-naming.bicep` audits resource group names. `policy-tagging.bicep` requires all four mandatory tags.
2. **Bicep Linter** — `bicepconfig.json` prevents hardcoded locations and environment URLs.
3. **Code Review** — PR reviews verify naming before merge (Project 3 pipeline adds automated checks).
4. **This Document** — serves as the authoritative reference for the team.
