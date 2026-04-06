metadata description = 'Creates an NSG with configurable security rules'

@description('Name of the NSG')
param nsgName string

@description('Azure region')
param location string
 
@description('Security rules to apply')
param securityRules securityRuleType[]

@description('Tags to apply')
param tags object
 
type securityRuleType = {
  name: string
  priority: int
  direction: ('Inbound' | 'Outbound')
  access: ('Allow' | 'Deny')
  protocol: ('Tcp' | 'Udp' | '*')
  sourceAddressPrefix: string
  sourcePortRange: string
  destinationAddressPrefix: string
  destinationPortRange: string
  description: string?
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [for rule in securityRules: {
      name: rule.name
      properties: {
        priority: rule.priority
        direction: rule.direction
        access: rule.access
        protocol: rule.protocol
        sourceAddressPrefix: rule.sourceAddressPrefix
        sourcePortRange: rule.sourcePortRange
        destinationAddressPrefix: rule.destinationAddressPrefix
        destinationPortRange: rule.destinationPortRange
        description: rule.?description  ?? ''
      }
    }]
  }
}

output nsgId string = nsg.id
output nsgName string = nsg.name


