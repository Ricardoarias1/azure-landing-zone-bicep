metadata description = 'Creates a Log Analytics Workspace'
 
@description('Name of the workspace')
param workspaceName string
 
@description('Azure region')
param location string
 
@description('Tags')
param tags object
 
@description('SKU: PerGB2018 is pay-as-you-go (first 5 GB/day free for 31 days)')
@allowed(['PerGB2018', 'Free'])
param sku string = 'PerGB2018'
 
@description('Data retention in days (31 free, then $0.10/GB/month per extra day)')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30     // 30 days is free; increase for prod
 
@description('Daily ingestion cap in GB (-1 = no cap)')
param dailyQuotaGb int = 1         // 1 GB/day cap to control costs in dev
 
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: { name: sku }
    retentionInDays: retentionInDays
    workspaceCapping: dailyQuotaGb > 0 ? {
      dailyQuotaGb: dailyQuotaGb
    } : null
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

output workspaceId string = law.id
output workspaceName string = law.name
output customerId string = law.properties.customerId  // Needed for agents
