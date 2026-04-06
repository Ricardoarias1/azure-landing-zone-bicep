metadata description = 'Creates bidirectional VNet peering'
 
@description('Name of the hub VNet (must exist in same sub)')
param hubVnetName string
 
@description('Name of the spoke VNet')
param spokeVnetName string
 
@description('Resource ID of the hub VNet')
param hubVnetId string
 
@description('Resource ID of the spoke VNet')
param spokeVnetId string

// Hub → Spoke peering
resource hubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = {
  name: '${hubVnetName}/peer-${hubVnetName}-to-${spokeVnetName}'
  properties: {
    remoteVirtualNetwork: { id: spokeVnetId }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false       // Set true if hub has VPN Gateway
    useRemoteGateways: false
  }
}
 
// Spoke → Hub peering
resource spokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = {
  name: '${spokeVnetName}/peer-${spokeVnetName}-to-${hubVnetName}'
  properties: {
    remoteVirtualNetwork: { id: hubVnetId }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false         // Set true if using hub VPN Gateway
  }
}
