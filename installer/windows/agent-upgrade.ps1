Stop-Service -Force -Name \"OBAS Agent Service\"; Invoke-WebRequest -Uri " +
              "\"${OPENBAS_URL}/api/agent/package/openbas/windows\" -OutFile \"openbas-installer.exe\"; " +
              "./openbas-installer.exe /S ~OPENBAS_URL=\"${OPENBAS_URL}\" ~ACCESS_TOKEN=\"${OPENBAS_TOKEN}\"; " +
              "Start-Sleep -Seconds 1.5; rm -force ./openbas-installer.exe;