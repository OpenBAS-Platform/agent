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
function Sanitize-UserName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    $UserName = $UserName.ToLower()
    $pattern = '[\/\\:\*\?<>\|]'
    return ($UserName -replace $pattern, '')
}
$BasePath = "C:\Filigran\";
$User = whoami;
$SanitizedUser =  Sanitize-UserName -UserName $user;
$isElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isElevated) {
    $AgentName = "OBASAgent-Session-Administrator-$SanitizedUser"
} else {
    $AgentName = "OBASAgent-Session-$SanitizedUser"
}
$InstallDir = $BasePath + $AgentName;
$AgentPath = $InstallDir + "\openbas-agent.exe";

Get-Process | Where-Object { $_.Path -eq "$AgentPath" } | Stop-Process -Force;
Invoke-WebRequest -Uri "${OPENBAS_URL}/api/agent/package/openbas/windows/${architecture}/session-user" -OutFile "openbas-installer-session-user.exe";
./agent-installer-session-user.exe /S ~OPENBAS_URL="${OPENBAS_URL}" ~ACCESS_TOKEN="${OPENBAS_TOKEN}" ~UNSECURED_CERTIFICATE=${OPENBAS_UNSECURED_CERTIFICATE} ~WITH_PROXY=${OPENBAS_WITH_PROXY};

Start-Sleep -Seconds 5;
rm -force ./agent-installer-session-user.exe;