#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=favicon.ico
#AutoIt3Wrapper_Outfile=dumpconfigurator-1.2.1.20-x86.exe
#AutoIt3Wrapper_Outfile_x64=dumpconfigurator-1.2.1.20-x64.exe
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=Sets registry settings for automatic creation of user dumps
#AutoIt3Wrapper_Res_Description=Sets registry settings for automatic creation of user dumps
#AutoIt3Wrapper_Res_Fileversion=1.2.1.20
#AutoIt3Wrapper_Res_LegalCopyright=Copyright © 2011 Torsten Feld - All rights reserved.
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

AutoItSetOption("TrayIconDebug", 1)

#region ### includes

	#include <ButtonConstants.au3>
	#include <ComboConstants.au3>
	#include <EditConstants.au3>
	#include <GUIConstantsEx.au3>
	#include <StaticConstants.au3>
	#include <WindowsConstants.au3>
	#include <WinAPI.au3>

	#include <GuiComboBox.au3>

	#Include <File.au3>
	#Include <String.au3>
	#include <INet.au3>
	#Include <Misc.au3>

	#include <Array.au3>

	#include ".\incs\APIErrors.au3"
	#include ".\incs\NTErrors.au3"
	#include ".\incs\APIConstants.au3"
	#include ".\incs\WinAPIEx.au3"

#endregion

