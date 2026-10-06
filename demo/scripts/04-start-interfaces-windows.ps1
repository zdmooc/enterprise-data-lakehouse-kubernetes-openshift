$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $Root

$Context = kubectl config current-context
if ($Context.Trim() -ne 'kind-edl-lab') { throw "Expected kind-edl-lab, got $Context" }

$Dir = Join-Path $Root '.audit\demo-port-forwards'
New-Item -ItemType Directory -Force -Path $Dir | Out-Null

$Specs = @(
  @{Name='argocd';      Ns='argocd';            Svc='argocd-server';             Local=18081; Remote=443},
  @{Name='kafka-ui';    Ns='edl-data';          Svc='edl-kafka-console';         Local=18082; Remote=8080},
  @{Name='spark-ui';    Ns='edl-data';          Svc='edl-spark-history';         Local=18083; Remote=18080},
  @{Name='grafana';     Ns='edl-observability'; Svc='edl-monitoring-grafana';    Local=13001; Remote=80},
  @{Name='prometheus';  Ns='edl-observability'; Svc='edl-monitoring-prometheus'; Local=19090; Remote=9090},
  @{Name='jupyter';     Ns='edl-data';          Svc='edl-jupyter';               Local=18888; Remote=8888},
  @{Name='trino';       Ns='edl-data';          Svc='edl-trino';                 Local=18080; Remote=8080},
  @{Name='polaris-api'; Ns='edl-data';          Svc='edl-polaris';               Local=18181; Remote=8181},
  @{Name='polaris-ui';  Ns='edl-data';          Svc='edl-polaris-console';       Local=18182; Remote=8080},
  @{Name='s3-api';      Ns='edl-data';          Svc='edl-s3';                    Local=19000; Remote=9000},
  @{Name='s3-ui';       Ns='edl-data';          Svc='edl-s3';                    Local=19001; Remote=9001}
)

foreach ($s in $Specs) {
  $pidFile = Join-Path $Dir ($s.Name + '.pid')
  $outFile = Join-Path $Dir ($s.Name + '.out.log')
  $errFile = Join-Path $Dir ($s.Name + '.err.log')
  if (Test-Path $pidFile) {
    $oldPid = [int](Get-Content $pidFile)
    if (Get-Process -Id $oldPid -ErrorAction SilentlyContinue) {
      Write-Host "[INFO] $($s.Name) already running pid=$oldPid"
      continue
    }
    Remove-Item $pidFile -Force
  }
  $args = @('--context=kind-edl-lab','-n',$s.Ns,'port-forward',('svc/' + $s.Svc),($s.Local.ToString() + ':' + $s.Remote.ToString()),'--address=127.0.0.1')
  $p = Start-Process -FilePath 'kubectl.exe' -ArgumentList $args -PassThru -WindowStyle Hidden -RedirectStandardOutput $outFile -RedirectStandardError $errFile
  Set-Content -Path $pidFile -Value $p.Id
  Start-Sleep -Seconds 1
  if ($p.HasExited) {
    Write-Host "[FAIL] $($s.Name) port-forward exited"
    if (Test-Path $errFile) { Get-Content $errFile }
    throw "Port-forward failed: $($s.Name)"
  }
  Write-Host "[PASS] $($s.Name) pid=$($p.Id)"
}

Write-Host ''
Write-Host '===== VISUAL DEMO URLS ====='
Write-Host 'Argo CD              https://127.0.0.1:18081'
Write-Host 'Kafka / Redpanda UI  http://127.0.0.1:18082'
Write-Host 'Spark History Server http://127.0.0.1:18083'
Write-Host 'Grafana              http://127.0.0.1:13001'
Write-Host 'Prometheus           http://127.0.0.1:19090'
Write-Host 'Jupyter              http://127.0.0.1:18888'
Write-Host 'Trino                 http://127.0.0.1:18080'
Write-Host 'Polaris Console       http://127.0.0.1:18182'
Write-Host 'Polaris API           http://127.0.0.1:18181'
Write-Host 'RustFS Console        http://127.0.0.1:19001'
Write-Host 'RustFS/S3 API         http://127.0.0.1:19000'
