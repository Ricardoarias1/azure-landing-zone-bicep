param(
    [Parameter(Mandatory)]
    [ValidateSet('dev', 'qa', 'prod')]
    [string]$Environment,
 
    [string]$RegionCode = 'eus',
    [string]$Workload = 'landing'
)
 
$prefix = "$Environment-$RegionCode-$Workload"
$rgNames = @(
    "rg-$prefix-network-001",
    "rg-$prefix-security-001",
    "rg-$prefix-monitor-001",
    "rg-$prefix-shared-001"
)
 
Write-Host "\n⚠️  WARNING: This will delete ALL resources in:" -ForegroundColor Red
$rgNames | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
 
$confirm = Read-Host "\nType 'DELETE' to confirm"
if ($confirm -ne 'DELETE') {
    Write-Host "Cancelled." -ForegroundColor Gray
    return
}
 
foreach ($rg in $rgNames) {
    Write-Host "Deleting $rg..." -ForegroundColor Red
    az group delete --name $rg --yes --no-wait
}
 
Write-Host "`n✅ Deletion initiated (running in background)." -ForegroundColor Green
Write-Host "Check progress: az group list --query ""[?starts_with(name, 'rg-$prefix')]. { Name:name, State:properties.provisioningState }"""
