$isElevatedPowershell = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isElevatedPowershell -like "False") { throw "PowerShell 'Run as Administrator' is required for installation" }
# Can't install the OpenBAS agent in System32 location because NSIS 64 exe
$location = Get-Location
if ($location -like "*C:\Windows\System32*") { cd C:\ }
switch ($env:PROCESSOR_ARCHITECTURE)
{
    "AMD64" {$architecture = "x86_64"; Break}
	"ARM64" {$architecture = "arm64"; Break}
	"x86" {
		switch ($env:PROCESSOR_ARCHITEW6432)
		{
			"AMD64" {$architecture = "x86_64"; Break}
			"ARM64" {$architecture = "arm64"; Break}
		}
	}
}
if ([string]::IsNullOrEmpty($architecture)) { throw "Architecture $env:PROCESSOR_ARCHITECTURE is not supported yet, please create a ticket in openbas github project" }

echo "Downloading and installing OpenBAS Agent..."
try {
    Invoke-WebRequest -Uri "${OPENBAS_URL}/api/agent/package/openbas/windows/${architecture}/service" -OutFile "openbas-installer.exe";
    ./openbas-installer.exe /S ~OPENBAS_URL="${OPENBAS_URL}" ~ACCESS_TOKEN="${OPENBAS_TOKEN}" ~UNSECURED_CERTIFICATE=${OPENBAS_UNSECURED_CERTIFICATE} ~WITH_PROXY=${OPENBAS_WITH_PROXY} ~SERVICE_NAME=${OPENBAS_SERVICE_NAME} ~INSTALL_DIR='"${OPENBAS_INSTALL_DIR}"';
    Start-Sleep -Seconds 5;
    rm -force ./openbas-installer.exe;
	echo "OpenBAS agent has been successfully installed"
} catch {
    echo "Installation failed"
  	if ((Get-Host).Version.Major -lt 7) { throw "PowerShell 7 or higher is required for installation" }
  	else { echo $_ }
} finally {
  	if ($location -like "*C:\Windows\System32*") { cd C:\Windows\System32 }
}
