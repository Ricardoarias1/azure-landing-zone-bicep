metadata description = 'Creates an Azure Storage Account'
 
@description('Storage account name (3–24 chars, lowercase alphanumeric only)')
@minLength(3)
@maxLength(24)
param storageAccountName string
 
@description('Azure region')
param location string
 
@description('Tags')
param tags object
 
@description('SKU: Standard_LRS for dev, Standard_GRS for prod')
@allowed(['Standard_LRS', 'Standard_GRS', 'Standard_ZRS'])
param skuName string = 'Standard_LRS'
 
@description('Kind of storage account')
param kind string = 'StorageV2'
 
@description('Enable blob versioning')
param enableBlobVersioning bool = false
 
resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: { name: skuName }
  kind: kind
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true     // Always enforce HTTPS
    minimumTlsVersion: 'TLS1_2'       // TLS 1.2 minimum
    allowBlobPublicAccess: false       // Never allow public blob access
    networkAcls: {
      defaultAction: 'Allow'           // Restrict in prod
      bypass: 'AzureServices'
    }
  }
}

// Enable blob versioning if requested
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = if (enableBlobVersioning) {
  parent: sa
  name: 'default'
  properties: {
    isVersioningEnabled: true
  }
}
 
output storageId string = sa.id
output storageName string = sa.name
