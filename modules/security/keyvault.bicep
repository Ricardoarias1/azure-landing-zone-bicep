metadata description = 'Creates an Azure Key Vault with RBAC authorization'
 
@description('Name of the Key Vault (3–24 chars, alphanumeric + hyphens)')
@minLength(3)
@maxLength(24)
param kvName string
 
@description('Azure region')
param location string
 
@description('Tags')
param tags object
 
@description('Enable soft delete (recommended: true for prod, true for dev too)')
param enableSoftDelete bool = true
 
@description('Soft delete retention in days (7–90)')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 7  // 7 for dev (min), 90 for prod
 
@description('Enable purge protection (true for prod, false for dev to allow cleanup)')
param enablePurgeProtection bool = false
 
@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string = ''
 
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'             // Standard tier is sufficient and cheapest
    }
    enableRbacAuthorization: true   // RBAC over access policies (best practice)
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    ...(enablePurgeProtection ? { enablePurgeProtection: true } : {})
    networkAcls: {
      defaultAction: 'Allow'       // Restrict to 'Deny' + VNet rules in prod
      bypass: 'AzureServices'
    }
  }
}

// Diagnostic settings (only if Log Analytics workspace is provided)
resource kvDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${kvName}-diagnostics'
  scope: kv
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { categoryGroup: 'allLogs', enabled: true, retentionPolicy: { enabled: false, days: 0 } }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true, retentionPolicy: { enabled: false, days: 0 } }
    ]
  }
}
 
output kvId string = kv.id
output kvName string = kv.name
output kvUri string = kv.properties.vaultUri

