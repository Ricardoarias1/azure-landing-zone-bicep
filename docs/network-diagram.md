# Network Architecture Diagram

> Hub-Spoke topology for the Azure Landing Zone. This diagram renders natively on GitHub using [Mermaid](https://mermaid.js.org/).

---

## High-Level Topology

```mermaid
graph TB
    subgraph INTERNET["☁️ Internet"]
        Users["Users / Clients"]
    end

    subgraph HUB["Hub VNet — 10.0.0.0/16"]
        direction TB
        BAS["AzureBastionSubnet<br/>10.0.0.0/24<br/>🔒 Secure remote access"]
        SHARED["snet-shared-services<br/>10.0.1.0/24<br/>DNS / Monitoring Agents"]
        GW["snet-gateway<br/>10.0.2.0/24<br/>🔗 Future VPN/ExpressRoute"]
    end

    subgraph SPOKE_DEV["Spoke-Dev VNet — 10.1.0.0/16"]
        direction TB
        WEB_DEV["snet-web (10.1.1.0/24)<br/>🌐 NSG: AllowHTTPS, AllowBastion"]
        APP_DEV["snet-app (10.1.2.0/24)<br/>⚙️ NSG: AllowFromWeb:8080"]
        DATA_DEV["snet-data (10.1.3.0/24)<br/>🗄️ NSG: AllowFromApp:1433"]
    end

    subgraph SPOKE_QA["Spoke-QA VNet — 10.2.0.0/16"]
        direction TB
        WEB_QA["snet-web (10.2.1.0/24)"]
        APP_QA["snet-app (10.2.2.0/24)"]
        DATA_QA["snet-data (10.2.3.0/24)"]
    end

    subgraph SPOKE_PROD["Spoke-Prod VNet — 10.3.0.0/16"]
        direction TB
        WEB_PROD["snet-web (10.3.1.0/24)"]
        APP_PROD["snet-app (10.3.2.0/24)"]
        DATA_PROD["snet-data (10.3.3.0/24)"]
    end

    Users -->|HTTPS 443| WEB_DEV
    Users -.->|Future| WEB_QA
    Users -.->|Future| WEB_PROD

    HUB <-->|"VNet Peering"| SPOKE_DEV
    HUB <-.->|"Future Peering"| SPOKE_QA
    HUB <-.->|"Future Peering"| SPOKE_PROD

    BAS -->|"SSH/RDP"| WEB_DEV
    BAS -->|"SSH/RDP"| APP_DEV

    WEB_DEV -->|":8080"| APP_DEV
    APP_DEV -->|":1433"| DATA_DEV

    WEB_QA --> APP_QA --> DATA_QA
    WEB_PROD --> APP_PROD --> DATA_PROD

    style HUB fill:#1B3A5C,stroke:#0D2137,color:#FFFFFF
    style SPOKE_DEV fill:#2E5090,stroke:#1B3A5C,color:#FFFFFF
    style SPOKE_QA fill:#4472C4,stroke:#2E5090,color:#FFFFFF
    style SPOKE_PROD fill:#6B9BD2,stroke:#4472C4,color:#1B3A5C
    style INTERNET fill:#F0F0F0,stroke:#CCCCCC,color:#333333
```

---

## Traffic Flow — Dev Environment

```mermaid
sequenceDiagram
    participant U as User / Client
    participant NSG_W as NSG-Web
    participant WEB as Web Tier<br/>(10.1.1.0/24)
    participant NSG_A as NSG-App
    participant APP as App Tier<br/>(10.1.2.0/24)
    participant NSG_D as NSG-Data
    participant DATA as Data Tier<br/>(10.1.3.0/24)
    participant BAS as Bastion<br/>(10.0.0.0/24)
    participant ADMIN as Admin / Developer

    Note over U,DATA: Normal Request Flow
    U->>NSG_W: HTTPS (port 443)
    NSG_W->>NSG_W: ✅ Rule 100: AllowHTTPS
    NSG_W->>WEB: Forward to web tier
    WEB->>NSG_A: Internal request (port 8080)
    NSG_A->>NSG_A: ✅ Rule 100: AllowFromWebTier
    NSG_A->>APP: Forward to app tier
    APP->>NSG_D: SQL query (port 1433)
    NSG_D->>NSG_D: ✅ Rule 100: AllowFromAppTier
    NSG_D->>DATA: Forward to data tier
    DATA-->>APP: Query results
    APP-->>WEB: API response
    WEB-->>U: HTTPS response

    Note over ADMIN,BAS: Admin Access Flow
    ADMIN->>BAS: Azure Portal → Bastion
    BAS->>NSG_W: SSH (port 22)
    NSG_W->>NSG_W: ✅ Rule 110: AllowBastionInbound
    NSG_W->>WEB: SSH session established

    Note over U,DATA: Blocked Traffic Example
    U->>NSG_A: Direct access to app tier (port 8080)
    NSG_A->>NSG_A: ❌ Rule 4096: DenyAllInbound
    NSG_A-->>U: Connection refused
```

---

## CIDR Allocation Table

| VNet / Subnet | CIDR Block | Usable IPs | Purpose | NSG |
|---------------|-----------|------------|---------|-----|
| **Hub VNet** | **10.0.0.0/16** | **65,531** | **Shared services** | — |
| └ AzureBastionSubnet | 10.0.0.0/24 | 251 | Bastion host (fixed name) | Azure-managed |
| └ snet-shared-services | 10.0.1.0/24 | 251 | DNS forwarders, monitoring | Minimal |
| └ snet-gateway | 10.0.2.0/24 | 251 | Future VPN/ExpressRoute | Minimal |
| **Spoke-Dev VNet** | **10.1.0.0/16** | **65,531** | **Dev workloads** | — |
| └ snet-web | 10.1.1.0/24 | 251 | Web tier (AKS, App Services) | nsg-web |
| └ snet-app | 10.1.2.0/24 | 251 | App tier (Functions, APIs) | nsg-app |
| └ snet-data | 10.1.3.0/24 | 251 | Data tier (SQL, Cosmos) | nsg-data |
| **Spoke-QA VNet** | **10.2.0.0/16** | **65,531** | **QA workloads** | — |
| └ snet-web | 10.2.1.0/24 | 251 | Web tier | nsg-web |
| └ snet-app | 10.2.2.0/24 | 251 | App tier | nsg-app |
| └ snet-data | 10.2.3.0/24 | 251 | Data tier | nsg-data |
| **Spoke-Prod VNet** | **10.3.0.0/16** | **65,531** | **Prod workloads** | — |
| └ snet-web | 10.3.1.0/24 | 251 | Web tier | nsg-web |
| └ snet-app | 10.3.2.0/24 | 251 | App tier | nsg-app |
| └ snet-data | 10.3.3.0/24 | 251 | Data tier | nsg-data |

**Total address space used:** 10.0.0.0/14 (covers 10.0.0.0 through 10.3.255.255)  
**Reserved for future spokes:** 10.4.0.0/16 through 10.255.0.0/16 (252 additional spokes possible)

---

## NSG Rules Summary

### nsg-web (Web Tier)

| Priority | Name | Direction | Access | Protocol | Source | Dest Port | Description |
|----------|------|-----------|--------|----------|--------|-----------|-------------|
| 100 | AllowHTTPS | Inbound | Allow | TCP | * | 443 | Internet HTTPS traffic |
| 110 | AllowBastionInbound | Inbound | Allow | TCP | 10.0.0.0/24 | 22, 3389 | SSH/RDP from Bastion only |
| 4096 | DenyAllInbound | Inbound | Deny | * | * | * | Deny everything else |

### nsg-app (App Tier)

| Priority | Name | Direction | Access | Protocol | Source | Dest Port | Description |
|----------|------|-----------|--------|----------|--------|-----------|-------------|
| 100 | AllowFromWebTier | Inbound | Allow | TCP | 10.1.1.0/24 | 8080 | API traffic from web tier |
| 4096 | DenyAllInbound | Inbound | Deny | * | * | * | Deny everything else |

### nsg-data (Data Tier)

| Priority | Name | Direction | Access | Protocol | Source | Dest Port | Description |
|----------|------|-----------|--------|----------|--------|-----------|-------------|
| 100 | AllowFromAppTier | Inbound | Allow | TCP | 10.1.2.0/24 | 1433 | SQL from app tier |
| 4096 | DenyAllInbound | Inbound | Deny | * | * | * | Deny everything else |

---

## Peering Relationships

```mermaid
graph LR
    HUB["Hub VNet<br/>10.0.0.0/16"]
    DEV["Spoke-Dev<br/>10.1.0.0/16"]
    QA["Spoke-QA<br/>10.2.0.0/16"]
    PROD["Spoke-Prod<br/>10.3.0.0/16"]

    HUB <-->|"peer-hub-to-dev<br/>AllowVNetAccess ✅<br/>AllowForwardedTraffic ✅<br/>GatewayTransit ❌"| DEV
    HUB <-.->|"Future"| QA
    HUB <-.->|"Future"| PROD

    DEV x--x QA
    DEV x--x PROD
    QA x--x PROD

    style HUB fill:#1B3A5C,color:#FFF
    style DEV fill:#2E5090,color:#FFF
    style QA fill:#4472C4,color:#FFF
    style PROD fill:#6B9BD2,color:#1B3A5C
```

**Key design point:** Spokes cannot communicate with each other directly. All inter-spoke traffic must route through the Hub. This provides centralized security inspection and prevents lateral movement between environments.

---

## Future Enhancements

| Enhancement | When | Cost Impact | Description |
|-------------|------|-------------|-------------|
| Azure Bastion Host | Project 2 (AKS) | ~$0.19/hr (use Basic SKU) | Deploy only when SSH access needed, delete after |
| Azure Firewall | Prod deployment | ~$1.25/hr (skip in dev) | Centralized egress filtering in hub |
| VPN Gateway | Client connectivity | ~$0.04/hr (VpnGw1) | Connect on-prem to hub |
| Private DNS Zones | Project 5 (RAG) | Free (< 25 zones) | Private endpoint DNS resolution |
| NSG Flow Logs | Phase 3 | ~$0.50/GB | Network traffic analytics |
| Azure DDoS Protection | Production only | ~$2,944/mo | Only for internet-facing production workloads |
