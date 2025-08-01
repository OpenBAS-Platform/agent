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
 
RequestExecutionLevel admin

# rtf or txt file - remember if it is txt, it must be in the DOS text format (\r\n)
LicenseData "license.txt"
# This will be in the installer/uninstaller's title bar
Name "${COMPANYNAME} - ${APPNAME}"
Icon "openbas.ico"
outFile "agent-installer-service-user.exe"

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
Var LabelUnsecuredCertificate
Var /GLOBAL ConfigUnsecuredCertificate
Var LabelWithProxy
Var /GLOBAL ConfigWithProxy
Var /GLOBAL ConfigServiceName
Var /GLOBAL ConfigInstallDir
Var LabelUser
Var /GLOBAL ConfigUser
Var LabelPassword
Var /GLOBAL AgentName
Var /GLOBAL UserSanitized
Var /GLOBAL ConfigPassword
Var /GLOBAL DisplayName
Var /GLOBAL ServiceName
Var UserSID
Var Perm

Function verifyParam
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

  ${If} $ConfigUser == ""
       MessageBox MB_OK|MB_ICONEXCLAMATION "Missing User"
       Abort
  ${EndIf}

  ${If} $ConfigPassword == ""
       MessageBox MB_OK|MB_ICONEXCLAMATION "Missing Password"
       Abort
  ${EndIf}
FunctionEnd

Function .onInit
    setShellVarContext all
    !insertmacro VerifyUserIsAdmin
    ${GetParameters} $R0
    ${GetOptions} $R0 ~OPENBAS_URL= $ConfigURL
    ${GetOptions} $R0 ~ACCESS_TOKEN= $ConfigToken
    ${GetOptions} $R0 ~UNSECURED_CERTIFICATE= $ConfigUnsecuredCertificate
    ${GetOptions} $R0 ~WITH_PROXY= $ConfigWithProxy
    ${GetOptions} $R0 ~SERVICE_NAME= $ConfigServiceName
    ${GetOptions} $R0 ~INSTALL_DIR= $ConfigInstallDir
    ${If} $ConfigServiceName == ""
        StrCpy $ConfigServiceName "OBASAgent-Service"
    ${EndIf}
    ${If} $ConfigInstallDir == ""
        StrCpy $ConfigInstallDir "C:\${COMPANYNAME}"
    ${EndIf}
    ${GetOptions} $R0 ~USER= $ConfigUser
    ${GetOptions} $R0 ~PASSWORD= $ConfigPassword

    ; If running silently, check params and update install path with user name
    ${If} ${Silent}
        Call verifyParam
        Call updateDirAndServiceName
    ${EndIf}
FunctionEnd

Var ConfigURLForm
Var ConfigTokenForm
Var ConfigUnsecuredCertificateForm
Var ConfigWithProxyForm
Var ConfigUserForm
Var ConfigPasswordForm

Function nsDialogsConfig

  ; disable next button
  GetDlgItem $0 $HWNDPARENT 1
  EnableWindow $0 0
	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}

  ${NSD_CreateLabel} 0 0 100% 10u "OpenBAS URL *"
	Pop $LabelURL
	${NSD_CreateText} 0 10u 100% 10u "http://localhost:3001"
	Pop $ConfigURLForm
  ${NSD_CreateLabel} 0 20u 100% 10u "Access token *"
	Pop $LabelToken
	${NSD_CreatePassword} 0 30u 100% 10u ""
	Pop $ConfigTokenForm
  ${NSD_CreateLabel} 0 40u 100% 10u "Unsecured certificate (true or false) *"
	Pop $LabelUnsecuredCertificate
	${NSD_CreateText} 0 50u 100% 10u "false"
	Pop $ConfigUnsecuredCertificateForm
  ${NSD_CreateLabel} 0 60u 100% 10u "Env with proxy (true or false) *"
	Pop $LabelWithProxy
	${NSD_CreateText} 0 70u 100% 10u "false"
	Pop $ConfigWithProxyForm
  ${NSD_CreateLabel} 0 80u 100% 10u "User *"
	Pop $LabelUser
	${NSD_CreateText} 0 90u 100% 10u ""
	Pop $ConfigUserForm
  ${NSD_CreateLabel} 0 100u 100% 10u "Password *"
	Pop $LabelPassword
	${NSD_CreatePassword} 0 110u 100% 10u ""
	Pop $ConfigPasswordForm

  ${NSD_OnChange} $ConfigURLForm onFieldChange
  ${NSD_OnChange} $ConfigTokenForm onFieldChange
  ${NSD_OnChange} $ConfigUnsecuredCertificateForm onFieldChange
  ${NSD_OnChange} $ConfigWithProxyForm onFieldChange
  ${NSD_OnChange} $ConfigUserForm onFieldChange

  nsDialogs::Show
FunctionEnd

