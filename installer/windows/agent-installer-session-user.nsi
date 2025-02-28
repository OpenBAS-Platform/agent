;includes
!include nsDialogs.nsh
!include LogicLib.nsh
!include FileFunc.nsh
!include StrFunc.nsh
${Using:StrFunc} StrRep
${Using:StrFunc} StrCase

!insertmacro GetParameters
!insertmacro GetOptions

!define APPNAME "OBAS Agent"
!define COMPANYNAME "Filigran"
!define DESCRIPTION "Filigran's agent for OpenBAS"
# These will be displayed by the "Click here for support information" link in "Add/Remove Programs"
# It is possible to use "mailto:" links in here to open the email client
!define HELPURL "https://filigran.io/" # "Support Information" link
!define UPDATEURL "https://filigran.io/" # "Product Updates" link
!define ABOUTURL "https://filigran.io/" # "Publisher" link
!define PRIV_STANDARD "Standard"
!define PRIV_ADMIN "Administrator"
!define INST_SESSION "Session"
!define INST_SERVICE "Service"
 
RequestExecutionLevel user
 
InstallDir "C:\${COMPANYNAME}\${APPNAME}"
 
# rtf or txt file - remember if it is txt, it must be in the DOS text format (\r\n)
LicenseData "license.txt"
# This will be in the installer/uninstaller's title bar
Name "${COMPANYNAME} - ${APPNAME}"
Icon "openbas.ico"
outFile "agent-installer-session-user.exe"
 
; page definition
page license
page directory
Page custom nsDialogsConfig nsDialogsPageLeave
Page instfiles

Var Dialog
Var LabelURL
Var /GLOBAL ConfigURL
Var LabelToken
Var /GLOBAL ConfigToken
Var LabelUnsecuredCertificate
Var /GLOBAL ConfigUnsecuredCertificate
Var LabelWithProxy
Var /GLOBAL ConfigWithProxy
Var LabelWithAdminPrivilege
Var /GLOBAL ConfigWithAdminPrivilege
Var /GLOBAL UserSanitized
Var /GLOBAL AgentName

function verifyParam

  ; check values are defined
  ${If} $ConfigURL == ""
    MessageBox MB_OK|MB_ICONEXCLAMATION "Missing URL"
	  Abort
  ${EndIf}

  ${If} $ConfigToken == ""
    MessageBox MB_OK|MB_ICONEXCLAMATION "Missing Token"
	  Abort
  ${EndIf}

  ${If} $ConfigUnsecuredCertificate != "false"
  ${AndIf} $ConfigUnsecuredCertificate != "true"
    MessageBox MB_OK|MB_ICONEXCLAMATION "Missing false or true value for unsecured certificate"
  	  Abort
  ${EndIf}

  ${If} $ConfigWithProxy != "false"
  ${AndIf} $ConfigWithProxy != "true"
    MessageBox MB_OK|MB_ICONEXCLAMATION "Missing false or true value for env with proxy"
      Abort
  ${EndIf}

  ${If} $ConfigWithAdminPrivilege != "false"
  ${AndIf} $ConfigWithAdminPrivilege != "true"
     MessageBox MB_OK|MB_ICONEXCLAMATION "Missing false or true value for admin privilege"
     Abort
  ${EndIf}
functionEnd

function .onInit
    setShellVarContext all
    ${GetParameters} $R0
    ${GetOptions} $R0 ~OPENBAS_URL= $ConfigURL
    ${GetOptions} $R0 ~ACCESS_TOKEN= $ConfigToken
    ${GetOptions} $R0 ~UNSECURED_CERTIFICATE= $ConfigUnsecuredCertificate
    ${GetOptions} $R0 ~WITH_PROXY= $ConfigWithProxy
    ${GetOptions} $R0 ~WITH_ADMIN_PRIVILEGE= $ConfigWithAdminPrivilege

    ;get the user name and sanitize it
    UserInfo::GetName
    Call sanitizeUserName
    pop $UserSanitized

    ; If running silently, check params and update install path with user name
    ${If} ${Silent}
        Call verifyParam
        Call updateInstallDir
    ${EndIf}

functionEnd

Var ConfigURLForm
Var ConfigTokenForm
Var ConfigUnsecuredCertificateForm
Var ConfigWithProxyForm
Var ConfigWithAdminPrivilegeForm

Function nsDialogsConfig

  ; disable next button
  GetDlgItem $0 $HWNDPARENT 1
  EnableWindow $0 0

	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}

  ${NSD_CreateLabel} 0 0 100% 12u "OpenBAS URL *"
	Pop $LabelURL
	${NSD_CreateText} 0 12u 100% 12u "http://localhost:3001"
	Pop $ConfigURLForm
  ${NSD_CreateLabel} 0 24u 100% 12u "Access token *"
	Pop $LabelToken
	${NSD_CreatePassword} 0 36u 100% 12u ""
	Pop $ConfigTokenForm
  ${NSD_CreateLabel} 0 48u 100% 12u "Unsecured certificate (true or false) *"
	Pop $LabelUnsecuredCertificate
	${NSD_CreateText} 0 60u 100% 12u "false"
	Pop $ConfigUnsecuredCertificateForm
  ${NSD_CreateLabel} 0 72u 100% 12u "Env with proxy (true or false) *"
	Pop $LabelWithProxy
	${NSD_CreateText} 0 84u 100% 12u "false"
	Pop $ConfigWithProxyForm
  ${NSD_CreateLabel} 0 96u 100% 12u "Install with admin privilege (true or false) *"
	Pop $LabelWithAdminPrivilege
	${NSD_CreateText} 0 108u 100% 12u "Standard"
	Pop $ConfigWithAdminPrivilegeForm

  ${NSD_OnChange} $ConfigURLForm onFieldChange
  ${NSD_OnChange} $ConfigTokenForm onFieldChange
  ${NSD_OnChange} $ConfigUnsecuredCertificateForm onFieldChange
  ${NSD_OnChange} $ConfigWithProxyForm onFieldChange
  ${NSD_OnChange} $ConfigWithAdminPrivilegeForm onFieldChange

  nsDialogs::Show

FunctionEnd

Function onFieldChange
  ; save in register the values entered by user
  ${NSD_GetText} $ConfigURLForm $ConfigURL
  ${NSD_GetText} $ConfigTokenForm $ConfigToken
  ${NSD_GetText} $ConfigUnsecuredCertificateForm $ConfigUnsecuredCertificate
  ${NSD_GetText} $ConfigWithProxyForm $ConfigWithProxy
  ${NSD_GetText} $ConfigWithAdminPrivilegeForm $ConfigWithAdminPrivilege


  ; enable next button if both defined 
  ${If} $ConfigURL != "" 
  ${AndIf} $ConfigToken != ""
  ${AndIf} $ConfigUnsecuredCertificate != ""
  ${AndIf} $ConfigWithAdminPrivilege != ""
  ${AndIf} $ConfigWithProxy != ""
    GetDlgItem $0 $HWNDPARENT 1
    EnableWindow $0 1
  ${Else}
    GetDlgItem $0 $HWNDPARENT 1
    EnableWindow $0 0
  ${EndIf}

FunctionEnd


Function sanitizeUserName
  Exch $0  ; get the username from the stack
  ; Replace  characters with an empty string
  ${StrRep} $0 $0 "/" ""
  ${StrRep} $0 $0 "\" ""
  ${StrRep} $0 $0 ":" ""
  ${StrRep} $0 $0 "*" ""
  ${StrRep} $0 $0 "?" ""
  ${StrRep} $0 $0 "\" ""
  ${StrRep} $0 $0 "<" ""
  ${StrRep} $0 $0 ">" ""
  ${StrRep} $0 $0 "|" ""

  ; Convert to lowercase
  ${StrCase} $0 $0 "L"

  Exch $0
FunctionEnd

Function updateInstallDir
  ${If} $ConfigWithAdminPrivilege == "true"
    StrCpy $AgentName "OBASAgent-Session-Administrator-$UserSanitized"
  ${Else}
    StrCpy $AgentName "OBASAgent-Session-$UserSanitized"
  ${EndIf}
  StrCpy $INSTDIR "C:\${COMPANYNAME}\$AgentName"
FunctionEnd

Function nsDialogsPageLeave
  Call verifyParam
  Call updateInstallDir
FunctionEnd

section "install"
  # Files for the install directory - to build the installer, these should be in the same directory as the install script (this file)
  setOutPath $INSTDIR
  # Files added here should be removed by the uninstaller (see section "uninstall")
  file "..\..\target\release\openbas-agent.exe"
  file "openbas.ico"
	
  ; write agent config file
  FileOpen $4 "$INSTDIR\openbas-agent-config.toml" w
    FileWrite $4 "debug=false$\r$\n"
    FileWrite $4 "$\r$\n"
    FileWrite $4 "[openbas]$\r$\n"
    FileWrite $4 "url = $\"$ConfigURL$\"$\r$\n"
    FileWrite $4 "token = $\"$ConfigToken$\"$\r$\n"
    FileWrite $4 "unsecured_certificate = $ConfigUnsecuredCertificate$\r$\n"
    FileWrite $4 "with_proxy = $ConfigWithProxy$\r$\n"
    FileWrite $4 "$\r$\n" ; newline
  FileClose $4

  ; Stop the scheduled task
  ExecWait 'schtasks /End /TN "$AgentName"' $0

  ; Remove the existing scheduled task if it exists
  ExecWait 'schtasks /Delete /TN "$AgentName" /F' $0

  ; Create a scheduled task to run the agent
  ${If} $ConfigWithAdminPrivilege == "true"
    ExecWait 'schtasks /Create /TN "$AgentName" /TR "$INSTDIR\openbas-agent.exe" /SC ONLOGON /RL HIGHEST' $0
  ${Else}
    ExecWait 'schtasks /Create /TN "$AgentName" /TR "$INSTDIR\openbas-agent.exe" /SC ONLOGON' $0
  ${EndIf}

  ;start the task 
  ExecWait 'schtasks /Run /TN "$AgentName"' $0


  # Uninstaller - See function un.onInit and section "uninstall" for configuration
  writeUninstaller "$INSTDIR\uninstall.exe"


sectionEnd
 
# Uninstaller
 
function un.onInit
	SetShellVarContext all
 
	#Verify the uninstaller - last chance to back out
	MessageBox MB_OKCANCEL "Permanently remove ${APPNAME}?" IDOK continue
		Abort
	continue:
functionEnd
 
section "uninstall"

  ;Get the directory name which is also the service name 
  ${GetFileName} "$INSTDIR" $AgentName

  ; Stop the scheduled task
  ExecWait 'schtasks /End /TN "$AgentName"' $0

  ; Remove the existing scheduled task
  ExecWait 'schtasks /Delete /TN "$AgentName" /F' $0

  ; Wait 1s to allow the task to fully end before deleting the exe
  Sleep 1000

  ; delete everything
  RMDir /r $INSTDIR
sectionEnd