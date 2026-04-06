# ── Azure Landing Zone Deployment Script ──────────────
param(
  [Parameter(Mandatory)]
  [ValidateSet('dev','qa','prod')]
  [string]$Environment,
 
  [switch]$WhatIf
)
 
$templateFile  = "environments/$Environment/main.bicep"
$paramFile     = "environments/$Environment/main.bicepparam"
$deployName    = "landing-zone-$Environment-$(Get-Date -Format 'yyyyMMdd-HHmm')"
 
Write-Host "\n🚀 Deploying Landing Zone: $Environment" -ForegroundColor Cyan
Write-Host "   Template:   $templateFile"
Write-Host "   Parameters: $paramFile"
Write-Host "   Deployment: $deployName\n"
 
if ($WhatIf) {
  Write-Host "🔍 Running What-If preview..." -ForegroundColor Yellow
  az deployment sub what-if `
    --location eastus `
    --template-file $templateFile `
    --parameters $paramFile
} else {
  Write-Host "⚡ Deploying..." -ForegroundColor Green
  az deployment sub create `
    --location eastus `
    --template-file $templateFile `
    --parameters $paramFile `
    --name $deployName
}
