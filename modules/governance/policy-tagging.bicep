metadata description = 'Azure Policy: Require tags on resource groups'
 
targetScope = 'subscription'
 
@description('List of tag names that are required on resource groups')
param requiredTags array = [
  'Environment'
  'CostCenter'
  'Owner'
  'Project'
]
 
// Create one policy assignment per required tag
// Uses the built-in policy: 'Require a tag on resource groups'
resource tagPolicies 'Microsoft.Authorization/policyAssignments@2023-04-01' = [for tag in requiredTags: {
  name: 'pola-require-tag-${toLower(tag)}'
  properties: {
    displayName: 'Require tag: ${tag} on resource groups'
    // Built-in policy ID for "Require a tag on resource groups"
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'
    parameters: {
      tagName: { value: tag }
    }
    enforcementMode: 'Default'
  }
}]
