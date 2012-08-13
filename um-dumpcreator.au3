#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=favicon.ico
#AutoIt3Wrapper_Outfile=dumpconfigurator-1.0.0.12-x86.exe
#AutoIt3Wrapper_Outfile_x64=dumpconfigurator-1.0.0.12-x64.exe
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=Sets registry settings for automatic creation of user dumps
#AutoIt3Wrapper_Res_Description=Sets registry settings for automatic creation of user dumps
#AutoIt3Wrapper_Res_Fileversion=1.0.0.13
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_LegalCopyright=Copyright © 2011 Torsten Feld - All rights reserved.
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****


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
	Global $gDirUserManualDump
	Global $gFileIniValuesSave = $gDirTemp & "\savedvalues.ini"

	Global $gUrlDownloadTool = "https://github.com/torstenfeld/um-dumpcreator/downloads"

	Global $gVersion
	Global $gTitleMsgBox = "Dump configurator"

	Global $gaProcesses
	Global $gPreVista = False
	Global $gInstalledDebuggingTools
	Global $gDirDebuggingTools

	Global $pos1 = MouseGetPos()
	Global $pos2 = MouseGetPos() ; must be initialized
	Global $appHandle = 0

	Global $gProcess
	Global $gProcCmdLine
	Global $gToolTipTxt
	Global $gProcessCrashed

	Global $ComboProcesses

#endregion

#region ### main

;~ 	AutoItSetOption("MustDeclareVars", 1)
	AutoItSetOption("MouseCoordMode", 1)

	If Not FileExists($gDirTemp) Then DirCreate($gDirTemp)

	_DcMain()

#endregion

Func _DcMain()


	_ArchCheck()

	If @Compiled Then
		$gVersion = FileGetVersion(@ScriptFullPath, "FileVersion")
		If @error Then $gVersion = "0.0.0.0"
	Else
		$gVersion = "9.99.99.99 - not compiled"
	EndIf

	_CheckForUpdate()

	_DebugToolsMain()
	_DebugToolsGetInstallFolder()

	_ProcessGetList()

	_OsCheckPreVista() ;test
;~ 	$gPreVista = True ;test

	_RegistryGetValues()
;~ 	_ArrayDisplay($gaRegUserDumpValues, "$gaRegUserDumpValues")
	_DcGui()

EndFunc

Func _ArchCheck()

	If Not @Compiled Then Return 0

	Local $lMsgBoxText = ""

	Switch @OSArch
		Case "X64"
			If Not @AutoItX64 Then $lMsgBoxText = "The architecture of your OS (" & @OSArch & ") does not match with the architecture of this tool (X86)." & @CRLF
		Case "X86"
			If @AutoItX64 Then $lMsgBoxText = "The architecture of your OS (" & @OSArch & ") does not match with the architecture of this tool (X64)." & @CRLF
	EndSwitch

	If $lMsgBoxText = "" Then Return 1

	Local $iMsgBoxAnswer = MsgBox(52,$gTitleMsgBox, $lMsgBoxText & "Please download the correct version from " & @CRLF & $gUrlDownloadTool & @CRLF & @CRLF & _
	"Would you like to open the site now?", 15)
	Select
		Case $iMsgBoxAnswer = 6 ;Yes
			ShellExecuteWait($gUrlDownloadTool)
			Sleep(4000)
			Exit 0
		Case $iMsgBoxAnswer = 7 ;No
			Exit 1

	EndSelect

EndFunc

Func _OsCheckPreVista()

	Switch @OSVersion
		Case "WIN_XP", "WIN_XPe", "WIN_2000"
