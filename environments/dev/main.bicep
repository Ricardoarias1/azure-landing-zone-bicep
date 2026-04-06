// ══════════════════════════════════════════════════════
// Azure Landing Zone — DEV Environment Orchestrator
// ══════════════════════════════════════════════════════

targetScope = 'subscription'       // Deploy at subscription level for RGs + policies

// ── Parameters ──────────────────────────────────────
@description('Target Azure region')
param location string
 
@description('Environment identifier')
@allowed(['dev', 'qa', 'prod'])
param env string
 
@description('Short region code for naming')
param regionCode string
 
@description('Workload identifier')
param workload string
 
@description('Cost center tag value')
param costCenter string
 
@description('Owner email for tagging')
param ownerEmail string

@description('Monthly budget cap in USD')
param monthlyBudget int = 12
 
// ── Variables — Naming Convention ────────────────────
var prefix = '${env}-${regionCode}-${workload}'
 
// Resource Group names
var rgNetworkName    = 'rg-${prefix}-network-001'
var rgSecurityName   = 'rg-${prefix}-security-001'
var rgMonitorName    = 'rg-${prefix}-monitor-001'
var rgSharedName     = 'rg-${prefix}-shared-001'
 
// Resource names
var hubVnetName      = 'vnet-${prefix}-hub-001'
var spokeVnetName    = 'vnet-${prefix}-spoke-001'
var nsgWebName       = 'nsg-${prefix}-web-001'
var nsgAppName       = 'nsg-${prefix}-app-001'
var nsgDataName      = 'nsg-${prefix}-data-001'
var kvName           = 'kv-${env}-${regionCode}-lz-001'     // Short for Key Vault 24-char limit
var logName          = 'log-${prefix}-central-001'
var stDiagName       = 'st${env}${regionCode}diag001'       // No hyphens, max 24 chars
 
// Tags
var commonTags = {
  Environment: env
  CostCenter: costCenter
  Owner: ownerEmail
  Project: workload
  ManagedBy: 'Bicep'
}
 
// ── Resource Groups ─────────────────────────────────
resource rgNetwork 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgNetworkName
  location: location
  tags: commonTags
}
 
resource rgSecurity 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgSecurityName
  location: location
  tags: commonTags
}
 
resource rgMonitor 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgMonitorName
  location: location
  tags: commonTags
}
 
resource rgShared 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgSharedName
  location: location
  tags: commonTags
}
 
// ── Monitoring (deploy first — other modules depend on Log Analytics) ───
module logAnalytics '../../modules/monitoring/loganalytics.bicep' = {
  name: 'deploy-loganalytics'
  scope: rgMonitor
  params: {
    workspaceName: logName
    location: location
    tags: commonTags
    sku: 'PerGB2018'
    retentionInDays: 30        // Free tier retention
    dailyQuotaGb: 1            // 1 GB/day cap for dev
  }
}

// ── Storage (diagnostics) ────────────────────────────
module diagStorage '../../modules/storage/storageaccount.bicep' = {
  name: 'deploy-diag-storage'
  scope: rgMonitor
  params: {
    storageAccountName: stDiagName
    location: location
    tags: commonTags
    skuName: 'Standard_LRS'    // LRS is sufficient for dev diagnostics
  }
}

// ── NSGs (deploy before VNets so we can associate them) ───
module nsgWeb '../../modules/networking/nsg.bicep' = {
  name: 'deploy-nsg-web'
  scope: rgNetwork
  params: {
    nsgName: nsgWebName
    location: location
    tags: commonTags
    securityRules: [
      {
        name: 'AllowHTTPS'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: '*'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '443'
        description: 'Allow inbound HTTPS traffic'
      }
      {
        name: 'AllowBastionInbound'
        priority: 110
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: '10.0.0.0/24'     // Bastion subnet CIDR
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '22'
        description: 'Allow SSH from Bastion subnet'
      }
      {
        name: 'DenyAllInbound'
        priority: 4096
        direction: 'Inbound'
        access: 'Deny'
        protocol: '*'
        sourceAddressPrefix: '*'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '*'
        description: 'Deny all other inbound traffic'
      }
    ]
  }
}
 
module nsgApp '../../modules/networking/nsg.bicep' = {
  name: 'deploy-nsg-app'
  scope: rgNetwork
  params: {
    nsgName: nsgAppName
    location: location
    tags: commonTags
    securityRules: [
      {
        name: 'AllowFromWebTier'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: '10.1.1.0/24'     // Web subnet CIDR
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '8080'
        description: 'Allow traffic from web tier on port 8080'
      }
      {
        name: 'DenyAllInbound'
        priority: 4096
        direction: 'Inbound'
        access: 'Deny'
        protocol: '*'
        sourceAddressPrefix: '*'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '*'
        description: 'Deny all other inbound traffic'
      }
    ]
  }
}
 
