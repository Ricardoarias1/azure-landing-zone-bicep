// --------------------------------------------
// Module: Virtual Network
// Purpose: Create a virtual network with configurable subnets
// --------------------------------------------

metadata description = 'Creates an Azure Virtual Network with configurable subnets. '

// -- Parameters ----------------------------------------------
@description('Name of the virtual network')
param vnetName string

@description('Azure region for the VNet')
param location string

@description('Address space for the VNet (e.g., 10.0.0.0/16)')
param addressPrefix string
 
@description('Array of subnet configurations')
param subnets subnetType[]
 
@description('Tags to apply to all resources')
param tags object
 
// ── User-Defined Types ──────────────────────────────
@description('Subnet configuration type')
type subnetType = {
  @description('Name of the subnet')
  name: string
  @description('Address prefix (e.g., 10.0.1.0/24)')
  addressPrefix: string
  @description('Optional NSG resource ID to associate')
  nsgId: string?
  @description('Optional: Enable private endpoint network policies')
  privateEndpointNetworkPolicies: ('Disabled' | 'Enabled')?
}
 
// ── Resources ───────────────────────────────────────
resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [addressPrefix]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: subnet.?nsgId != null ? {
          id: subnet.?nsgId
        } : null
        privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies  ?? 'Disabled'
      }
    }]
  }
}

// ── Outputs ───────────────────────────────────────
@description('Resource ID of the created VNet')
output vnetId string = vnet.id
 
@description('Name of the created VNet')
output vnetName string = vnet.name
 
@description('Array of subnet resource IDs')
output subnetIds array = [for (subnet, i) in subnets: vnet.properties.subnets[i].id]