;~ 			MsgBox(16,"Dump configurator","Unfortunately, Microsoft Windows below Vista is currently not supported. " & @CRLF & _
;~ 				"Support for those Operating Systems (especially Windows XP) will be added as soon as possible. " & @CRLF & @CRLF & _
;~ 				"Visit https://github.com/torstenfeld/um-dumpcreator for latest news.")
;~ 			Exit 2
			$gPreVista = True
		Case "WIN_2008R2", "WIN_7", "WIN_8", "WIN_2008", "WIN_VISTA", "WIN_2003"
			$gPreVista = False
		Case Else
			MsgBox(16,$gTitleMsgBox,"Unfortunately, the Operating System you are using currently not supported. " & @CRLF & _
				"Please write an email to torsten@torsten-feld.de with the following information:" & @CRLF & _
				@OSVersion & " / " & @OSBuild & " / " & @OSServicePack & @CRLF & @CRLF & _
				"Visit https://github.com/torstenfeld/um-dumpcreator for latest news.")

	EndSwitch

EndFunc

Func _DcGui()

	Local $lChButtonActive = False

	#Region ### START Koda GUI section ### Form=
	$FormDcGui = GUICreate($gTitleMsgBox & " - v" & $gVersion, 527, 474, 214, 131)
	$ButtonCancel = GUICtrlCreateButton("Cancel", 440, 440, 75, 25)
	GUICtrlSetTip(-1, "Quits the tool")
	$Tab1 = GUICtrlCreateTab(8, 32, 513, 401)
	$TabUserMode = GUICtrlCreateTabItem("User mode")
	$GroupUserAutomatic = GUICtrlCreateGroup("User Mode Automatic", 16, 60, 497, 193)
	$CheckboxActivate = GUICtrlCreateCheckbox("Activate", 24, 76, 97, 17)
	GUICtrlSetTip(-1, "(De)activate automatic creation of process dumps, if a process crashes")
	$LabelDumpCount = GUICtrlCreateLabel("Dump count", 24, 100, 72, 17)
	$LabelDumpLocate = GUICtrlCreateLabel("Directory to store:", 24, 132, 72, 17)
	$LabelDumpType = GUICtrlCreateLabel("Type of dump:", 24, 164, 72, 17)
	$InputDumpCount = GUICtrlCreateInput("", 136, 100, 185, 21)
	GUICtrlSetTip(-1, "Sets the number of dumps which will be saved until the oldest dump will be deleted")
	$InputDumpLocate = GUICtrlCreateInput("", 136, 132, 185, 21)
	GUICtrlSetTip(-1, "Sets the folder to which the dumps are written")
	$RadioCustomDump = GUICtrlCreateRadio("Custom dump", 136, 164, 97, 17)
	GUICtrlSetState(-1, $GUI_HIDE)
	$RadioMiniDump = GUICtrlCreateRadio("Mini dump", 240, 164, 97, 17)
	GUICtrlSetTip(-1, "Only basic information of the process itself is written to disk")
	$RadioFullDump = GUICtrlCreateRadio("Full dump", 344, 164, 89, 17)
	GUICtrlSetTip(-1, "Whole memory of the process is written to disk")
	$ButtonCustomDump = GUICtrlCreateButton("Custom dump", 136, 188, 75, 25)
	GUICtrlSetState(-1, $GUI_HIDE)
	$ButtonAvira = GUICtrlCreateButton("Extended", 392, 188, 115, 25)
	GUICtrlSetTip(-1, "Setting configuration, which is recommended to collect data for troubleshooting")
	$ButtonMicrosoft = GUICtrlCreateButton("Microsoft", 272, 188, 115, 25)
	GUICtrlSetTip(-1, "Setting configuration, which is recommended by Microsoft for daily work")
	$ButtonUserABrowse = GUICtrlCreateButton("Browse", 368, 132, 75, 25)
	$ButtonSave = GUICtrlCreateButton("Save", 432, 220, 75, 25)
	GUICtrlSetTip(-1, "Configuration is written to registry")
	$ButtonReset = GUICtrlCreateButton("Reset", 136, 220, 75, 25)
	GUICtrlSetTip(-1, "On setting a new configuration for the first time, the original config is saved for later restore")
	$ButtonOpen = GUICtrlCreateButton("Open folder", 216, 220, 75, 25)
	GUICtrlSetTip(-1, "Opens the folder, where dumps are saved")

	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$GroupUserManual = GUICtrlCreateGroup("User Mode Manual", 16, 260, 497, 161)
	$Label1 = GUICtrlCreateLabel("Choose Process:", 24, 284, 84, 17)
	$ComboProcesses = GUICtrlCreateCombo("", 136, 284, 217, 25)
	$ButtonRefresh = GUICtrlCreateButton("Refresh", 368, 284, 75, 25)
	GUICtrlSetTip(-1, "Refresh the process list")
	$ButtonCrosshair = GUICtrlCreateButton("", 480, 284, 25, 25)
	GUICtrlSetTip(-1, "Click to get process by windows")
	$Label2 = GUICtrlCreateLabel("Type of dump:", 24, 348, 72, 17)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$RadioUserCrash = GUICtrlCreateRadio("Crash", 136, 348, 89, 17)
	GUICtrlSetTip(-1, "Select if you would like to get a dump of a crashed process")
	GUICtrlSetState(-1, $GUI_CHECKED)
	$RadioUserHang = GUICtrlCreateRadio("Hang", 232, 348, 113, 17)
	GUICtrlSetTip(-1, "Select if you would like to get a dump of a hanging process")
	$Label3 = GUICtrlCreateLabel("Dump location:", 24, 316, 75, 17)
	$InputUserLocation = GUICtrlCreateInput("", 136, 316, 185, 21)
	GUICtrlSetTip(-1, "Specify the folder where the dumps should be saved")
	$ButtonUserBrowse = GUICtrlCreateButton("Browse", 368, 316, 75, 25)
	GUICtrlSetTip(-1, "Click to browse for the folder where the dumps should be saved")
	$Label4 = GUICtrlCreateLabel("Process existing:", 24, 380, 83, 17)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$RadioProcessExists = GUICtrlCreateRadio("Existing", 136, 380, 89, 17)
	GUICtrlSetState(-1, $GUI_CHECKED)
	GUICtrlSetTip(-1, "Select if the process has already crashed")
	$RadioProcessWaiting = GUICtrlCreateRadio("Waiting for", 232, 380, 113, 17)
	GUICtrlSetTip(-1, "Select if the process is currently not running")
	$ButtonUserCreateDump = GUICtrlCreateButton("Create dump", 368, 380, 75, 25)
	GUICtrlSetTip(-1, "Click to start dump creation")

	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$TabKernelMode = GUICtrlCreateTabItem("Kernel mode")
	GUICtrlCreateTabItem("")
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###


	If Not FileExists($gFileIniValuesSave) Then GUICtrlSetState($ButtonReset, $GUI_DISABLE)
	_SetValuesToUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)

	If GUICtrlRead($CheckboxActivate) <> $GUI_CHECKED Then _ChangeAccessUserModeDumpControl(False, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)

	If $gPreVista Then
		_ChangeAccessUserModeDumpControl(False, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
		GUICtrlSetState($CheckboxActivate, $GUI_DISABLE)
		GUICtrlSetState($ButtonAvira, $GUI_DISABLE)
		GUICtrlSetState($ButtonMicrosoft, $GUI_DISABLE)
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
	Else
		_GuiComboProcessFill()
	EndIf

	GUICtrlSetData($InputUserLocation, IniRead($gFileIniValuesSave, "UserModeManual", "DumpLocation", ""))

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE, $ButtonCancel
				Exit
			Case $ButtonCrosshair
				If $lChButtonActive Then
					AdlibUnRegister("_Mouse_Control_GetInfoAdlib")
					ToolTip("")
					$lChButtonActive = False
				Else
					_ProcessGetList()
					_GuiComboProcessFill()
					AdlibRegister("_Mouse_Control_GetInfoAdlib", 10)
					$lChButtonActive = True
				EndIf
			Case $ButtonRefresh
				_ProcessGetList()
				_GuiComboProcessFill()
			Case $CheckboxActivate
				If GUICtrlRead($CheckboxActivate) = $GUI_CHECKED Then
					_ChangeAccessUserModeDumpControl(True, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				Else
					_ChangeAccessUserModeDumpControl(False, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				EndIf
			Case $ButtonSave
				If Not _CheckBackupIniFileValues() Then _SaveValuesToIniFile() ; returns 1 if backup has already been made
				GUICtrlSetState($ButtonReset, $GUI_ENABLE)
				_GetValuesFromUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				If _CompareUserDumpValues() Then
					MsgBox(262208,$gTitleMsgBox,"No value has changed.",15)
					ContinueLoop
				EndIf
				_RegistryWriteValues()
				_RegistryGetValues()
				_SetValuesToUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				MsgBox(64,$gTitleMsgBox,"The new configuration has been written to registry.",15)
			Case $ButtonUserABrowse
				$lFolderDump = GUICtrlRead($InputDumpLocate)
				If StringInStr($lFolderDump, "%") Then
					$lTempStringBetweenResult = StringRegExpReplace($lFolderDump, ".*\%(.*)\%.*", "$1")
					$lFolderDump = StringReplace($lFolderDump, "%" & $lTempStringBetweenResult & "%", EnvGet($lTempStringBetweenResult))
				EndIf
				If Not FileExists($lFolderDump) Then $lFolderDump = @ScriptDir
				$lFolderDump = FileSelectFolder("Please choose a directoy to store the dumps", "", 7, $lFolderDump, $FormDcGui)
				If @error Then ContinueLoop
				GUICtrlSetData($InputDumpLocate, $lFolderDump)
			Case $ButtonAvira
				GUICtrlSetState($CheckboxActivate, $GUI_CHECKED)
				GUICtrlSetData($InputDumpCount, 10)
				If GUICtrlRead($InputDumpLocate) = "" Then GUICtrlSetData($InputDumpLocate, "%LOCALAPPDATA%\CrashDumps")
				GUICtrlSetState($RadioFullDump, $GUI_CHECKED)
				_ChangeAccessUserModeDumpControl(True, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
			Case $ButtonMicrosoft
				GUICtrlSetState($CheckboxActivate, $GUI_CHECKED)
				GUICtrlSetData($InputDumpCount, 10)
				GUICtrlSetData($InputDumpLocate, "%LOCALAPPDATA%\CrashDumps")
				GUICtrlSetState($RadioMiniDump, $GUI_CHECKED)
				_ChangeAccessUserModeDumpControl(True, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
			Case $ButtonReset
				_IniFileGetValues()
				_SetValuesToUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				_RegistryGetValues()
			Case $ButtonOpen
				$lFolderDump = GUICtrlRead($InputDumpLocate)
				If StringInStr($lFolderDump, "%") Then
					$lTempStringBetweenResult = StringRegExpReplace($lFolderDump, ".*\%(.*)\%.*", "$1")
					$lFolderDump = StringReplace($lFolderDump, "%" & $lTempStringBetweenResult & "%", EnvGet($lTempStringBetweenResult))
				EndIf
				If FileExists($lFolderDump) Then
					ShellExecute($lFolderDump)
				Else
					If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
					$iMsgBoxAnswer = MsgBox(52,$gTitleMsgBox,"The folder " & $lFolderDump & " does not exist. Would you like to create it now?")
					Select
						Case $iMsgBoxAnswer = 6 ;Yes
							DirCreate($lFolderDump)
							ShellExecute($lFolderDump)
;~ 						Case $iMsgBoxAnswer = 7 ;No
					EndSelect
				EndIf
			Case $ButtonUserBrowse
				$gDirUserManualDump = GUICtrlRead($InputUserLocation)
				If Not FileExists($gDirUserManualDump) Then $gDirUserManualDump = @ScriptDir
				$gDirUserManualDump = FileSelectFolder("Please choose a directoy to store the dumps", "", 7, $gDirUserManualDump, $FormDcGui)
				If @error Then ContinueLoop
				GUICtrlSetData($InputUserLocation, $gDirUserManualDump)
			Case $ButtonUserCreateDump
				IniWrite($gFileIniValuesSave, "UserModeManual", "DumpLocation", GUICtrlRead($InputUserLocation))
				If GUICtrlRead($ComboProcesses) = "" Then
					If GUICtrlRead($RadioProcessExists) = $GUI_CHECKED Then
						MsgBox(0, $gTitleMsgBox, "error") ;test
						ContinueLoop
					EndIf
				EndIf
				If Not FileExists(GUICtrlRead($InputUserLocation)) Then
					MsgBox(0, $gTitleMsgBox, "error") ;test
					ContinueLoop
				EndIf
				Local $lFileAdPlus = $gDirDebuggingTools & "\adplus.exe"

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
							MsgBox(0, $gTitleMsgBox, "InputBox error: " & @error) ;test
							ContinueLoop
					EndSwitch
				EndIf
				 $lAdPlusParameters &= ' -o "' & GUICtrlRead($InputUserLocation) & _
					'" -FullOnFirst -lcqd'
;~ 					'" -FullOnFirst -CTCFB'

;~ 				Run(@ComSpec & ' /c ' & FileGetShortName($lFileAdPlus) & $lAdPlusParameters);, @SW_HIDE)
				Local $lOutputRun = Run(FileGetShortName($lFileAdPlus) & $lAdPlusParameters);, @SW_MAXIMIZE, $STDERR_CHILD + $STDOUT_CHILD)

				If GUICtrlRead($RadioProcessWaiting) = $GUI_CHECKED Then MsgBox(64,$gTitleMsgBox,"After the crash occured, please close the crashed window and close the DOS box which just opened with <ENTER>.",10)

				ProcessWaitClose("adplus.exe")
				MsgBox(0, $gTitleMsgBox, "Dump has been created") ;test
			Case $RadioProcessWaiting
				GUICtrlSetState($ComboProcesses, $GUI_DISABLE)
			Case $RadioProcessExists
				GUICtrlSetState($ComboProcesses, $GUI_ENABLE)

		EndSwitch
	WEnd

EndFunc

Func _ChangeAccessUserModeDumpControl($lActivate, ByRef $InputDumpCount, ByRef $InputDumpLocate, ByRef $RadioCustomDump, ByRef $RadioMiniDump, ByRef $RadioFullDump)

	If $lActivate Then
		GUICtrlSetState($InputDumpCount, $GUI_ENABLE)
		GUICtrlSetState($InputDumpLocate, $GUI_ENABLE)
		GUICtrlSetState($RadioMiniDump, $GUI_ENABLE)
		GUICtrlSetState($RadioFullDump, $GUI_ENABLE)
	Else
		GUICtrlSetState($InputDumpCount, $GUI_DISABLE)
		GUICtrlSetState($InputDumpLocate, $GUI_DISABLE)
		GUICtrlSetState($RadioMiniDump, $GUI_DISABLE)
		GUICtrlSetState($RadioFullDump, $GUI_DISABLE)
	EndIf
EndFunc

Func _ProcessGetList()

	$gaProcesses = ProcessList()
	If $gaProcesses[0][0] = 0 Then Return SetError(1, 0, 1)
	_ArraySort($gaProcesses, 0, 1)

EndFunc

Func _GuiComboProcessFill()
	_GUICtrlComboBox_ResetContent($ComboProcesses)
	_GUICtrlComboBox_BeginUpdate($ComboProcesses)
	For $i = 1 To $gaProcesses[0][0]
		_GUICtrlComboBox_AddString($ComboProcesses, $gaProcesses[$i][0] & " (" & $gaProcesses[$i][1] & ")")
	Next
	_GUICtrlComboBox_EndUpdate($ComboProcesses)

EndFunc

Func _ProcessGetExe($lHandle) ; returns process executable

	Local $lPid = WinGetProcess($lHandle)
	Local $lArrayResult = _ArraySearch($gaProcesses, $lPid, 0, 0, 0, 0, 1, 1)
	If @error Then
		_ProcessGetList()
		_GuiComboProcessFill()
		$lArrayResult = _ArraySearch($gaProcesses, $lPid, 0, 0, 0, 0, 1, 1)
	EndIf
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

	$lRegBase = $gRegBase & "\LocalDumps"
	$gaRegUserDumpValues[0] = False

	$gaRegUserDumpValues[1] = RegRead($lRegBase, "DumpFolder")
	$gaRegUserDumpValues[2] = RegRead($lRegBase, "DumpCount")
	$gaRegUserDumpValues[3] = RegRead($lRegBase, "DumpType")

	If $gaRegUserDumpValues[1] <> "" Then $gaRegUserDumpValues[0] = True

EndFunc

Func _RegistryWriteValues()

	$lRegBase = $gRegBase & "\LocalDumps"
;~ 	_ArrayDisplay($gaRegUserDumpValuesNew, "$gaRegUserDumpValuesNew")

	If $gaRegUserDumpValuesNew[0] = True Then
		RegWrite($lRegBase, "DumpFolder", "REG_EXPAND_SZ", $gaRegUserDumpValuesNew[1])
		If @error Then MsgBox(0, $gTitleMsgBox, "RegWrite error: " & @error) ;test
		RegWrite($lRegBase, "DumpCount", "REG_DWORD", $gaRegUserDumpValuesNew[2])
		RegWrite($lRegBase, "DumpType", "REG_DWORD", $gaRegUserDumpValuesNew[3])
	Else
		RegDelete($lRegBase, "DumpFolder")
		RegDelete($lRegBase, "DumpCount")
		RegDelete($lRegBase, "DumpType")
	EndIf

EndFunc

Func _IniFileGetValues()

	$gaRegUserDumpValues[0] = IniRead($gFileIniValuesSave, "values", "active", "")
	If $gaRegUserDumpValues[0] = "" Then Return SetError(1, 0, 0)

	$gaRegUserDumpValues[1] = IniRead($gFileIniValuesSave, "values", "folder", "")
	$gaRegUserDumpValues[2] = IniRead($gFileIniValuesSave, "values", "count", "")
	$gaRegUserDumpValues[3] = IniRead($gFileIniValuesSave, "values", "type", "")

EndFunc

Func _DebugToolsMain()

	If _DebugToolsCheckInstalled() Then
;~ 		MsgBox(64, "Dump Configurator", "Windows Debugging Tools are already installed. Skipping installation.") ;test
		$gInstalledDebuggingTools = True
		Return 1
	Else
		If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
		$iMsgBoxAnswer = MsgBox(36,$gTitleMsgBox,"Windows Debugging Tools are not installed, which are needed for user dump creation. " & @CRLF & "Would you like to install Windows Debugging Tools now?")
		Select
;~ 			Case $iMsgBoxAnswer = 6 ;Yes
			Case $iMsgBoxAnswer = 7 ;No
				$gInstalledDebuggingTools = False
				Return SetError(1, 0, 0)
		EndSelect
	EndIf
	Local $lMsiToInstall = _DebugToolsDownload()
	If _DebugToolsInstall($lMsiToInstall) Then
		$gInstalledDebuggingTools = True
	Else
		$gInstalledDebuggingTools = False
	EndIf

EndFunc

Func _DebugToolsCheckInstalled() ; returns 1 if installed

	Local $lRegUninstallBase = "HKLM"
	If @OSArch = "X64" Then $lRegUninstallBase &= "64"
	$lRegUninstallBase &= "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"

	Local $lDbgToolsFound = 0
	Local $lRegSubKey, $lRegValue

	For $i = 1 To 9999999999
		$lRegSubKey = RegEnumKey($lRegUninstallBase, $i)
		If @error <> 0 Then ExitLoop
		$lRegValue = RegRead($lRegUninstallBase & $lRegSubKey, "DisplayName")
		If StringInStr($lRegValue, "Debugging Tools for Windows") Then
			$lDbgToolsFound = 1
			ExitLoop
		EndIf
	Next

	Return $lDbgToolsFound

EndFunc

Func _DebugToolsDownload() ; returns filename if file was successfully loaded and sets error if not

	Local $lDownloadSuccess = 0
	Local $lDbtUrlBase = "https://github.com/downloads/torstenfeld/um-dumpcreator/"
	Local $lDbtUrlFile = "dbg_"
	Switch @OSArch
		Case "X64"
			$lDbtUrlFile &= "amd64.msi"
		Case "X86"
			$lDbtUrlFile &= "x86.msi"
		Case "IA64"
			$lDbtUrlFile &= "ia64.msi"
		Case Else
			MsgBox(16,$gTitleMsgBox,"Your OS architecture is not supported. " & @CRLF & "Windows Debugging Tools will not be installed.",15)
			Return SetError(1, 0, 0)
	EndSwitch

	Local $lhDownload = InetGet($lDbtUrlBase & $lDbtUrlFile, $gDirTemp & "\" & $lDbtUrlFile, 27, 1)
	Local $lDownloadTotalSize = InetGetSize($lDbtUrlBase & $lDbtUrlFile, 11) / 1024
	Local $lDownloadCurrentSize = InetGetInfo($lhDownload, 0) / 1024
	Local $lDownloadPerCent
	ProgressOn($gTitleMsgBox, "Loading: " & $lDownloadCurrentSize & " \ " & $lDownloadTotalSize & " kBytes", $lDbtUrlBase & $lDbtUrlFile)
	Do
		$lDownloadCurrentSize = InetGetInfo($lhDownload, 0) / 1024
		$lDownloadPerCent = StringFormat("%.0i", ($lDownloadCurrentSize / $lDownloadTotalSize) * 100)
		ProgressSet($lDownloadPerCent, $lDownloadPerCent & " percent", "Loading: " & $lDownloadCurrentSize & " \ " & $lDownloadTotalSize & " kBytes")
		Sleep(100)
	Until InetGetInfo($lhDownload, 2)
	InetClose($lhDownload) ; Close the handle to release resources.
;~ 	ProgressSet(100, "Done", "Complete")
	Sleep(500)
	ProgressOff()

	If FileExists($gDirTemp & "\" & $lDbtUrlFile) Then
		Local $lFileSizeLocally = FileGetSize($gDirTemp & "\" & $lDbtUrlFile)
		If ($lFileSizeLocally / 1024) = $lDownloadTotalSize Then
			MsgBox(64,$gTitleMsgBox,"Download of Windows Debugging Tools successfull.")
			Return $gDirTemp & "\" & $lDbtUrlFile
		Else
			MsgBox(16,$gTitleMsgBox,"Download of Windows Debugging Tools was not completed.")
			Return SetError(2, 0, 0)
		EndIf
	Else
		MsgBox(16,$gTitleMsgBox,"Download of Windows Debugging Tools failed.")
		Return SetError(3, 0, 0)
	EndIf

EndFunc

Func _DebugToolsInstall($lMsiToInstall) ; returns 1 if install was successfull

	RunWait(@ComSpec & " /c " & $lMsiToInstall & " /qn /lv* " & $gDirTemp & "\windbgt-install.log", "", @SW_HIDE)

	Sleep(2000)

	If _DebugToolsCheckInstalled() Then
		MsgBox(64,$gTitleMsgBox,"Installation of Windows Debugging Tools finished successfully.",15)
		Return 1
	Else
		MsgBox(64,$gTitleMsgBox,"Installation of Windows Debugging Tools failed.",15)
		Return SetError(1, 0, 0)
	EndIf

EndFunc

Func _DebugToolsGetInstallFolder()

	If Not $gInstalledDebuggingTools Then Return SetError(2, 0, 0)

	Local $laFolders = _FileListToArray(@ProgramFilesDir, "*", 2)
;~ 	_ArrayDisplay($laFolders, "$laFolders") ;test
	$lArrayIndex = _ArraySearch($laFolders, "Debugging Tools for Windows", 1, 0, 0, 1)
	If @error Then
		$gDirDebuggingTools = IniRead($gFileIniValuesSave, "UserModeManual", "WdtPath", "")
		If $gDirDebuggingTools <> "" Then Return 1

		$gDirDebuggingTools = FileSelectFolder("Windows Debugging Tools installation folder could not be found. Please choose folder by yourself.", "", 6, @ProgramFilesDir)
		If @error Then
			$gInstalledDebuggingTools = false
			Return SetError(1, 0, 0)
		EndIf
		If Not FileExists($gDirDebuggingTools & "\adplus.exe") Or Not FileExists($gDirDebuggingTools & "\cdb.exe") Then
			MsgBox(16,$gTitleMsgBox,"The directory you entered seems not to be a valid Debugging Tools for Windows installation folder.")
			$gInstalledDebuggingTools = false
			Return SetError(2, 0, 0)
		Else
			IniWrite($gFileIniValuesSave, "UserModeManual", "WdtPath", $gDirDebuggingTools)
		EndIf
	Else
		$gDirDebuggingTools = @ProgramFilesDir & "\" & $laFolders[$lArrayIndex]
	EndIf

EndFunc

Func _GetValuesFromUserDumpItems(ByRef $CheckboxActivate, ByRef $InputDumpCount, ByRef $InputDumpLocate, ByRef $RadioCustomDump, ByRef $RadioMiniDump, ByRef $RadioFullDump)

	If GUICtrlRead($CheckboxActivate) = $GUI_UNCHECKED Then
		$gaRegUserDumpValuesNew[0] = False
		Return 0
	Else
		$gaRegUserDumpValuesNew[0] = True
	EndIf

	$gaRegUserDumpValuesNew[1] = GUICtrlRead($InputDumpLocate)
	$gaRegUserDumpValuesNew[2] = GUICtrlRead($InputDumpCount)

	If GUICtrlRead($RadioCustomDump) = $GUI_CHECKED Then $gaRegUserDumpValuesNew[3] = 0
	If GUICtrlRead($RadioMiniDump) =  $GUI_CHECKED Then $gaRegUserDumpValuesNew[3] = 1
	If GUICtrlRead($RadioFullDump) =  $GUI_CHECKED Then $gaRegUserDumpValuesNew[3] = 2

EndFunc

Func _CompareUserDumpValues() ; returns 1 if all values are the same

	For $i = 0 To UBound($gaRegUserDumpValues)-1
		If $gaRegUserDumpValues[$i] <> $gaRegUserDumpValuesNew[$i] Then Return 0
	Next

	Return 1

EndFunc

Func _SetValuesToUserDumpItems(ByRef $CheckboxActivate, ByRef $InputDumpCount, ByRef $InputDumpLocate, ByRef $RadioCustomDump, ByRef $RadioMiniDump, ByRef $RadioFullDump)

	If $gaRegUserDumpValues[0] Then
		GUICtrlSetState($CheckboxActivate, $GUI_CHECKED)
	Else
		GUICtrlSetState($CheckboxActivate, $GUI_UNCHECKED)
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
			Exit(1)

	EndSwitch

EndFunc

Func _SaveValuesToIniFile()

	IniWrite($gFileIniValuesSave, "values", "active", $gaRegUserDumpValues[0])
	IniWrite($gFileIniValuesSave, "values", "folder", $gaRegUserDumpValues[1])
	IniWrite($gFileIniValuesSave, "values", "count", $gaRegUserDumpValues[2])
	IniWrite($gFileIniValuesSave, "values", "type", $gaRegUserDumpValues[3])

EndFunc

Func _CheckBackupIniFileValues() ; returns 1 if backup has already been made

	If Not FileExists($gFileIniValuesSave) Then Return 0

	If IniRead($gFileIniValuesSave, "values", "folder", "")  = "" Then Return 0
	If IniRead($gFileIniValuesSave, "values", "count", "")  = "" Then Return 0
	If IniRead($gFileIniValuesSave, "values", "type", "")  = "" Then Return 0

	Return 1
EndFunc

Func _CheckForUpdate()

	$lVersionOnline = _INetGetSource("https://raw.github.com/torstenfeld/um-dumpcreator/master/version.txt")
	If _VersionCompare($gVersion, $lVersionOnline) < 0 Then
		If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
		$iMsgBoxAnswer = MsgBox(4,$gTitleMsgBox,"There is a new version available. Please download it from " & @CRLF & $gUrlDownloadTool & @CRLF & @CRLF & _
			"Would you like to open the site now?", 15)
		Select
			Case $iMsgBoxAnswer = 6 ;Yes
				ShellExecuteWait($gUrlDownloadTool)
				Sleep(4000)
				Exit 0
;~ 			Case $iMsgBoxAnswer = 7 ;No

		EndSelect
	EndIf

EndFunc

#cs ; notes

	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl



#ce

