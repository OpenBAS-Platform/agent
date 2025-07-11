[Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12;
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

function Sanitize-UserName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    $UserName = $UserName.ToLower()
    $pattern = '[\/\\:\*\?<>\|]'
    return ($UserName -replace $pattern, '')
}

if ([string]::IsNullOrEmpty($architecture)) { throw "Architecture $env:PROCESSOR_ARCHITECTURE is not supported yet, please create a ticket in openbas github project" }

$BasePath = "C:\Filigran\";
$User = whoami;
$SanitizedUser =  Sanitize-UserName -UserName $user;
$AgentName = "OBASAgent-Service-$SanitizedUser";
$InstallDir = $BasePath + $AgentName;
$AgentPath = $InstallDir + "\openbas-agent.exe";
$AgentUpgradedPath = $InstallDir + "\openbas-agent_upgrade.exe";

#Download the agent exe
Invoke-WebRequest -Uri "${OPENBAS_URL}/api/agent/executable/openbas/windows/${architecture}" -OutFile $AgentUpgradedPath;

#Stop the service
sc.exe stop $AgentName;

#Delete the current exe and replace it with the new one
rm -force $AgentPath;
mv $AgentUpgradedPath $AgentPath;

#Start the service
sc.exe start $AgentName;