metadata description = 'Azure Policy: Enforce naming convention via audit'
 
targetScope = 'subscription'
 
@description('Environment code to enforce (dev, qa, prod)')
param envCode string
 
@description('Region code to enforce (eus, eus2, cus)')
param regionCode string
 
// Policy Definition
resource namingPolicy 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'pol-naming-convention-${envCode}'
  properties: {
    displayName: 'Audit: Resource names must follow naming convention'
    description: 'Audits resources whose names do not follow the pattern: {type}-${envCode}-${regionCode}-{workload}-{instance}'
    policyType: 'Custom'
    mode: 'All'
    metadata: {
      category: 'Naming'
      version: '1.0.0'
    }
    parameters: {}
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Resources/subscriptions/resourceGroups'
          }
          {
            not: {
              field: 'name'
              match: 'rg-${envCode}-${regionCode}-??????-###'
            }
          }
        ]
      }
      then: {
        effect: 'Audit'   // Use 'Audit' first, switch to 'Deny' when confident
      }
    }
  }
}

// Policy Assignment
resource namingAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: 'pola-naming-${envCode}'
  properties: {
    displayName: 'Enforce naming convention (${envCode})'
    policyDefinitionId: namingPolicy.id
    enforcementMode: 'Default'
  }
}