#region ### global variables

	Global $gRegBase = "HKLM"
	If @OSArch = "X64" Then $gRegBase &= "64"
	$gRegBase &= "\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
	Global $gaRegUserDumpValues[4] ; active, folder, count, type
	Global $gaRegUserDumpValuesNew[4] ; active, folder, count, type

	Global $gDirTemp = @TempDir & "\dumpconfigurator"
	Global $gDirUserAutomaticDump
	Global $gDirUserManualDump
	Global $gDirProgramFilesx86 = EnvGet("ProgramFiles")
	If @OSArch = "X64" Then $gDirProgramFilesx86 &= " (x86)"
	Global $gDirProgramFilesx64 = EnvGet("ProgramFiles")
	Global $gFileIniValuesSave = $gDirTemp & "\savedvalues.ini"
	Global $gDbgFile = $gDirTemp & "\dc-debug.log"

	Global $gUrlDownloadTool = "https://github.com/torstenfeld/um-dumpcreator/downloads"

	Global $gVersion
	Global $gTitleMsgBox = "Dump configurator"
	Global $gTitleMsgBoxFull

	Global $gaUserModeAutomaticDumps

	Global $gaProcesses
	Global $gPreVista = False
	Global $gInstalledDebuggingTools
	Global $gDirDebuggingToolsx64
	Global $gDirDebuggingToolsx86

	Global $pos1 = MouseGetPos()
	Global $pos2 = MouseGetPos() ; must be initialized
	Global $appHandle = 0

	Global $gProcess
	Global $gProcCmdLine
	Global $gToolTipTxt
	Global $gProcessCrashed

	Global $ComboProcesses

	Global $_COMMON_KERNEL32DLL=DllOpen("kernel32.dll")		; DLLClose() will be done automatically on exit. [this doesn't reload the DLL]

#endregion

#region ### main

;~ 	AutoItSetOption("MustDeclareVars", 1)
	AutoItSetOption("MouseCoordMode", 1)

	If Not FileExists($gDirTemp) Then DirCreate($gDirTemp)
	If FileExists($gDbgFile) Then FileDelete($gDbgFile)

	_DcMain()

#endregion

Func _DcMain()

	_WriteDebug("INFO;_DcMain;_DcMain started")
	_ArchCheck()

	If @Compiled Then
		$gVersion = FileGetVersion(@ScriptFullPath, "FileVersion")
		If @error Then $gVersion = "0.0.0.0"
		_WriteDebug("INFO;_DcMain;compiled - Version " & $gVersion)
	Else
		$gVersion = "9.99.99.99 - not compiled"
		_WriteDebug("INFO;_DcMain;Not compiled - Version " & $gVersion)
	EndIf

	_CheckForUpdate()

	_WriteDebug("INFO;_DcMain;$gDirProgramFilesx86: " & $gDirProgramFilesx86)
	_WriteDebug("INFO;_DcMain;$gDirProgramFilesx64: " & $gDirProgramFilesx64)

	_DebugToolsMain()
;~ 	MsgBox(0, "test", "$gDirDebuggingToolsx64:" & $gDirDebuggingToolsx64 & @CRLF & "$gDirDebuggingToolsx86: " & $gDirDebuggingToolsx86)
;~ 	_DebugToolsGetInstallFolder()

	_ProcessGetList()

	_OsCheckPreVista() ;test
;~ 	$gPreVista = True ;test

	_RegistryGetValues()
	_GetUserModeAutomaticDumps()
;~ 	_ArrayDisplay($gaUserModeAutomaticDumps, "$gaUserModeAutomaticDumps")
	_DcGui()

EndFunc

Func _ArchCheck()

	_WriteDebug("INFO;_ArchCheck;_ArchCheck started")

	If Not @Compiled Then
		_WriteDebug("WARN;_ArchCheck;Not compiled - returning 0 and exiting _ArchCheck")
		Return 0
	EndIf

	Local $lMsgBoxText = ""

	Switch @OSArch
		Case "X64"
			If Not @AutoItX64 Then $lMsgBoxText = "The architecture of your OS (" & @OSArch & ") does not match with the architecture of this tool (X86)." & @CRLF
		Case "X86"
			If @AutoItX64 Then $lMsgBoxText = "The architecture of your OS (" & @OSArch & ") does not match with the architecture of this tool (X64)." & @CRLF
	EndSwitch

	If $lMsgBoxText = "" Then
		_WriteDebug("INFO;_ArchCheck;OsArch check ok - returning 1")
		Return 1
	EndIf
	_WriteDebug("WARN;_ArchCheck;OsArch check nok - $lMsgBoxText: " & StringStripCR($lMsgBoxText))

	Local $iMsgBoxAnswer = MsgBox(52,$gTitleMsgBox, $lMsgBoxText & "Please download the correct version from " & @CRLF & $gUrlDownloadTool & @CRLF & @CRLF & _
		"Would you like to open the site now?", 15)
	Select
		Case $iMsgBoxAnswer = 6 ;Yes
			_WriteDebug("INFO;_ArchCheck;user chose to open download page - exit 0")
			ShellExecuteWait($gUrlDownloadTool)
			Sleep(4000)
			Exit 0
		Case $iMsgBoxAnswer = 7 ;No
			_WriteDebug("ERR ;_ArchCheck;user did NOT choose to open download page - exit 1")
			Exit 1
	EndSelect

EndFunc

Func _OsCheckPreVista()

	_WriteDebug("INFO;_OsCheckPreVista;_OsCheckPreVista started")

	Switch @OSVersion
		Case "WIN_XP", "WIN_XPe", "WIN_2000"
			$gPreVista = True
			_WriteDebug("INFO;_OsCheckPreVista;OsVersion: " & @OSVersion & " - $gPreVista: " & $gPreVista)
		Case "WIN_2008R2", "WIN_7", "WIN_8", "WIN_2008", "WIN_VISTA", "WIN_2003"
			$gPreVista = False
			_WriteDebug("INFO;_OsCheckPreVista;OsVersion: " & @OSVersion & " - $gPreVista: " & $gPreVista)
		Case Else
			_WriteDebug("ERR ;_OsCheckPreVista;OsVersion: " & @OSVersion & " - Os not supported: " & @OSBuild & " / " & @OSServicePack & " - exit 3")
			MsgBox(16,$gTitleMsgBox,"Unfortunately, the Operating System you are using currently not supported. " & @CRLF & _
				"Please write an email to torsten@torsten-feld.de with the following information:" & @CRLF & _
				@OSVersion & " / " & @OSBuild & " / " & @OSServicePack & @CRLF & @CRLF & _
				"Visit https://github.com/torstenfeld/um-dumpcreator for latest news.")
			Exit 3
	EndSwitch

EndFunc

Func _DcGui()

	_WriteDebug("INFO;_DcGui;_DcGui started")

	Local $lChButtonActive = False
	$gTitleMsgBoxFull = $gTitleMsgBox & " - v" & $gVersion

	#Region ### START Koda GUI section ### Form=
	$FormDcGui = GUICreate($gTitleMsgBoxFull, 527, 474, 214, 131)
	$MenuItemHelp = GUICtrlCreateMenu("&Help")
	$MenuItemHelpWeb = GUICtrlCreateMenuItem("Project site", $MenuItemHelp)
	$MenuItemHelpChangelog = GUICtrlCreateMenuItem("Changelog", $MenuItemHelp)
	$MenuItemHelpDownload = GUICtrlCreateMenuItem("Download", $MenuItemHelp)
	$MenuItemHelpCredits = GUICtrlCreateMenuItem("Credits", $MenuItemHelp)
	GUICtrlCreateMenuItem("", $MenuItemHelp)
	$MenuItemHelpUpdate = GUICtrlCreateMenuItem("Check for update", $MenuItemHelp)
	GUICtrlCreateMenuItem("", $MenuItemHelp)
	$MenuItemHelpOpenDbgLog = GUICtrlCreateMenuItem("Open debug log", $MenuItemHelp)

	$ButtonCancel = GUICtrlCreateButton("Cancel", 440, 416, 75, 25)
	GUICtrlSetTip(-1, "Quits the tool")

	$Tab1 = GUICtrlCreateTab(8, 8, 513, 401)
	$TabUserMode = GUICtrlCreateTabItem("User mode")
	$GroupUserAutomatic = GUICtrlCreateGroup("User Mode Automatic", 12, 33, 497, 193)
	GUICtrlSetFont(-1, 8, 400, 0, "Arial")
	$CheckboxActivate = GUICtrlCreateCheckbox("Activate", 20, 49, 97, 17)
	GUICtrlSetTip(-1, "(De)activate automatic creation of process dumps, if a process crashes")
	$LabelDumpCount = GUICtrlCreateLabel("Dump count", 20, 73, 72, 17)
	$LabelDumpLocate = GUICtrlCreateLabel("Directory to store:", 20, 105, 72, 17)
	$LabelDumpType = GUICtrlCreateLabel("Type of dump:", 20, 137, 72, 17)
	$InputDumpCount = GUICtrlCreateInput("", 132, 73, 185, 22)
	GUICtrlSetTip(-1, "Sets the number of dumps which will be saved until the oldest dump will be deleted")
	$InputDumpLocate = GUICtrlCreateInput("", 132, 105, 185, 22)
	GUICtrlSetTip(-1, "Sets the folder to which the dumps are written")
	$RadioCustomDump = GUICtrlCreateRadio("Custom dump", 132, 137, 97, 17)
	GUICtrlSetState(-1, $GUI_HIDE)
	$RadioMiniDump = GUICtrlCreateRadio("Mini dump", 236, 137, 97, 17)
	GUICtrlSetTip(-1, "Only basic information of the process itself is written to disk")
	$RadioFullDump = GUICtrlCreateRadio("Full dump", 340, 137, 89, 17)
	GUICtrlSetTip(-1, "Whole memory of the process is written to disk")
	$ButtonCustomDump = GUICtrlCreateButton("Custom dump", 132, 161, 75, 25)
	GUICtrlSetState(-1, $GUI_HIDE)
	$ButtonExtended = GUICtrlCreateButton("Extended", 388, 161, 115, 25)
	GUICtrlSetTip(-1, "Setting configuration, which is recommended to collect data for troubleshooting")
	$ButtonMicrosoft = GUICtrlCreateButton("Microsoft", 268, 161, 115, 25)
	GUICtrlSetTip(-1, "Setting configuration, which is recommended by Microsoft for daily work")
	$ButtonUserABrowse = GUICtrlCreateButton("Browse", 364, 105, 75, 25)
	$ButtonSave = GUICtrlCreateButton("Save", 428, 193, 75, 25)
	GUICtrlSetTip(-1, "Configuration is written to registry")
	$ButtonReset = GUICtrlCreateButton("Reset", 132, 193, 75, 25)
	GUICtrlSetTip(-1, "On setting a new configuration for the first time, the original config is saved for later restore")
	$ButtonOpen = GUICtrlCreateButton("Open folder", 212, 193, 75, 25)
	GUICtrlSetTip(-1, "Opens the folder, where dumps are saved")
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$GroupUserManual = GUICtrlCreateGroup("User Mode Manual", 12, 233, 497, 161)
	GUICtrlSetFont(-1, 8, 400, 0, "Arial")
	$Label1 = GUICtrlCreateLabel("Choose Process:", 20, 257, 84, 17)
	$ComboProcesses = GUICtrlCreateCombo("", 132, 257, 217, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
	$ButtonRefresh = GUICtrlCreateButton("Refresh", 364, 257, 75, 25)
	GUICtrlSetTip(-1, "Refresh the process list")
	$ButtonCrosshair = GUICtrlCreateButton("", 476, 257, 25, 25)
	GUICtrlSetTip(-1, "Click to get process by windows")
	$Label2 = GUICtrlCreateLabel("Type of dump:", 20, 321, 72, 17)
	$RadioUserCrash = GUICtrlCreateRadio("Crash", 132, 321, 89, 17)
	GUICtrlSetTip(-1, "Select if you would like to get a dump of a crashed process")
	GUICtrlSetState(-1, $GUI_CHECKED)
	$RadioUserHang = GUICtrlCreateRadio("Hang", 228, 321, 113, 17)
	GUICtrlSetTip(-1, "Select if you would like to get a dump of a hanging process")
	$Label3 = GUICtrlCreateLabel("Dump location:", 20, 289, 75, 17)
	$InputUserLocation = GUICtrlCreateInput("", 132, 289, 185, 22)
	GUICtrlSetTip(-1, "Specify the folder where the dumps should be saved")
	$ButtonUserBrowse = GUICtrlCreateButton("Browse", 364, 289, 75, 25)
	GUICtrlSetTip(-1, "Click to browse for the folder where the dumps should be saved")
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$Label4 = GUICtrlCreateLabel("Process existing:", 20, 353, 83, 17)
	$RadioProcessExists = GUICtrlCreateRadio("Existing", 132, 353, 89, 17)
	GUICtrlSetState(-1, $GUI_CHECKED)
	GUICtrlSetTip(-1, "Select if the process has already crashed")
	$RadioProcessWaiting = GUICtrlCreateRadio("Waiting for", 228, 353, 113, 17)
	GUICtrlSetTip(-1, "Select if the process is currently not running")
	$ButtonUserCreateDump = GUICtrlCreateButton("Create dump", 364, 353, 75, 25)
	GUICtrlSetTip(-1, "Click to start dump creation")
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$TabKernelMode = GUICtrlCreateTabItem("Kernel mode")
	GUICtrlCreateTabItem("")
;~ 	Dim $FormDcGui_AccelTable[2][2] = [["0", $MenuItemHelpDownload],["{BS}", $MenuItemHelpCredits]]
;~ 	GUISetAccelerators($FormDcGui_AccelTable)
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	If Not FileExists($gFileIniValuesSave) Then GUICtrlSetState($ButtonReset, $GUI_DISABLE)
	_SetValuesToUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)

	If GUICtrlRead($CheckboxActivate) <> $GUI_CHECKED Then 	_ChangeAccessUserModeDumpControl(False, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)

	If $gPreVista Then
		_ChangeAccessUserModeDumpControl(False, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
		GUICtrlSetState($CheckboxActivate, $GUI_DISABLE)
		GUICtrlSetState($ButtonExtended, $GUI_DISABLE)
		GUICtrlSetState($ButtonMicrosoft, $GUI_DISABLE)
		_WriteDebug("WARN;_DcGui;Automatic user dump gui items disabled as prevista")
	EndIf

	If Not $gInstalledDebuggingTools Then
		GUICtrlSetState($CheckboxActivate, $GUI_DISABLE)
		GUICtrlSetState($ComboProcesses, $GUI_DISABLE)
		GUICtrlSetState($ButtonRefresh, $GUI_DISABLE)
		GUICtrlSetState($ButtonCrosshair, $GUI_DISABLE)
		GUICtrlSetState($RadioUserCrash, $GUI_DISABLE)
		GUICtrlSetState($RadioUserHang, $GUI_DISABLE)
		GUICtrlSetState($InputUserLocation, $GUI_DISABLE)
		GUICtrlSetState($ButtonUserBrowse, $GUI_DISABLE)
		GUICtrlSetState($ButtonUserCreateDump, $GUI_DISABLE)
		GUICtrlSetState($RadioProcessExists, $GUI_DISABLE)
		GUICtrlSetState($RadioProcessWaiting, $GUI_DISABLE)
		_WriteDebug("WARN;_DcGui;Manual user dump gui items disabled as Debugging Tools not installed")
	Else
		_GuiComboProcessFill()
		_WriteDebug("INFO;_DcGui;$ComboProcesses filled")
	EndIf

	GUICtrlSetData($InputUserLocation, IniRead($gFileIniValuesSave, "UserModeManual", "DumpLocation", ""))
	_WriteDebug("INFO;_DcGui;$InputUserLocation filled")

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE, $ButtonCancel
				_WriteDebug("INFO;_DcGui;$GUI_EVENT_CLOSE, $ButtonCancel - exit")
				Exit
			Case $MenuItemHelpOpenDbgLog
				_WriteDebug("INFO;_DcGui;$MenuItemHelpOpenDbgLog clicked")
				ShellExecute($gDbgFile)
			Case $MenuItemHelpUpdate
				_WriteDebug("INFO;_DcGui;$MenuItemHelpUpdate clicked")
				If Not _CheckForUpdate() Then MsgBox(262208, $gTitleMsgBox, "You are using the latest version. No update is necessary.",15)
			Case $MenuItemHelpWeb
				_WriteDebug("INFO;_DcGui;$MenuItemHelpWeb clicked")
				ShellExecute("https://github.com/torstenfeld/um-dumpcreator")
			Case $MenuItemHelpChangelog
				_WriteDebug("INFO;_DcGui;$MenuItemHelpChangelog clicked")
				ShellExecute("https://github.com/torstenfeld/um-dumpcreator#readme")
			Case $MenuItemHelpDownload
				_WriteDebug("INFO;_DcGui;$MenuItemHelpDownload clicked")
				ShellExecute("https://github.com/torstenfeld/um-dumpcreator/downloads")
			Case $MenuItemHelpCredits
				_WriteDebug("INFO;_DcGui;$MenuItemHelpCredits clicked")
				_DcGuiCredits($FormDcGui)
			Case $ButtonCrosshair
				_WriteDebug("INFO;_DcGui;$ButtonCrosshair clicked")
				If $lChButtonActive Then
					AdlibUnRegister("_Mouse_Control_GetInfoAdlib")
					ToolTip("")
					_WriteDebug("INFO;_DcGui;$ButtonCrosshair - _Mouse_Control_GetInfoAdlib unregistered - ToolTip deleted")
					$lChButtonActive = False
				Else
					_ProcessGetList()
					_GuiComboProcessFill()
					AdlibRegister("_Mouse_Control_GetInfoAdlib", 10)
					_WriteDebug("INFO;_DcGui;$ButtonCrosshair - _Mouse_Control_GetInfoAdlib registered - ToolTip activated")
					$lChButtonActive = True
				EndIf
			Case $ButtonRefresh
				_WriteDebug("INFO;_DcGui;$ButtonRefresh clicked")
				_ProcessGetList()
				_GuiComboProcessFill()
			Case $CheckboxActivate
				_WriteDebug("INFO;_DcGui;$CheckboxActivate clicked")
				If GUICtrlRead($CheckboxActivate) = $GUI_CHECKED Then
					_ChangeAccessUserModeDumpControl(True, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
					_WriteDebug("INFO;_DcGui;$CheckboxActivate checked - activated corresponding gui items")
				Else
					_ChangeAccessUserModeDumpControl(False, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
					_WriteDebug("INFO;_DcGui;$CheckboxActivate unchecked - deactivated corresponding gui items")
				EndIf
			Case $ButtonSave
				_WriteDebug("INFO;_DcGui;$ButtonSave clicked")
				If Not _CheckBackupIniFileValues() Then _SaveValuesToIniFile() ; returns 1 if backup has already been made
				GUICtrlSetState($ButtonReset, $GUI_ENABLE)
				_WriteDebug("INFO;_DcGui;reading user dump items values")
				_GetValuesFromUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				If _CompareUserDumpValues() Then
					MsgBox(262208,$gTitleMsgBox,"No value has changed.",15)
					_WriteDebug("INFO;_DcGui;values have not changed - continuing loop")
					ContinueLoop
				EndIf
				_RegistryWriteValues()
				_WriteDebug("INFO;_DcGui;values have been written to registry")
				_RegistryGetValues()
				_SetValuesToUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				_WriteDebug("INFO;_DcGui;values have been rewritten to gui")
				MsgBox(64,$gTitleMsgBox,"The new configuration has been written to registry.",15)
			Case $ButtonUserABrowse
				_WriteDebug("INFO;_DcGui;$ButtonUserABrowse clicked")
				$lFolderDump = GUICtrlRead($InputDumpLocate)
				_WriteDebug("INFO;_DcGui;$lFolderDump: " & $lFolderDump)
				If StringInStr($lFolderDump, "%") Then
					$lTempStringBetweenResult = StringRegExpReplace($lFolderDump, ".*\%(.*)\%.*", "$1")
					$lFolderDump = StringReplace($lFolderDump, "%" & $lTempStringBetweenResult & "%", EnvGet($lTempStringBetweenResult))
					_WriteDebug("INFO;_DcGui;system variable used: $lFolderDump: " & $lFolderDump)
				EndIf
				If Not FileExists($lFolderDump) Then $lFolderDump = @ScriptDir
				$lFolderDump = FileSelectFolder("Please choose a directoy to store the dumps", "", 7, $lFolderDump, $FormDcGui)
				If @error Then ContinueLoop
				_WriteDebug("INFO;_DcGui;$lFolderDump: " & $lFolderDump)
				GUICtrlSetData($InputDumpLocate, $lFolderDump)
			Case $ButtonExtended
				_WriteDebug("INFO;_DcGui;$ButtonExtended clicked")
				GUICtrlSetState($CheckboxActivate, $GUI_CHECKED)
				GUICtrlSetData($InputDumpCount, 10)
				If GUICtrlRead($InputDumpLocate) = "" Then GUICtrlSetData($InputDumpLocate, "%LOCALAPPDATA%\CrashDumps")
				GUICtrlSetState($RadioFullDump, $GUI_CHECKED)
				_ChangeAccessUserModeDumpControl(True, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				_WriteDebug("INFO;_DcGui;set extended settings for user mode automatic")
			Case $ButtonMicrosoft
				_WriteDebug("INFO;_DcGui;$ButtonMicrosoft clicked")
				GUICtrlSetState($CheckboxActivate, $GUI_CHECKED)
				GUICtrlSetData($InputDumpCount, 10)
				GUICtrlSetData($InputDumpLocate, "%LOCALAPPDATA%\CrashDumps")
				GUICtrlSetState($RadioMiniDump, $GUI_CHECKED)
				_ChangeAccessUserModeDumpControl(True, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				_WriteDebug("INFO;_DcGui;set microsoft recommended settings for user mode automatic")
			Case $ButtonReset
				_WriteDebug("INFO;_DcGui;$ButtonReset clicked")
				_IniFileGetValues()
				_SetValuesToUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				_RegistryGetValues()
			Case $ButtonOpen
				_WriteDebug("INFO;_DcGui;$ButtonOpen clicked")
				$lFolderDump = GUICtrlRead($InputDumpLocate)
				If StringInStr($lFolderDump, "%") Then $lFolderDump = _GetRealFolderFromSystemvariable($lFolderDump)
				If FileExists($lFolderDump) Then
					_WriteDebug("INFO;_DcGui;$lFolderDump exists - opening: " & $lFolderDump)
					ShellExecute($lFolderDump)
				Else
					_WriteDebug("WARN;_DcGui;$lFolderDump does not exist")
					If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
					$iMsgBoxAnswer = MsgBox(52,$gTitleMsgBox,"The folder " & $lFolderDump & " does not exist. Would you like to create it now?")
					Select
						Case $iMsgBoxAnswer = 6 ;Yes
							_WriteDebug("INFO;_DcGui;user chose yes, folder is going to be created: " & $lFolderDump)
							DirCreate($lFolderDump)
							ShellExecute($lFolderDump)
						Case $iMsgBoxAnswer = 7 ;No
							_WriteDebug("WARN;_DcGui;user chose no, folder not going to be created")
					EndSelect
				EndIf
			Case $ButtonUserBrowse
				_WriteDebug("INFO;_DcGui;$ButtonUserBrowse clicked")
				$gDirUserManualDump = GUICtrlRead($InputUserLocation)
				If Not FileExists($gDirUserManualDump) Then $gDirUserManualDump = @ScriptDir
				$gDirUserManualDump = FileSelectFolder("Please choose a directoy to store the dumps", "", 7, $gDirUserManualDump, $FormDcGui)
				If @error Then
					_WriteDebug("WARN;_DcGui;$gDirUserManualDump not chosen - continuing loop")
					ContinueLoop
				EndIf
				_WriteDebug("INFO;_DcGui;$gDirUserManualDump: " & $gDirUserManualDump)
				GUICtrlSetData($InputUserLocation, $gDirUserManualDump)
			Case $ButtonUserCreateDump
				_WriteDebug("INFO;_DcGui;$ButtonUserCreateDump clicked")
				IniWrite($gFileIniValuesSave, "UserModeManual", "DumpLocation", GUICtrlRead($InputUserLocation))
				If GUICtrlRead($ComboProcesses) = "" Then
					If GUICtrlRead($RadioProcessExists) = $GUI_CHECKED Then
						_WriteDebug("WARN;_DcGui;no process was chosen")
						MsgBox(16,$gTitleMsgBox,"You did not specify a process to be dumped. Please choose a process in the dropdown menu.")
						ContinueLoop
					EndIf
				EndIf
				If Not FileExists(GUICtrlRead($InputUserLocation)) Then
					_WriteDebug("WARN;_DcGui;$InputUserLocation not set")
					If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
					$iMsgBoxAnswer = MsgBox(52,$gTitleMsgBox,"The directory you specified was not found. Would you like to have it created for you?")
					Select
						Case $iMsgBoxAnswer = 6 ;Yes
							DirCreate(GUICtrlRead($InputUserLocation))
							_WriteDebug("INFO;_DcGui;dir was created: " & $InputUserLocation)
						Case $iMsgBoxAnswer = 7 ;No
							_WriteDebug("WARN;_DcGui;dir not chosen - continuing loop")
							ContinueLoop
					EndSelect
				EndIf

				If GUICtrlRead($RadioUserCrash) = $GUI_CHECKED Then
					$lAdPlusParameters = " -Crash"
				Else
					$lAdPlusParameters = " -Hang"
				EndIf
				If GUICtrlRead($RadioProcessExists) = $GUI_CHECKED Then
					$lAdPlusParameters &= " -p " & StringRegExpReplace(GUICtrlRead($ComboProcesses), ".*\((\d*)\).*", "$1")
				Else
					;InputBox features: Title=Yes, Prompt=Yes, Default Text=No
					If Not IsDeclared("sInputBoxAnswer") Then Local $sInputBoxAnswer
					$sInputBoxAnswer = InputBox("Dump configurator","Please enter the name of the process (without path)" & @CRLF & @CRLF & " e.g. notepad.exe","","","-1","-1")
					Switch @Error
						Case 0 ;OK - The string returned is valid
							$lAdPlusParameters &= " -pmn " & $sInputBoxAnswer
						Case Else ;any error
							_WriteDebug("ERR ;_DcGui;InputBox error: "  & @error)
							MsgBox(0, $gTitleMsgBox, "InputBox error: " & @error) ;test
							ContinueLoop
					EndSwitch
				EndIf
				$lAdPlusParameters &= ' -o "' & GUICtrlRead($InputUserLocation) & _
					'" -FullOnFirst -lcqd'
;~ 					'" -FullOnFirst -CTCFB'
				_WriteDebug("INFO;_DcGui;$lAdPlusParameters: " & $lAdPlusParameters)

				If @OSArch = "X64" Then
					If GUICtrlRead($RadioProcessWaiting) = $GUI_CHECKED Then
						_WriteDebug("INFO;_DcGui;$RadioProcessWaiting set")
						Local $lProcessId = ProcessWait($sInputBoxAnswer)
						Local $lhProcess = _ProcessOpen($lProcessId, 0x00001000)
					Else
						_WriteDebug("INFO;_DcGui;$RadioProcessExists set")
						Local $lhProcess = _ProcessOpen(StringRegExpReplace(GUICtrlRead($ComboProcesses), ".*\((\d*)\).*", "$1"), 0x00001000)
					EndIf
					Local $lProcessArch = _ProcessIsWow64($lhProcess) ; 1 if x86 proc on x64 os
					_ProcessCloseHandle($lhProcess)
				Else
					Local $lProcessArch = 1
				EndIf

				If $lProcessArch Then
					Local $lFileAdPlus = $gDirDebuggingToolsx86 & "\adplus.exe"
				Else
					Local $lFileAdPlus = $gDirDebuggingToolsx64 & "\adplus.exe"
				EndIf
				_WriteDebug("INFO;_DcGui;$lProcessArch: " & $lProcessArch & " - " & $lFileAdPlus)

;~ 				Run(@ComSpec & ' /c ' & FileGetShortName($lFileAdPlus) & $lAdPlusParameters);, @SW_HIDE)
				Local $lOutputRun = Run(FileGetShortName($lFileAdPlus) & $lAdPlusParameters);, @SW_MAXIMIZE, $STDERR_CHILD + $STDOUT_CHILD)

				If GUICtrlRead($RadioProcessWaiting) = $GUI_CHECKED Then MsgBox(64,$gTitleMsgBox,"After the crash occured, please close the crashed window and close the DOS box which just opened with <ENTER>.",10)

				ProcessWaitClose("adplus.exe")
				_WriteDebug("INFO;_DcGui;adplus.exe has been closed")
				MsgBox(0, $gTitleMsgBox, "Dump has been created") ;test
			Case $RadioProcessWaiting
				GUICtrlSetState($ComboProcesses, $GUI_DISABLE)
				_WriteDebug("INFO;_DcGui;$RadioProcessWaiting checked")
			Case $RadioProcessExists
				GUICtrlSetState($ComboProcesses, $GUI_ENABLE)
				_WriteDebug("INFO;_DcGui;$RadioProcessExists checked")

		EndSwitch
	WEnd

EndFunc

Func _DcGuiCredits($lhParent)

	_WriteDebug("INFO;_DcGuiCredits;_DcGuiCredits started")

	Local $lEditMessage = "External sources" & @CRLF & "----------" & @CRLF & _
		"ascend4nt (https://sites.google.com/site/ascend4ntscode/)" & @CRLF & _
		" - _ProcessIsWow64" & @CRLF & _
		" - _ProcessOpen" & @CRLF & _
		" - _ProcessCloseHandle" & @CRLF & _
		" - __PFEnforcePID" & @CRLF & _
		" - __PFCloseHandle"

	#Region ### START Koda GUI section ### Form=
	$FormCredits = GUICreate("Credits", 370, 274, -1, -1)
	$EditCredits = GUICtrlCreateEdit($lEditMessage, 8, 8, 353, 225, BitOR($ES_AUTOVSCROLL, $ES_WANTRETURN, $ES_READONLY))
	$ButtonOk = GUICtrlCreateButton("Ok", 8, 240, 355, 25)
	GUICtrlSetState(-1, $GUI_DEFBUTTON)
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	_WriteDebug("INFO;_DcGuiCredits;$FormCredits is shown")

	While 1
		$nMsgCredits = GUIGetMsg()
		Switch $nMsgCredits
			Case $GUI_EVENT_CLOSE, $ButtonOk
				GUIDelete($FormCredits)
				_WriteDebug("INFO;_DcGuiCredits;$FormCredits deleted")
				If WinExists($gTitleMsgBoxFull) Then WinActivate($gTitleMsgBoxFull)
				ExitLoop
		EndSwitch
	WEnd

EndFunc

Func _ChangeAccessUserModeDumpControl($lActivate, ByRef $InputDumpCount, ByRef $InputDumpLocate, ByRef $RadioCustomDump, ByRef $RadioMiniDump, ByRef $RadioFullDump)

	_WriteDebug("INFO;_ChangeAccessUserModeDumpControl;_ChangeAccessUserModeDumpControl started")

	If $lActivate Then
		GUICtrlSetState($InputDumpCount, $GUI_ENABLE)
		GUICtrlSetState($InputDumpLocate, $GUI_ENABLE)
		GUICtrlSetState($RadioMiniDump, $GUI_ENABLE)
		GUICtrlSetState($RadioFullDump, $GUI_ENABLE)
		_WriteDebug("INFO;_ChangeAccessUserModeDumpControl;Items activated")
	Else
		GUICtrlSetState($InputDumpCount, $GUI_DISABLE)
		GUICtrlSetState($InputDumpLocate, $GUI_DISABLE)
		GUICtrlSetState($RadioMiniDump, $GUI_DISABLE)
		GUICtrlSetState($RadioFullDump, $GUI_DISABLE)
		_WriteDebug("INFO;_ChangeAccessUserModeDumpControl;Items deactivated")
	EndIf
EndFunc

Func _ProcessGetList()

	_WriteDebug("INFO;_ProcessGetList;_ProcessGetList started")

	$gaProcesses = ProcessList()
	If $gaProcesses[0][0] = 0 Then
		_WriteDebug("ERR ;_ProcessGetList;error in ProcessList()")
		Return SetError(1, 0, 1)
	EndIf
	_WriteDebug("INFO;_ProcessGetList;sorting $gaProcesses")
	_ArraySort($gaProcesses, 0, 1)

EndFunc

Func _GuiComboProcessFill()
	_WriteDebug("INFO;_GuiComboProcessFill;_GuiComboProcessFill started")
	_GUICtrlComboBox_ResetContent($ComboProcesses)
	_WriteDebug("INFO;_GuiComboProcessFill;$ComboProcesses has been reset")
	_GUICtrlComboBox_BeginUpdate($ComboProcesses)
	For $i = 1 To $gaProcesses[0][0]
		_GUICtrlComboBox_AddString($ComboProcesses, $gaProcesses[$i][0] & " (" & $gaProcesses[$i][1] & ")")
	Next
	_GUICtrlComboBox_EndUpdate($ComboProcesses)
	_WriteDebug("INFO;_GuiComboProcessFill;$ComboProcesses has been filled")

EndFunc

Func _ProcessGetExe($lHandle) ; returns process executable

	_WriteDebug("INFO;_ProcessGetExe;_ProcessGetExe started")
	Local $lPid = WinGetProcess($lHandle)
	_WriteDebug("INFO;_ProcessGetExe;$lPid: " & $lPid)
	Local $lArrayResult = _ArraySearch($gaProcesses, $lPid, 0, 0, 0, 0, 1, 1)
	If @error Then
		_WriteDebug("WARN;_ProcessGetExe;$lPid not found in array - refreshing and searching again")
		_ProcessGetList()
		_GuiComboProcessFill()
		$lArrayResult = _ArraySearch($gaProcesses, $lPid, 0, 0, 0, 0, 1, 1)
	EndIf
	_WriteDebug("INFO;_ProcessGetExe;returning " & $gaProcesses[$lArrayResult][0])
	Return $gaProcesses[$lArrayResult][0]

EndFunc

Func _Mouse_Control_GetInfoAdlib()

	If _IsPressed(0x01) Then
		Switch $gProcess
			Case "WerFault.exe"
				_GUICtrlComboBox_SelectString($ComboProcesses, $gProcessCrashed)
			Case Else
				_GUICtrlComboBox_SelectString($ComboProcesses, $gProcess)
		EndSwitch
	EndIf

    $pos1 = MouseGetPos()

    If $pos1[0] <> $pos2[0] Or $pos1[1] <> $pos2[1] Then ; has the mouse moved?
        Local $a_info = _Mouse_Control_GetInfo()
        Local $aDLL = DllCall('User32.dll', 'int', 'GetDlgCtrlID', 'hwnd', $a_info[0]) ; get the ID of the control
        If @error Then Return

;~ 		If @Compiled Then
;~ 			$lProcessExclude = @ScriptName
;~ 		Else
;~ 			$lProcessExclude = "AutoIt3.exe"
;~ 		EndIf
;~ 		If _ProcessGetExe($a_info[0]) = $lProcessExclude Then
		If _ProcessGetExe($a_info[0]) = @AutoItExe Then
			ToolTip("")
			Return 0
		EndIf
		$gProcess = _ProcessGetExe($a_info[0])
		$gProcCmdLine = _WinAPI_GetProcessCommandLine(WinGetProcess($a_info[0]))

		$gToolTipTxt = "Proc = " & $gProcess & @CRLF & "ProcCmdLine = " & $gProcCmdLine
		Switch $gProcess
			Case "WerFault.exe"
				$gProcessCrashed = $gaProcesses[_ArraySearch($gaProcesses, StringRegExpReplace($gProcCmdLine, ".*\-p\s(\d*)\s.*", "$1"), 0, 0, 0, 0, 1, 1)][0]
				$gToolTipTxt &= @CRLF & "Crash in = " & $gProcessCrashed
		EndSwitch

;~         ToolTip("Handle = " & $a_info[0] & @CRLF & _
;~ 				"Proc = " & _ProcessGetExe($a_info[0]) & @CRLF & _
;~ 				"ProcCmdLine = " & _WinAPI_GetProcessCommandLine(WinGetProcess($a_info[0])) & @CRLF & _
;~                 "Class = " & $a_info[1] & @CRLF & _
;~                 "ID = " & $aDLL[0] & @CRLF & _
;~                 "Mouse X Pos = " & $a_info[2] & @CRLF & _
;~                 "Mouse Y Pos = " & $a_info[3] & @CRLF & _
;~                 "ClassNN = " & $a_info[4] & @CRLF & _ ; optional
;~                 "Parent Hwd = " & _WinAPI_GetAncestor($appHandle, $GA_ROOT) & @CRLF & _
;~                 "Parent Proc = " & _ProcessGetExe(_WinAPI_GetAncestor($appHandle, $GA_ROOT)) & @CRLF & _
;~                 "Parent CmdLine = " & _WinAPI_GetProcessCommandLine(WinGetProcess(_WinAPI_GetAncestor($appHandle, $GA_ROOT))))
        ToolTip($gToolTipTxt)

        $pos2 = MouseGetPos()

    EndIf

EndFunc   ;==>_Mouse_Control_GetInfoAdlib

Func _Mouse_Control_GetInfo()
    Local $client_mpos = $pos1 ; gets client coords because of "MouseCoordMode" = 2
    Local $a_mpos
;~  Call to removed due to offset issue $a_mpos = _ClientToScreen($appHandle, $client_mpos[0], $client_mpos[1]) ; $a_mpos now screen coords
    $a_mpos = $client_mpos
    $appHandle = GetHoveredHwnd($client_mpos[0], $client_mpos[1]) ; Uses the mouse to do the equivalent of WinGetHandle()

    If @error Then Return SetError(1, 0, 0)
    Local $a_wfp = DllCall("user32.dll", "hwnd", "WindowFromPoint", "long", $a_mpos[0], "long", $a_mpos[1]) ; gets the control handle
    If @error Then Return SetError(2, 0, 0)

    Local $t_class = DllStructCreate("char[260]")
    DllCall("User32.dll", "int", "GetClassName", "hwnd", $a_wfp[0], "ptr", DllStructGetPtr($t_class), "int", 260)
    Local $a_ret[5] = [$a_wfp[0], DllStructGetData($t_class, 1), $a_mpos[0], $a_mpos[1], "none"]
    Local $sClassNN = _ControlGetClassnameNN($a_ret[0]) ; optional, will run faster without it
    $a_ret[4] = $sClassNN

    Return $a_ret
EndFunc   ;==>_Mouse_Control_GetInfo

Func GetHoveredHwnd($i_xpos, $i_ypos)
    Local $iRet = DllCall("user32.dll", "int", "WindowFromPoint", "long", $i_xpos, "long", $i_ypos)
    If IsArray($iRet) Then
        $appHandle = $iRet[0]
        Return HWnd($iRet[0])
    Else
        Return SetError(1, 0, 0)
    EndIf
EndFunc   ;==>GetHoveredHwnd

Func _ControlGetClassnameNN($hControl)
    If Not IsHWnd($hControl) Then Return SetError(1, 0, "")
    Local Const $hParent = _WinAPI_GetAncestor($appHandle, $GA_ROOT) ; get the Window handle, this is set in GetHoveredHwnd()
    If Not $hParent Then Return SetError(2, 0, "")

    Local Const $sList = WinGetClassList($hParent) ; list of every class in the Window
    Local $aList = StringSplit(StringTrimRight($sList, 1), @LF, 2)
    _ArraySort($aList) ; improves speed
    Local $nInstance, $sLastClass, $sComposite

    For $i = 0 To UBound($aList) - 1
        If $sLastClass <> $aList[$i] Then ; set up the first occurrence of a unique classname
            $sLastClass = $aList[$i]
            $nInstance = 1
        EndIf
        $sComposite = $sLastClass & $nInstance ;build the ClassNN for testing with ControlGetHandle. ClassNN = Class & ClassCount
        ;if ControlGetHandle(ClassNN) matches the given control return else look at the next instance of the classname
        If ControlGetHandle($hParent, "", $sComposite) = $hControl Then
            Return $sComposite
        EndIf
        $nInstance += 1 ; count the number of times the class name appears in the list
    Next
    Return SetError(3, 0, "")

EndFunc   ;==>_ControlGetClassnameNN

Func _RegistryGetValues()

	_WriteDebug("INFO;_RegistryGetValues;_RegistryGetValues started")

	$lRegBase = $gRegBase & "\LocalDumps"
	$gaRegUserDumpValues[0] = False

	$gaRegUserDumpValues[1] = RegRead($lRegBase, "DumpFolder")
	If $gaRegUserDumpValues[1] <> "" Then
		$gaRegUserDumpValues[0] = True
		$gDirUserAutomaticDump = _GetRealFolderFromSystemvariable($gaRegUserDumpValues[1])
		_WriteDebug("INFO;_RegistryGetValues;$gDirUserAutomaticDump: " & $gDirUserAutomaticDump)
	Else
		$gDirUserAutomaticDump = ""
		_WriteDebug("INFO;_RegistryGetValues;$gDirUserAutomaticDump: " & $gDirUserAutomaticDump)
		Return SetError(1, 0, 0)
	EndIf

	$gaRegUserDumpValues[2] = RegRead($lRegBase, "DumpCount")
	$gaRegUserDumpValues[3] = RegRead($lRegBase, "DumpType")
	_WriteDebug("INFO;_RegistryGetValues;Registry values read")

	_WriteDebug("INFO;_RegistryGetValues;$gaRegUserDumpValues[0]: " & $gaRegUserDumpValues[0])

EndFunc

Func _RegistryWriteValues()

	_WriteDebug("INFO;_RegistryWriteValues;_RegistryWriteValues started")
	$lRegBase = $gRegBase & "\LocalDumps"
;~ 	_ArrayDisplay($gaRegUserDumpValuesNew, "$gaRegUserDumpValuesNew")

	If $gaRegUserDumpValuesNew[0] = True Then
		RegWrite($lRegBase, "DumpFolder", "REG_EXPAND_SZ", $gaRegUserDumpValuesNew[1])
		If @error Then
			_WriteDebug("ERR ;_RegistryWriteValues;RegWrite failed: " & @error)
			MsgBox(0, $gTitleMsgBox, "RegWrite error: " & @error) ;test
		EndIf
		RegWrite($lRegBase, "DumpCount", "REG_DWORD", $gaRegUserDumpValuesNew[2])
		RegWrite($lRegBase, "DumpType", "REG_DWORD", $gaRegUserDumpValuesNew[3])
		_WriteDebug("INFO;_RegistryWriteValues;writing to registry successfull")
	Else
		RegDelete($lRegBase, "DumpFolder")
		If @error Then
			_WriteDebug("INFO;_RegistryWriteValues;RegDelete failed: " & @error)
			MsgBox(0, $gTitleMsgBox, "RegDelete error: " & @error) ;test
		EndIf
		RegDelete($lRegBase, "DumpCount")
		RegDelete($lRegBase, "DumpType")
		_WriteDebug("INFO;_RegistryWriteValues;RegDelete successfull")
	EndIf

EndFunc

Func _IniFileGetValues()

	_WriteDebug("INFO;_IniFileGetValues;_IniFileGetValues started")

	$gaRegUserDumpValues[0] = IniRead($gFileIniValuesSave, "values", "active", "")
	If $gaRegUserDumpValues[0] = "" Then
		_WriteDebug("WARN;_IniFileGetValues;could not read value of ini file")
		Return SetError(1, 0, 0)
	EndIf
	$gaRegUserDumpValues[1] = IniRead($gFileIniValuesSave, "values", "folder", "")
	$gaRegUserDumpValues[2] = IniRead($gFileIniValuesSave, "values", "count", "")
	$gaRegUserDumpValues[3] = IniRead($gFileIniValuesSave, "values", "type", "")
	_WriteDebug("INFO;_IniFileGetValues;values read successfully of ini file")

EndFunc

Func _DebugToolsMain()

	_WriteDebug("INFO;_DebugToolsMain;_DebugToolsMain started")

	If @OSArch = "X64" Then
		; filename, download size, installed, x64
		Local $laDbtInfoArray[2][4] = [["dbg_x86.msi", "", 0, 0], ["dbg_amd64.msi", "", 0, 1]]
	else
		Local $laDbtInfoArray[1][4] = [["dbg_x86.msi", "", 0, 0]]
	EndIf
	_WriteDebug("INFO;_DebugToolsMain;@OSArch: " & @OSArch & " / ubound($laDbtInfoArray): " & UBound($laDbtInfoArray))

	If _DebugToolsCheckInstalled($laDbtInfoArray) Then
;~ 		MsgBox(64, "Dump Configurator", "Windows Debugging Tools are already installed. Skipping installation.") ;test
		$gInstalledDebuggingTools = True
		_WriteDebug("INFO;_DebugToolsMain;$gInstalledDebuggingTools: " & $gInstalledDebuggingTools)
		_DebugToolsGetInstallFolder($laDbtInfoArray)
		_WriteDebug("INFO;_DebugToolsMain;wdt folders read - returning 1")
		Return 1 ;test
	Else
		_WriteDebug("WARN;_DebugToolsMain;wdt tools not installed - asking for automatic installation")
		If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
		$iMsgBoxAnswer = MsgBox(36,$gTitleMsgBox,"Windows Debugging Tools are not installed, which are needed for user dump creation. " & @CRLF & "Would you like to install Windows Debugging Tools now?")
		Select
			Case $iMsgBoxAnswer = 6 ;Yes
				_WriteDebug("INFO;_DebugToolsMain;user chose to install wdt")
			Case $iMsgBoxAnswer = 7 ;No
				_WriteDebug("WARN;_DebugToolsMain;user chose NOT to install wdt - returning error 1")
				$gInstalledDebuggingTools = False
				Return SetError(1, 0, 0)
		EndSelect
	EndIf
	If Not _DebugToolsDownload($laDbtInfoArray) Then
		_WriteDebug("WARN;_DebugToolsMain;wdt download failed - returning error 3")
		Return SetError(3, 0, 0)
	EndIf
	_WriteDebug("INFO;_DebugToolsMain;wdt download successfull")

	If _DebugToolsInstall($laDbtInfoArray) Then
		$gInstalledDebuggingTools = True
		_WriteDebug("INFO;_DebugToolsMain;$gInstalledDebuggingTools: " & $gInstalledDebuggingTools)
		_DebugToolsGetInstallFolder($laDbtInfoArray)
		_WriteDebug("INFO;_DebugToolsMain;wdt folders read - returning 1")
		Return 1
	Else
		_WriteDebug("WARN;_DebugToolsMain;wdt tools not installed - returning error 2")
		$gInstalledDebuggingTools = False
		Return SetError(2, 0, 0)
	EndIf

EndFunc

Func _DebugToolsCheckInstalled(ByRef $laDbtInfoArray) ; returns 1 if installed

	_WriteDebug("INFO;_DebugToolsCheckInstalled;_DebugToolsCheckInstalled started")

	Local $lRegUninstallBase
	Local $lRegSubKey, $lRegValue, $lDbgToolsFound = 0

	; filename, download size, installed, x64
	For $i = 0 To UBound($laDbtInfoArray)-1
;~ 		$lRegUninstallBase = "HKLM"
;~ 		If $laDbtInfoArray[$i][3] Then $lRegUninstallBase &= "64"
;~ 		$lRegUninstallBase &= "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"

		_WriteDebug("INFO;_DebugToolsCheckInstalled;$laDbtInfoArray[$i][3]: " & $laDbtInfoArray[$i][3] & " / @OSArch: " & @OSArch)
		$lRegUninstallBase = "HKLM\SOFTWARE"
		If Not $laDbtInfoArray[$i][3] And Not (@OSArch = "X86") Then $lRegUninstallBase &= "\Wow6432Node"
		$lRegUninstallBase &= "\Microsoft\Windows\CurrentVersion\Uninstall\"
		_WriteDebug("INFO;_DebugToolsCheckInstalled;$lRegUninstallBase: " & $lRegUninstallBase)

		For $j = 1 To 9999999999
			$lRegSubKey = RegEnumKey($lRegUninstallBase, $j)
			If @error <> 0 Then ExitLoop
			$lRegValue = RegRead($lRegUninstallBase & $lRegSubKey, "DisplayName")
			If StringInStr($lRegValue, "Debugging Tools for Windows") Then
;~ 				MsgBox(0, "test", $lRegUninstallBase & $lRegSubKey)
				_WriteDebug("INFO;_DebugToolsCheckInstalled;Debug tools found in: " & $lRegUninstallBase & $lRegSubKey)
				$laDbtInfoArray[$i][2] = 1
				$lDbgToolsFound += 1
				ExitLoop
			EndIf
		Next
	Next

	If $lDbgToolsFound = UBound($laDbtInfoArray) then
		$lDbgToolsFound = 1
		_WriteDebug("INFO;_DebugToolsCheckInstalled;$lDbgToolsFound: " & $lDbgToolsFound)
	Else
		$lDbgToolsFound = 0
		_WriteDebug("WARN;_DebugToolsCheckInstalled;$lDbgToolsFound: " & $lDbgToolsFound)
	EndIf

	Return $lDbgToolsFound

EndFunc

Func _DebugToolsDownload(ByRef $laDbtInfoArray) ; returns 1 if files were successfully loaded and sets error if not

	; filename, download size, installed, x64
	_WriteDebug("INFO;_DebugToolsDownload;_DebugToolsDownload started")

	Local $lDownloadSuccess = 0
	Local $lDbtUrlBase = "https://github.com/downloads/torstenfeld/um-dumpcreator/"
;~ 	Local $lDbtUrlFile = "dbg_"
	Local $lNumberOfLoops = UBound($laDbtInfoArray)-1
	Local $lDownloadTotalSize = 0
	Local $lDownloadPreviousSize = 0
	Local $lDownloadCurrentSize
	Local $lDownloadCurrentSizeLoading
	Local $lDownloadPerCent
	Local $lhDownload
	Local $lSkippedArrayEntries = 0

	_WriteDebug("INFO;_DebugToolsDownload;$lDbtUrlBase: " & $lDbtUrlBase)

	For $i = 0 To $lNumberOfLoops
		If $laDbtInfoArray[$i][2] Then ; skip if version already installed
			$lSkippedArrayEntries += 1
			_WriteDebug("INFO;_DebugToolsDownload;download skipped for " & $laDbtInfoArray[$i][0])
			ContinueLoop
		EndIf
		$laDbtInfoArray[$i][1] = InetGetSize($lDbtUrlBase & $laDbtInfoArray[$i][0], 11) / 1024
		_WriteDebug("INFO;_DebugToolsDownload;size for " & $laDbtInfoArray[$i][0] & ": " & $laDbtInfoArray[$i][1])
		$lDownloadTotalSize += $laDbtInfoArray[$i][1]
	Next
	_WriteDebug("INFO;_DebugToolsDownload;$lDownloadTotalSize: " & $lDownloadTotalSize)

	For $i = 0 To $lNumberOfLoops

		If $laDbtInfoArray[$i][2] Then ContinueLoop ; skip if version already installed
		$lhDownload = InetGet($lDbtUrlBase & $laDbtInfoArray[$i][0], $gDirTemp & "\" & $laDbtInfoArray[$i][0], 27, 1)

		If $i = 0 Then
			$lDownloadCurrentSize = InetGetInfo($lhDownload, 0) / 1024
			$lDownloadCurrentSizeLoading = $lDownloadPreviousSize + $lDownloadCurrentSize
			ProgressOn($gTitleMsgBox, "Loading: " & $lDownloadCurrentSizeLoading & " \ " & $lDownloadTotalSize & " kBytes", $lDbtUrlBase & $laDbtInfoArray[$i][0])
		EndIf
		Do
			$lDownloadCurrentSize = InetGetInfo($lhDownload, 0) / 1024
			$lDownloadCurrentSizeLoading = $lDownloadPreviousSize + $lDownloadCurrentSize
			$lDownloadPerCent = StringFormat("%.0i", ($lDownloadCurrentSizeLoading / $lDownloadTotalSize) * 100)
			ProgressSet($lDownloadPerCent, $lDownloadPerCent & " percent", "Loading: " & $lDownloadCurrentSizeLoading & " \ " & $lDownloadTotalSize & " kBytes")
			Sleep(100)
		Until InetGetInfo($lhDownload, 2)
		$lDownloadPreviousSize = $lDownloadCurrentSizeLoading
		InetClose($lhDownload) ; Close the handle to release resources.
;~ 		ProgressSet(100, "Done", "Complete")

		If FileExists($gDirTemp & "\" & $laDbtInfoArray[$i][0]) Then
			Local $lFileSizeLocally = FileGetSize($gDirTemp & "\" & $laDbtInfoArray[$i][0])
			_WriteDebug("INFO;_DebugToolsDownload;$lFileSizeLocally: " & $lFileSizeLocally)
			If ($lFileSizeLocally / 1024) = $laDbtInfoArray[$i][1] Then
				_WriteDebug("INFO;_DebugToolsDownload;download successfull: " & $laDbtInfoArray[$i][0])
				$lDownloadSuccess += 1
			Else
				MsgBox(16,$gTitleMsgBox,"Download of Windows Debugging Tools was not completed (" & $laDbtInfoArray[$i][0] & ").")
				_WriteDebug("WARN;_DebugToolsDownload;download not complete: " & $laDbtInfoArray[$i][0] & " - returning error 2")
				ProgressOff()
				Return SetError(2, 0, 0)
			EndIf
		Else
			MsgBox(16,$gTitleMsgBox,"Download of Windows Debugging Tools failed. (" & $laDbtInfoArray[$i][0] & ")")
			_WriteDebug("WARN;_DebugToolsDownload;download failed: " & $laDbtInfoArray[$i][0] & " - returning error 3")
			ProgressOff()
			Return SetError(3, 0, 0)
		EndIf
	Next
	Sleep(500)
	ProgressOff()

	If $lDownloadSuccess = ($lNumberOfLoops + 1 - $lSkippedArrayEntries) then
		MsgBox(64,$gTitleMsgBox,"Download of Windows Debugging Tools successfull.")
		_WriteDebug("INFO;_DebugToolsDownload;download of all files successfull - returning 1")
		Return 1
	Else
		MsgBox(16,$gTitleMsgBox,"Download of Windows Debugging Tools failed.")
		_WriteDebug("ERR ;_DebugToolsDownload;download failed - returning error 4")
		Return SetError(4, 0, 0)
	EndIf
EndFunc

Func _DebugToolsInstall(ByRef $laDbtInfoArray) ; returns 1 if install was successfull

	_WriteDebug("INFO;_DebugToolsInstall;_DebugToolsInstall started")

	; filename, download size, installed, x64

;~ 	RunWait(@ComSpec & " /c " & $lMsiToInstall & " /qn /lv* " & $gDirTemp & "\windbgt-install.log", "", @SW_HIDE)
	SplashTextOn($gTitleMsgBox, "Installing Debugging Tools for Windows", 300, 150)
	For $i = 0 To UBound($laDbtInfoArray)-1
		If $laDbtInfoArray[$i][2] Then
			_WriteDebug("INFO;_DebugToolsInstall;skipped install of " & $laDbtInfoArray[$i][0])
			ContinueLoop
		EndIf
		ControlSetText($gTitleMsgBox, "", "Static1", "Installing Debugging Tools for Windows (" & $laDbtInfoArray[$i][0] & ")")
		_WriteDebug("INFO;_DebugToolsInstall;install started: " & $laDbtInfoArray[$i][0])
		RunWait(@ComSpec & " /c " & $gDirTemp & "\" & $laDbtInfoArray[$i][0] & " /qn /lv* " & $gDirTemp & "\windbgt-install-" & $laDbtInfoArray[$i][0] & ".log", "", @SW_HIDE)
	next
	SplashOff()

	Sleep(2000)

	If _DebugToolsCheckInstalled($laDbtInfoArray) Then
		MsgBox(64,$gTitleMsgBox,"Installation of Windows Debugging Tools finished successfully.",15)
		Return 1
	Else
		MsgBox(64,$gTitleMsgBox,"Installation of Windows Debugging Tools failed.",15)
		Return SetError(1, 0, 0)
	EndIf

EndFunc

Func _DebugToolsGetInstallFolder(ByRef $laDbtInfoArray)

	_WriteDebug("INFO;_DebugToolsGetInstallFolder;_DebugToolsGetInstallFolder started")

	If Not $gInstalledDebuggingTools Then
		_WriteDebug("WARN;_DebugToolsGetInstallFolder;$gInstalledDebuggingTools: " & $gInstalledDebuggingTools & " - returning error 2")
		Return SetError(2, 0, 0)
	EndIf

	Local $laFolders, $lPathToDebuggingTools, $lIniWdtPath

	; filename, download size, installed, x64

	Local $lNumberOfLoops = UBound($laDbtInfoArray)-1
	For $i = 0 To $lNumberOfLoops

		_WriteDebug("INFO;_DebugToolsGetInstallFolder;starting check of " & $laDbtInfoArray[$i][0])
		If $laDbtInfoArray[$i][3] Then ; if file is x64
			$laFolders = _FileListToArray($gDirProgramFilesx64, "*", 2)
			$lIniWdtPath = "WdtPath64"
		Else
			$laFolders = _FileListToArray($gDirProgramFilesx86, "*", 2)
			$lIniWdtPath = "WdtPath86"
		EndIf
		$lArrayIndex = _ArraySearch($laFolders, "Debugging Tools for Windows", 1, 0, 0, 1)
		If @error Then
			_WriteDebug("WARN;_DebugToolsGetInstallFolder;install folder not found for: " & $laDbtInfoArray[$i][0])
			$lPathToDebuggingTools = IniRead($gFileIniValuesSave, "UserModeManual", $lIniWdtPath, "")
			If $lPathToDebuggingTools <> "" Then
				_WriteDebug("INFO;_DebugToolsGetInstallFolder;read $lPathToDebuggingTools from ini file: " & $lPathToDebuggingTools & " - returning 1")
				Return 1
			EndIf

			If $laDbtInfoArray[$i][3] Then
				$lPathToDebuggingTools = FileSelectFolder("Windows Debugging Tools for x64 installation folder could not be found. Please choose folder by yourself.", "", 6, $gDirProgramFilesx64)
				If @error Then
					$gInstalledDebuggingTools = false
					_WriteDebug("WARN;_DebugToolsGetInstallFolder;$lPathToDebuggingTools x64 not chosen manually - returning error 1 - extended 1")
					Return SetError(1, 1, 0)
				EndIf
				_WriteDebug("INFO;_DebugToolsGetInstallFolder;manual folder selected for wdt x64: " & $lPathToDebuggingTools)
			Else
				$lPathToDebuggingTools = FileSelectFolder("Windows Debugging Tools for x86 installation folder could not be found. Please choose folder by yourself.", "", 6, $gDirProgramFilesx86)
				If @error Then
					$gInstalledDebuggingTools = false
					_WriteDebug("WARN;_DebugToolsGetInstallFolder;$lPathToDebuggingTools x86 not chosen manually - returning error 1 - extended 2")
					Return SetError(1, 2, 0)
				EndIf
				_WriteDebug("INFO;_DebugToolsGetInstallFolder;manual folder selected for wdt x86: " & $lPathToDebuggingTools)
			EndIf
			If Not FileExists($lPathToDebuggingTools & "\adplus.exe") Or Not FileExists($lPathToDebuggingTools & "\cdb.exe") Then
				MsgBox(16,$gTitleMsgBox,"The directory you entered seems not to be a valid Debugging Tools for Windows (" & $laDbtInfoArray[$i][0] & ") installation folder.")
				$gInstalledDebuggingTools = false
				_WriteDebug("WARN;_DebugToolsGetInstallFolder;$lPathToDebuggingTools seems not to be valid - returning error 2")
				Return SetError(2, 0, 0)
			Else
				IniWrite($gFileIniValuesSave, "UserModeManual", $lIniWdtPath, $lPathToDebuggingTools)
				_WriteDebug("INFO;_DebugToolsGetInstallFolder;$lPathToDebuggingTools written to ini file")
			EndIf
		Else
			If $laDbtInfoArray[$i][3] Then ; if file is x64
				$gDirDebuggingToolsx64 = $gDirProgramFilesx64 & "\" & $laFolders[$lArrayIndex]
				_WriteDebug("INFO;_DebugToolsGetInstallFolder;$gDirDebuggingToolsx64: " & $gDirDebuggingToolsx64)
			Else
				$gDirDebuggingToolsx86 = $gDirProgramFilesx86 & "\" & $laFolders[$lArrayIndex]
				_WriteDebug("INFO;_DebugToolsGetInstallFolder;$gDirDebuggingToolsx86: " & $gDirDebuggingToolsx86)
			EndIf
		EndIf
	Next

EndFunc

Func _GetValuesFromUserDumpItems(ByRef $CheckboxActivate, ByRef $InputDumpCount, ByRef $InputDumpLocate, ByRef $RadioCustomDump, ByRef $RadioMiniDump, ByRef $RadioFullDump)

	_WriteDebug("INFO;_GetValuesFromUserDumpItems;_GetValuesFromUserDumpItems started")

	If GUICtrlRead($CheckboxActivate) = $GUI_UNCHECKED Then
		$gaRegUserDumpValuesNew[0] = False
		_WriteDebug("INFO;_GetValuesFromUserDumpItems;$gaRegUserDumpValuesNew[0]: " & $gaRegUserDumpValuesNew[0])
		Return 0
	Else
		$gaRegUserDumpValuesNew[0] = True
	EndIf
	_WriteDebug("INFO;_GetValuesFromUserDumpItems;$gaRegUserDumpValuesNew[0]: " & $gaRegUserDumpValuesNew[0] & " - reading values of gui")

	$gaRegUserDumpValuesNew[1] = GUICtrlRead($InputDumpLocate)
	$gaRegUserDumpValuesNew[2] = GUICtrlRead($InputDumpCount)

	If GUICtrlRead($RadioCustomDump) = $GUI_CHECKED Then $gaRegUserDumpValuesNew[3] = 0
	If GUICtrlRead($RadioMiniDump) =  $GUI_CHECKED Then $gaRegUserDumpValuesNew[3] = 1
	If GUICtrlRead($RadioFullDump) =  $GUI_CHECKED Then $gaRegUserDumpValuesNew[3] = 2

EndFunc

Func _CompareUserDumpValues() ; returns 1 if all values are the same

	_WriteDebug("INFO;_CompareUserDumpValues;_CompareUserDumpValues started")

	For $i = 0 To UBound($gaRegUserDumpValues)-1
		If $gaRegUserDumpValues[$i] <> $gaRegUserDumpValuesNew[$i] Then
			_WriteDebug("INFO;_CompareUserDumpValues;at least one item has changed - returning 0")
			Return 0
		EndIf
	Next

	_WriteDebug("INFO;_CompareUserDumpValues;no item has changed - returning 1")
	Return 1

EndFunc

Func _SetValuesToUserDumpItems(ByRef $CheckboxActivate, ByRef $InputDumpCount, ByRef $InputDumpLocate, ByRef $RadioCustomDump, ByRef $RadioMiniDump, ByRef $RadioFullDump)

	_WriteDebug("INFO;_SetValuesToUserDumpItems;_SetValuesToUserDumpItems started")


	If $gaRegUserDumpValues[0] Then
		GUICtrlSetState($CheckboxActivate, $GUI_CHECKED)
		_WriteDebug("INFO;_SetValuesToUserDumpItems;$CheckboxActivate activated")
	Else
		GUICtrlSetState($CheckboxActivate, $GUI_UNCHECKED)
		_WriteDebug("INFO;_SetValuesToUserDumpItems;$CheckboxActivate not checked - returning error 1")
		Return SetError(1, 0, 0)
	EndIf

	GUICtrlSetData($InputDumpLocate, $gaRegUserDumpValues[1])
	GUICtrlSetData($InputDumpCount, $gaRegUserDumpValues[2])
	Switch $gaRegUserDumpValues[3]
		Case 0
			GUICtrlSetState($RadioCustomDump, $GUI_CHECKED)
		Case 1
			GUICtrlSetState($RadioMiniDump, $GUI_CHECKED)
		Case 2
			GUICtrlSetState($RadioFullDump, $GUI_CHECKED)
		Case Else
			MsgBox(262160,$gTitleMsgBox,"Error in _SetValuesToUserDumpItems()" & @CRLF & @CRLF & "Weird value in $gaRegUserDumpValues[3]",10)
			_WriteDebug("ERR ;_SetValuesToUserDumpItems;Weird value in $gaRegUserDumpValues[3]: " & $gaRegUserDumpValues[3])
			Exit(1)
	EndSwitch
	_WriteDebug("INFO;_SetValuesToUserDumpItems;gui items set successfully")

EndFunc

Func _SaveValuesToIniFile()

	_WriteDebug("INFO;_SaveValuesToIniFile;_SaveValuesToIniFile started")

	IniWrite($gFileIniValuesSave, "values", "active", $gaRegUserDumpValues[0])
	If @error Then
		_WriteDebug("WARN;_SaveValuesToIniFile;could not write value to ini file: " & $gFileIniValuesSave & " - returning error 1")
		Return SetError(1, 0, 0)
	EndIf
	IniWrite($gFileIniValuesSave, "values", "folder", $gaRegUserDumpValues[1])
	IniWrite($gFileIniValuesSave, "values", "count", $gaRegUserDumpValues[2])
	IniWrite($gFileIniValuesSave, "values", "type", $gaRegUserDumpValues[3])

	_WriteDebug("INFO;_SaveValuesToIniFile;values written to ini successfully")

EndFunc

Func _CheckBackupIniFileValues() ; returns 1 if backup has already been made

	_WriteDebug("INFO;_CheckBackupIniFileValues;_CheckBackupIniFileValues started")

	If Not FileExists($gFileIniValuesSave) Then
		_WriteDebug("WARN;_CheckBackupIniFileValues;file does not exist: " & $gFileIniValuesSave & " - returning 0")
		Return 0
	EndIf

	If IniRead($gFileIniValuesSave, "values", "folder", "")  = "" Then Return 0
	If IniRead($gFileIniValuesSave, "values", "count", "")  = "" Then Return 0
	If IniRead($gFileIniValuesSave, "values", "type", "")  = "" Then Return 0

	_WriteDebug("INFO;_CheckBackupIniFileValues;ini values read successfully - returning 1")

	Return 1
EndFunc

Func _GetRealFolderFromSystemvariable($lDirWithVariable) ; returns real path

	_WriteDebug("INFO;_GetRealFolderFromSystemvariable;system variable used $lFolderDump: " & $lDirWithVariable)
	Local $lTempStringBetweenResult = StringRegExpReplace($lDirWithVariable, ".*\%(.*)\%.*", "$1")
	Local $lResult = StringReplace($lDirWithVariable, "%" & $lTempStringBetweenResult & "%", EnvGet($lTempStringBetweenResult))
	_WriteDebug("INFO;_GetRealFolderFromSystemvariable;returning " & $lResult)
	Return $lResult

EndFunc

Func _GetUserModeAutomaticDumps()

	_WriteDebug("INFO;_GetUserModeAutomaticDumps;_GetUserModeAutomaticDumps started")

	$gaUserModeAutomaticDumps = _FileListToArray($gDirUserAutomaticDump, "*.dmp", 1)
	If @error Then
		_WriteDebug("WARN;_GetUserModeAutomaticDumps;_FileListToArray for " & $gDirUserAutomaticDump & " failed with error " & @error & " - returning error 1")
		Dim $gaUserModeAutomaticDumps[1] = [0]
		Return SetError(1, 0, 0)
	EndIf
	_WriteDebug("INFO;_FileListToArray;$gaUserModeAutomaticDumps has " & $gaUserModeAutomaticDumps[0] & " items")

EndFunc

Func _CheckForUpdate() ; returns 1 if update available

	_WriteDebug("INFO;_CheckForUpdate;_CheckForUpdate started")

	$lVersionOnline = _INetGetSource("https://raw.github.com/torstenfeld/um-dumpcreator/master/version.txt")
	_WriteDebug("INFO;_CheckForUpdate;version online: " & $lVersionOnline & " - version used: " & $gVersion)
	If _VersionCompare($gVersion, $lVersionOnline) < 0 Then
		_WriteDebug("INFO;_CheckForUpdate;newer version available")
		If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
		$iMsgBoxAnswer = MsgBox(4,$gTitleMsgBox,"There is a new version available. Please download it from " & @CRLF & $gUrlDownloadTool & @CRLF & @CRLF & _
			"Would you like to open the site now?", 15)
		Select
			Case $iMsgBoxAnswer = 6 ;Yes
				ShellExecuteWait($gUrlDownloadTool)
				Sleep(4000)
				_WriteDebug("INFO;_CheckForUpdate;user chose to open website")
				Exit 0
			Case $iMsgBoxAnswer = 7 ;No
				_WriteDebug("WARN;_CheckForUpdate;user chose NOT to open website")
		EndSelect
		Return 1
	Else
		Return 0
	EndIf

EndFunc

; ===================================================================================================================
; Func _ProcessIsWow64($hProcess)
;
; Determines if process is an x86 (32-bit) process running on an x64 O/S
;	MSDN:
;	  'WOW64 is the x86 emulator that allows 32-bit Windows-based applications to run seamlessly on 64-bit Windows'
;
; $hProcess = Handle to opened Process
;	Process should have been opened with PROCESS_QUERY_INFORMATION or PROCESS_QUERY_LIMITED_INFORMATION (Vista+) access
;
; Returns:
;	Success: 0/False or 1 (true) and @error=0
;	Failure: False, with @error set
;		@error = 1 = invalid parameter
;		@error = 2 = DLLCall error (@extended = error code returned from DLLCall)
;		@error = 3 = API call returned Failure - check GetLastError code for more info
;
; Author: Ascend4nt
; ===================================================================================================================
Func _ProcessIsWow64($hProcess)

	_WriteDebug("INFO;_ProcessIsWow64;_ProcessIsWow64 started")

	If Not IsPtr($hProcess) Then
		_WriteDebug("WARN;_ProcessIsWow64;$hProcess is no pointer - returning error 1 - false")
		Return SetError(1,0,False)
	EndIf

	; Not available on all architectures, but AutoIT uses 'GetProcAddress' here anyway, so no worries about run-time link errors
	Local $aRet=DllCall($_COMMON_KERNEL32DLL,"bool","IsWow64Process","handle",$hProcess,"bool*",0)
	If @error Then
		; Function could not be found (using GetProcAddress), most definitely indicating the function doesn't exist,
		;	hence, not an x64 O/S  [function IS available on some x86 O/S's, but that's what the next steps are for)
		If @error=3 Then
			_WriteDebug("WARN;_ProcessIsWow64;error 3 - function IsWow64Process does not exist - probably x86 OS - returning false")
			Return False
		EndIf
		_WriteDebug("WARN;_ProcessIsWow64;error " & @error & " - returning error 2 - false")
		Return SetError(2,@error,False)	; some other error
	EndIf
	If Not $aRet[0] Then
		_WriteDebug("WARN;_ProcessIsWow64;api returning fail - returning error 3 - false")
		Return SetError(3,0,False)	; API returned 'fail'
	EndIf
	_WriteDebug("INFO;_ProcessIsWow64;returning " & $aRet[2])
	Return $aRet[2]	; non-zero = Wow64, 0 = not
EndFunc

; ===================================================================================================================
; Func _ProcessOpen($vProcessID,$iAccess,$bInheritHandle=False)
;
; Function to open a handle to the given process name/PID.
;
; $vProcessID = process name or ID. -1 is special value meaning to return the current process's 'pseudo-handle'
; $iAccess = Access type (not used when $vProcessID=-1)
; $bInheritHandle = child processes inherit handle? True/False. False is typical.
;
; See 'Process Security and Access Rights (Windows)' at MSDN:
;	http://msdn.microsoft.com/en-us/library/ms684880%28VS.85%29.aspx
;
; Commnly-used access types (combinable) [not used for $vProcessID=-1, which has ALL_ACCESS]:
;	PROCESS_QUERY_LIMITED_INFORMATION = 0x1000 [VISTA+/Server 2008+ O/S required]
;	PROCESS_QUERY_INFORMATION = 0x0400,
;	PROCESS_VM_READ = 0x0010 [for reading process memory],
;	PROCESS_VM_WRITE = 0x0020 [for writing to process memory]
;	PROCESS_VM_OPERATION = 0x0008 (for writing and using VirtualProtect)
;
; Returns:
;	Success: Process handle (non-zero value), with @error=0 and @extended = Process ID#
;	Failure: 0, with @error set:
;		@error = 1 = invalid param
;		@error = 2 = DLLCall error, @extended contains the actuall DLLCall @error result (see AutoIT help)
;		@error = 3 = OpenProcess returned a 0 result (possibly a process that requires higher privilege levels)
;		@error = 16 = Process passed wasn't a number, and does not exist (process ended or is invalid)
;
; Author: Ascend4nt
; ===================================================================================================================
Func _ProcessOpen($vProcessID,$iAccess,$bInheritHandle=False)

	_WriteDebug("INFO;_ProcessOpen;_ProcessOpen started")

	Local $aRet
	; Special 'Open THIS process' ID?  [returns pseudo-handle from Windows]
	If $vProcessID=-1 Then
		$aRet=DllCall($_COMMON_KERNEL32DLL,"handle","GetCurrentProcess")
		If @error Then
			_WriteDebug("WARN;_ProcessOpen;error in GetCurrentProcess: " & @error & " - returning error 2")
			Return SetError(2,@error,0)
		EndIf
		_WriteDebug("INFO;_ProcessOpen;returning " & $aRet[0])
		Return $aRet[0]		; usually the constant '-1', but we're keeping it future-OS compatible this way
	ElseIf Not __PFEnforcePID($vProcessID) Then
		_WriteDebug("WARN;_ProcessOpen;Process does not exist or was invalid - returning error 16")
		Return SetError(16,0,0)		; Process does not exist or was invalid
	EndIf
	$aRet=DllCall($_COMMON_KERNEL32DLL,"handle","OpenProcess","dword",$iAccess,"bool",$bInheritHandle,"dword",$vProcessID)
	If @error Then
		_WriteDebug("WARN;_ProcessOpen;OpenProcess error: " & @error & " - returning error 2")
		Return SetError(2,@error,0)
	EndIf
	If Not $aRet[0] Then
		_WriteDebug("WARN;_ProcessOpen;$aRet[0]: " & $aRet[0] & " - returning error 3")
		Return SetError(3,@error,0)
	EndIf
	_WriteDebug("INFO;_ProcessOpen;returning $aRet[0]: " & $aRet[0] & " with process id " & $vProcessID)
	Return SetExtended($vProcessID,$aRet[0])	; Return Process ID in @extended in case a process name was passed
EndFunc

; ===================================================================================================================
; Func _ProcessCloseHandle(ByRef $hProcess)
;
;	Just calls 'CloseHandle' to close process handle that was opened with _ProcessOpen()
;		(Renamed from _ProcessClose to *Handle due to similarity to ProcessClose() function)
;
; $hProcess = Handle to opened Process
;
; Returns:
;	Success: True, with $hProcess invalidated
;	Failure: False, with @error set:
;		@error = 1 = invalid parameter
;		@error = 2 = DLLCall error, @extended = DLLCall error # (see AutoIT documentation)
;		@error = 3 = 'False' return from API call.
;
; Author: Ascend4nt
; ===================================================================================================================
Func _ProcessCloseHandle(ByRef $hProcess)
	_WriteDebug("INFO;_ProcessCloseHandle;_ProcessCloseHandle started")
	If Not __PFCloseHandle($hProcess) Then
		_WriteDebug("WARN;_ProcessCloseHandle;error in closing process - returning error: " & @error)
		Return SetError(@error,@extended,False)
	EndIf
	_WriteDebug("INFO;_ProcessCloseHandle;returning true")
	Return True
EndFunc

; ===================================================================================================================
; Func __PFEnforcePID(ByRef $vPID)
;
; Takes either a Process ID or Process Name and ensures the returned parameter is a Process ID # (on success)
;	On failure, the passed parameter is invalidated (set to 0 by ProcessExists())
;
; $vPID = Process ID # or Process name. If it is a Process name, it will be converted to a PID# on successful return.
;
; Returns:
;	Success: True, with $vPID correctly set as a Processs ID #, @error=0.
;	Failure: False, with $vPID=0 and @error set:
;		@error = 1 = invalid parameter or Process does not exist
;
; Author: Ascend4nt
; ===================================================================================================================
Func __PFEnforcePID(ByRef $vPID)
	If IsInt($vPID) Then Return True
	$vPID=ProcessExists($vPID)
	If $vPID Then Return True
	Return SetError(1,0,False)
EndFunc

; ===================================================================================================================
; Func __PFCloseHandle(ByRef $hHandle)
;
;	Closes an opened handle (for many various types of objects)
;	  [most likely same as _WinAPI_CloseHandle()]
;
; $hHandle = Handle to opened object (see list of handles that get closed this way @ MSDN)
;
; Returns:
;	Success: True, with $hHandle invalidated
;	Failure: False, with @error set:
;		@error = 1 = invalid parameter
;		@error = 2 = DLLCall error, @extended = DLLCall error # (see AutoIT documentation)
;		@error = 3 = Function returned False (failure) - check GetLastError code
;
; Author: Ascend4nt
; ===================================================================================================================
Func __PFCloseHandle(ByRef $hHandle)
	If Not IsPtr($hHandle) Or $hHandle=0 Then Return SetError(1,0,False)
	Local $aRet=DllCall($_COMMON_KERNEL32DLL,"bool","CloseHandle","handle",$hHandle)
	If @error Then Return SetError(2,@error,False)
	If Not $aRet[0] Then Return SetError(3,@error,False)
	; non-zero value for return means success
	$hHandle=0	; invalidate handle
	Return True
EndFunc

Func _WriteDebug($lParam) ; $lType, $lFunc, $lString) ; creates debuglog for analyzing problems
	Local $lArray[4]
	Local $lResult

;~ 	$lArray[0] bleibt leer
;~ 	$lArray[1] = "Type: "
;~ 	$lArray[2] = "Func: "
;~ 	$lArray[3] = "Desc: "

	Local $lArrayTemp = StringSplit($lParam, ";")
	If @error Then
		Dim $lArrayTemp[4]
;~ 		$lArrayTemp[0] bleibt leer
		$lArrayTemp[1] = "ERR "
		$lArrayTemp[2] = "_WriteDebug"
		$lArrayTemp[3] = "StringSplit failed"
	EndIf

;~ 	if (Not $gAdvDebug) and ($lArrayTemp[1] = "INFO") Then
;~ 		SetError(1)
;~ 		Return -1
;~ 	EndIf

	For $i = 1 To $lArrayTemp[0]
		If $i > 1 Then $lResult = $lResult & @CRLF
		$lResult = $lResult & $lArray[$i] & $lArrayTemp[$i]
	Next

	FileWriteLine($gDbgFile, @MDAY & @MON & @YEAR & " " & @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC & " - " & $lArrayTemp[1] & " - " & $lArrayTemp[2] & " - " & $lArrayTemp[3])
;~ 	FileWriteLine($gDbgFile, @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC & " - " & $lType & " - " & $lFunc & " - " & $lString)
EndFunc   ;==>_WriteDebug

#cs ; notes

	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl



#ce

