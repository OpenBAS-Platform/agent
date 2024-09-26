if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") { $architecture = "x86_64" }
if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { $architecture = "arm64" }
if ([string]::IsNullOrEmpty($architecture)) { throw "Architecture $env:PROCESSOR_ARCHITECTURE is not supported yet, please create a ticket in openbas github project" }
if ((Get-Host).Version.Major -lt 7) { throw "PowerShell 7 or higher is required for installation" }
Stop-Service -Force -Name "OBAS Agent Service"; Invoke-WebRequest -Uri "${OPENBAS_URL}/api/agent/package/openbas/windows/${architecture}" -OutFile "openbas-installer.exe"; ./openbas-installer.exe /S ~OPENBAS_URL="${OPENBAS_URL}" ~ACCESS_TOKEN="${OPENBAS_TOKEN}" ~UNSECURED_CERTIFICATE=${OPENBAS_UNSECURED_CERTIFICATE} ~WITH_PROXY=${OPENBAS_WITH_PROXY}; Start-Sleep -Seconds 1.5; rm -force ./openbas-installer.exe;
