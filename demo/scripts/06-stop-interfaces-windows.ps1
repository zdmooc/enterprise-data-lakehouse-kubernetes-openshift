$ErrorActionPreference = 'Continue'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $Root
$Dir = Join-Path $Root '.audit\demo-port-forwards'
if (-not (Test-Path $Dir)) { Write-Host '[INFO] no demo port-forward directory'; exit 0 }

Get-ChildItem -Path $Dir -Filter '*.pid' | ForEach-Object {
  $name = $_.BaseName
  $pidValue = [int](Get-Content $_.FullName)
  $proc = Get-Process -Id $pidValue -ErrorAction SilentlyContinue
  if ($proc) {
    Stop-Process -Id $pidValue -Force -ErrorAction SilentlyContinue
    Write-Host "[PASS] stopped $name pid=$pidValue"
  } else {
    Write-Host "[INFO] $name pid=$pidValue already stopped"
  }
  Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
}
Write-Host '[PASS] demo port-forwards stopped'
