# Technology

Windows installer is powered by https://nsis.sourceforge.io/
You can download the compiler with https://prdownloads.sourceforge.net/nsis/nsis-3.10-setup.exe?download
Then use the installer.nsi file to generate the installer

# Installation

** Installation required administrator privilege**

## UI based

Just double click on **filigran-obas-agent-installer-0.0.1.exe** and follow the instructions.

## Command based

You can install in silent mode following this kind of command

`filigran-obas-agent-installer-0.0.1.exe /S /OPENBAS_URL="http://your_openbas" /ACCESS_TOKEN="your_access_token" /UNSECURED_CERTIFICATE=false /WITH_PROXY=false`