module nsgData '../../modules/networking/nsg.bicep' = {
  name: 'deploy-nsg-data'
  scope: rgNetwork
  params: {
    nsgName: nsgDataName
    location: location
    tags: commonTags
    securityRules: [
      {
        name: 'AllowFromAppTier'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: '10.1.2.0/24'     // App subnet CIDR
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '1433'
        description: 'Allow SQL traffic from app tier'
      }
      {
        name: 'DenyAllInbound'
        priority: 4096
        direction: 'Inbound'
        access: 'Deny'
        protocol: '*'
        sourceAddressPrefix: '*'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '*'
        description: 'Deny all other inbound traffic'
      }
    ]
  }
}
 
// ── Hub Virtual Network ─────────────────────────────
module hubVnet '../../modules/networking/vnet.bicep' = {
  name: 'deploy-hub-vnet'
  scope: rgNetwork
  params: {
    vnetName: hubVnetName
    location: location
    tags: commonTags
    addressPrefix: '10.0.0.0/16'
    subnets: [
      {
        name: 'AzureBastionSubnet'              // Fixed name required by Azure
        addressPrefix: '10.0.0.0/24'
      }
      {
        name: 'snet-${prefix}-shared-001'
        addressPrefix: '10.0.1.0/24'
      }
      {
        name: 'snet-${prefix}-gateway-001'
        addressPrefix: '10.0.2.0/24'
      }
    ]
  }
}
 
// ── Spoke Virtual Network ────────────────────────────
module spokeVnet '../../modules/networking/vnet.bicep' = {
  name: 'deploy-spoke-vnet'
  scope: rgNetwork
  params: {
    vnetName: spokeVnetName
    location: location
    tags: commonTags
    addressPrefix: '10.1.0.0/16'
    subnets: [
      {
        name: 'snet-${prefix}-web-001'
        addressPrefix: '10.1.1.0/24'
        nsgId: nsgWeb.outputs.nsgId
      }
      {
        name: 'snet-${prefix}-app-001'
        addressPrefix: '10.1.2.0/24'
        nsgId: nsgApp.outputs.nsgId
      }
      {
        name: 'snet-${prefix}-data-001'
        addressPrefix: '10.1.3.0/24'
        nsgId: nsgData.outputs.nsgId
      }
    ]
  }
}
 
// ── VNet Peering ────────────────────────────────────
module peering '../../modules/networking/peering.bicep' = {
  name: 'deploy-peering'
  scope: rgNetwork
  params: {
    hubVnetName: hubVnet.outputs.vnetName
    spokeVnetName: spokeVnet.outputs.vnetName
    hubVnetId: hubVnet.outputs.vnetId
    spokeVnetId: spokeVnet.outputs.vnetId
  }
}
 
// ── Key Vault ────────────────────────────────────────
module keyVault '../../modules/security/keyvault.bicep' = {
  name: 'deploy-keyvault'
  scope: rgSecurity
  params: {
    kvName: kvName
    location: location
    tags: commonTags
    enableSoftDelete: true
    softDeleteRetentionInDays: 7       // Minimum for dev (easy cleanup)
    enablePurgeProtection: false        // Allow full cleanup in dev
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}
 
// ── Governance Policies (subscription-level) ─────────
module namingPolicy '../../modules/governance/policy-naming.bicep' = {
  name: 'deploy-naming-policy'
  params: {
    envCode: env
    regionCode: regionCode
  }
}
 
module taggingPolicy '../../modules/governance/policy-tagging.bicep' = {
  name: 'deploy-tagging-policy'
  params: {
    requiredTags: [
      'Environment'
      'CostCenter'
      'Owner'
      'Project'
    ]
  }
}
 
// ── Budget ───────────────────────────────────────────
module budget '../../modules/governance/budget.bicep' = {
  name: 'deploy-budget'
  params: {
    budgetName: 'budget-${prefix}-monthly'
    amount: monthlyBudget
    startDate: '2026-04-01'
    endDate: '2027-04-01'
    contactEmails: [ownerEmail]
    alertThreshold: 80           // Email at 80% actual spend
    alertThresholdForecast: 100  // Email when forecasted to hit 100%
  }
}

// ── Outputs ──────────────────────────────────────────
output hubVnetId string = hubVnet.outputs.vnetId
output spokeVnetId string = spokeVnet.outputs.vnetId
output keyVaultUri string = keyVault.outputs.kvUri
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId
