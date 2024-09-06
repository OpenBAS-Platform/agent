;includes
!include nsDialogs.nsh
!include LogicLib.nsh
!include FileFunc.nsh

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

# Windows Service
!define displayName "${APPNAME} Service"
!define serviceName "OBASAgentService"
 
RequestExecutionLevel admin ;Require admin rights on NT6+ (When UAC is turned on)
 
InstallDir "$PROGRAMFILES\${COMPANYNAME}\${APPNAME}"
 
# rtf or txt file - remember if it is txt, it must be in the DOS text format (\r\n)
LicenseData "license.txt"
# This will be in the installer/uninstaller's title bar
Name "${COMPANYNAME} - ${APPNAME}"
Icon "openbas.ico"
outFile "agent-installer.exe"
 
; page definition
page license
page directory
Page custom nsDialogsConfig nsDialogsPageLeave
Page instfiles
 
!macro VerifyUserIsAdmin
UserInfo::GetAccountType
pop $0
${If} $0 != "admin" ;Require admin rights on NT4+
        messageBox mb_iconstop "Administrator rights required!"
        setErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
        quit
${EndIf}
!macroend

Var Dialog
Var LabelURL
Var /GLOBAL ConfigURL
Var LabelToken
Var /GLOBAL ConfigToken

function .onInit
	setShellVarContext all
	!insertmacro VerifyUserIsAdmin
	${GetParameters} $R0
    ${GetOptions} $R0 ~OPENBAS_URL= $ConfigURL
    ${GetOptions} $R0 ~ACCESS_TOKEN= $ConfigToken
    ${GetOptions} $R0 ~NON_SYSTEM_USER= $ConfigNonSystemUser
    ${GetOptions} $R0 ~NON_SYSTEM_PWD= $ConfigNonSystemPwd
functionEnd


Var ConfigURLForm
Var ConfigTokenForm
Var ConfigNonSystemUserForm
Var ConfigNonSystemPwdForm

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
	${NSD_CreateText} 0 13u 100% 12u "http://localhost:3001"
	Pop $ConfigURLForm
  ${NSD_CreateLabel} 0 30u 100% 12u "Access token *"
	Pop $LabelToken
	${NSD_CreatePassword} 0 42u 100% 12u ""
	Pop $ConfigTokenForm
  ${NSD_CreateLabel} 0 55u 100% 12u "User (optional)"
    Pop $LabelNonSystemUser
    ${NSD_CreateText} 0 67u 100% 12u ""
    Pop $ConfigNonSystemUserForm
  ${NSD_CreateLabel} 0 85u 100% 12u "Password (optional)"
    Pop $LabelNonSystemPassword
    ${NSD_CreatePassword} 0 97u 100% 12u ""
    Pop $ConfigNonSystemPwdForm


  ${NSD_OnChange} $ConfigURLForm onFieldChange
  ${NSD_OnChange} $ConfigTokenForm onFieldChange
  ${NSD_OnChange} $ConfigNonSystemUserForm onFieldChange
  ${NSD_OnChange} $ConfigNonSystemPwdForm onFieldChange

	nsDialogs::Show
FunctionEnd

Function onFieldChange
  ; save in register the values entered by user
  ${NSD_GetText} $ConfigURLForm $ConfigURL
  ${NSD_GetText} $ConfigTokenForm $ConfigToken
  ${NSD_GetText} $ConfigNonSystemUserForm $ConfigNonSystemUser
  ${NSD_GetText} $ConfigNonSystemPwdForm $ConfigNonSystemPwd

  ; enable next button if both defined 
  ${If} $ConfigURL != "" 
  ${AndIf} $ConfigToken != ""
    GetDlgItem $0 $HWNDPARENT 1
    EnableWindow $0 1
  ${Else}
    GetDlgItem $0 $HWNDPARENT 1
    EnableWindow $0 0
  ${EndIf}

FunctionEnd

Function nsDialogsPageLeave
  ; check values are defined
  ${If} $ConfigURL == ""
    MessageBox MB_OK|MB_ICONEXCLAMATION "Missing URL"
	  Abort
  ${EndIf}

  ${If} $ConfigToken == ""
    MessageBox MB_OK|MB_ICONEXCLAMATION "Missing Token"
	  Abort
  ${EndIf}

 ; No need to check for user and password as they can be empty
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
    ${If} $ConfigUser != ""
      FileWrite $4 "non-system-user = $\"$ConfigNonSystemUser$\"$\r$\n"
    ${EndIf}
    ${If} $ConfigPassword != ""
      FileWrite $4 "non-system-pwd = $\"$ConfigNonSystemPwd$\"$\r$\n"
    ${EndIf}
    FileWrite $4 "$\r$\n" ; newline
  FileClose $4

  ; register windows service
  ExecWait 'sc create ${serviceName} error="severe" displayname="${displayName}" type="own" start="auto" binpath="$INSTDIR\openbas-agent.exe"'
  ; start the service
  ExecWait 'sc start ${serviceName}'

  # Uninstaller - See function un.onInit and section "uninstall" for configuration
  writeUninstaller "$INSTDIR\uninstall.exe"

sectionEnd
 
# Uninstaller
 
function un.onInit
	SetShellVarContext all
 
	#Verify the uninstaller - last chance to back out
	MessageBox MB_OKCANCEL "Permanently remove ${APPNAME}?" IDOK next
		Abort
	next:
	!insertmacro VerifyUserIsAdmin
functionEnd
 
section "uninstall"
  ; unregister service
  ExecWait 'sc delete ${serviceName}'

  ; delete everything
	RMDir /r $INSTDIR
sectionEnd