Function onFieldChange
  ; save in register the values entered by user
  ${NSD_GetText} $ConfigURLForm $ConfigURL
  ${NSD_GetText} $ConfigTokenForm $ConfigToken
  ${NSD_GetText} $ConfigUnsecuredCertificateForm $ConfigUnsecuredCertificate
  ${NSD_GetText} $ConfigWithProxyForm $ConfigWithProxy
  ${NSD_GetText} $ConfigUserForm $ConfigUser

  ; enable next button if both defined
  ${If} $ConfigURL != ""
  ${AndIf} $ConfigToken != ""
  ${AndIf} $ConfigUnsecuredCertificate != ""
  ${AndIf} $ConfigUser != ""
  ${AndIf} $ConfigPassword != ""
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
  ${StrRep} $0 $0 "<" ""
  ${StrRep} $0 $0 ">" ""
  ${StrRep} $0 $0 "|" ""

  ; Convert to lowercase
  ${StrCase} $0 $0 "L"

  Exch $0
FunctionEnd


;Update Directly and service information based on the user name
Function updateDirAndServiceName
    StrCpy $R0 "$ConfigUser"
    Push $R0
    Call sanitizeUserName
    Pop $UserSanitized
    StrCpy $AgentName "$ConfigServiceName-$UserSanitized"

    ;update the installation directory
    StrCpy $INSTDIR "$ConfigInstallDir\$AgentName"

    ; update service information
    StrCpy $DisplayName "OBAS Agent Service $UserSanitized"
    StrCpy $ServiceName "$AgentName"
FunctionEnd


Function nsDialogsPageLeave
  Call verifyParam
  Call updateDirAndServiceName
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
    FileWrite $4 "installation_mode = $\"service-user$\"$\r$\n"
    FileWrite $4 "service_name = $\"$ConfigServiceName$\"$\r$\n"
    FileWrite $4 "$\r$\n" ; newline
  FileClose $4

  ;stopping existing service
  ExecWait 'sc stop $ServiceName' $0

  ;deleting existing service
  ExecWait 'sc delete $ServiceName' $0

  ; register windows service
  ExecWait 'sc create $ServiceName error="severe" displayname="$DisplayName" obj="$ConfigUser" password="$ConfigPassword" type="own" start="auto" binpath="$INSTDIR\openbas-agent.exe"' $R0

  ; configure restart in case of failure
  ExecWait 'sc failure $ServiceName reset= 0 actions= restart/60000/restart/60000/restart/60000'

  ;------ Add the permissions to start/stop service for the user

  ; Retrieve the SID for $ConfigUser using PowerShell
  nsExec::ExecToStack "powershell.exe -NoProfile -WindowStyle Hidden -Command (New-Object System.Security.Principal.NTAccount('$ConfigUser')).Translate([System.Security.Principal.SecurityIdentifier]).Value"
  Pop $R0    ; Pop the exit code
  Pop $UserSID  ; Pop the SID string

  ;remove newline and whitespace from the UserSID
  Push $UserSID
  Call Trim
  Pop $UserSID

  ; Get Existing permssion and Add permission for the user to stop/start the service
  nsExec::ExecToStack "cmd /c sc sdshow $ServiceName"
  Pop $R0    ; Pop the exit code
  Pop $Perm  ; Pop the perm

  ;remove newline and whitespace from the result returned by sdsshow
  Push $Perm
  Call Trim
  Pop $Perm

  ;remove the "D:" (2 first characters ) from the permission to be able to add the new permission at the beginning
  StrCpy $Perm $Perm "" 2

  ;run the command to add the permission
  ExecWait 'cmd /c sc sdset "$ServiceName" "D:(A;;RPWPCR;;;$UserSID)$Perm"' $R0


  ; start the service
  ExecWait 'sc start $ServiceName' $R0

  # Uninstaller - See function un.onInit and section "uninstall" for configuration
  writeUninstaller "$INSTDIR\uninstall.exe"
sectionEnd
 
# Uninstaller
 
Function un.onInit
  SetShellVarContext all

  #Verify the uninstaller - last chance to back out
  MessageBox MB_OKCANCEL "Permanently remove ${APPNAME}?" IDOK next
    Abort
  next:
    !insertmacro VerifyUserIsAdmin
FunctionEnd
 
section "uninstall"
  ;Get the directory name which is also the service name 
  ${GetFileName} "$INSTDIR" $ServiceName

  ; unregister service
  ExecWait 'sc stop $ServiceName'
  ExecWait 'sc delete $ServiceName'

  ; delete everything
  RMDir /r $INSTDIR
sectionEnd

; Trim
;   Removes leading & trailing whitespace from a string
; Usage:
;   Push
;   Call Trim
;   Pop
Function Trim
  Exch $R1 ; Original string
  Push $R2

  Loop:
    StrCpy $R2 "$R1" 1
	StrCmp "$R2" " " TrimLeft
	StrCmp "$R2" "$\r" TrimLeft
	StrCmp "$R2" "$\n" TrimLeft
	StrCmp "$R2" "$\t" TrimLeft
	GoTo Loop2
  TrimLeft:
	StrCpy $R1 "$R1" "" 1
	Goto Loop

  Loop2:
	StrCpy $R2 "$R1" 1 -1
	StrCmp "$R2" " " TrimRight
	StrCmp "$R2" "$\r" TrimRight
	StrCmp "$R2" "$\n" TrimRight
	StrCmp "$R2" "$\t" TrimRight
	GoTo Done
  TrimRight:
	StrCpy $R1 "$R1" -1
	Goto Loop2

  Done:
	Pop $R2
	Exch $R1
FunctionEnd