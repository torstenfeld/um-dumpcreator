
#requireadmin

#region ### includes

	#include <ButtonConstants.au3>
	#include <EditConstants.au3>
	#include <GUIConstantsEx.au3>
	#include <StaticConstants.au3>
	#include <WindowsConstants.au3>
	#Include <String.au3>
	#include <INet.au3>
	#Include <Misc.au3>

	#include <Array.au3>

#endregion

#region ### global variables

	Global $gRegBase = "HKLM"
	If @OSArch = "X64" Then $gRegBase &= "64"
	$gRegBase &= "\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
	Global $gaRegUserDumpValues[4] ; active, folder, count, type
	Global $gaRegUserDumpValuesNew[4] ; active, folder, count, type

	Global $gDirTemp = @TempDir & "\dumpconfigurator"
	Global $gFileIniValuesSave = $gDirTemp & "\savedvalues.ini"

	Global $gVersion = "0.0.0.0"

#endregion

#region ### main

	If Not FileExists($gDirTemp) Then DirCreate($gDirTemp)

	_DcMain()

#endregion

Func _DcMain()

	_CheckForUpdate()
	_RegistryGetValues()
;~ 	_ArrayDisplay($gaRegUserDumpValues, "$gaRegUserDumpValues")
	_DcGui()

EndFunc

Func _DcGui()

	#Region ### START Koda GUI section ### Form=
	$FormDcGui = GUICreate("Dump Configurator", 514, 376, -834, 241)
	$GroupUser = GUICtrlCreateGroup("User Mode", 8, 32, 497, 145)
	$CheckboxActivate = GUICtrlCreateCheckbox("Activate", 16, 48, 97, 17)
	GUICtrlSetTip(-1, "(De)activate automatic creation of process dumps, if a process crashes", Default, 0, 1)
	$LabelDumpCount = GUICtrlCreateLabel("Dump count", 16, 72, 72, 17)
	$LabelDumpLocate = GUICtrlCreateLabel("Directory to store:", 16, 96, 72, 17)
	$LabelDumpType = GUICtrlCreateLabel("Type of dump:", 16, 120, 72, 17)
	$InputDumpCount = GUICtrlCreateInput("", 128, 72, 185, 21)
	GUICtrlSetTip(-1, "Sets the number of dumps which will be saved until the oldest dump will be deleted", Default, 0, 1)
	$InputDumpLocate = GUICtrlCreateInput("", 128, 96, 185, 21)
	GUICtrlSetTip(-1, "Sets the folder to which the dumps are written", Default, 0, 1)
	$RadioCustomDump = GUICtrlCreateRadio("Custom dump", 128, 120, 97, 17)
	GUICtrlSetTip(-1, "", Default, 0, 1)
	GUICtrlSetState(-1, $GUI_HIDE)
	$RadioMiniDump = GUICtrlCreateRadio("Mini dump", 232, 120, 97, 17)
	GUICtrlSetTip(-1, "Only basic information of the process itself is written to disk", Default, 0, 1)
	$RadioFullDump = GUICtrlCreateRadio("Full dump", 336, 120, 89, 17)
	GUICtrlSetTip(-1, "Whole memory of the process is written to disk", Default, 0, 1)
	$ButtonCustomDump = GUICtrlCreateButton("Custom dump", 128, 144, 75, 25, $WS_GROUP)
	GUICtrlSetTip(-1, "", Default, 0, 1)
	GUICtrlSetState(-1, $GUI_HIDE)
	$ButtonAvira = GUICtrlCreateButton("Avira recommendation", 264, 144, 115, 25, $WS_GROUP)
	GUICtrlSetTip(-1, "Setting configuration, which is recommended by Avira Userland QA", Default, 0, 1)
	$ButtonMicrosoft = GUICtrlCreateButton("MS recommendation", 384, 144, 115, 25, $WS_GROUP)
	GUICtrlSetTip(-1, "Setting configuration, which is recommended by Microsoft for daily work", Default, 0, 1)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$GroupKernel = GUICtrlCreateGroup("Kernel mode", 8, 184, 497, 153)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$ButtonReset = GUICtrlCreateButton("Reset", 8, 344, 75, 25, $WS_GROUP)
	GUICtrlSetTip(-1, "On setting a new configuration for the first time, the original config is saved for later restore", Default, 0, 1)
	$ButtonOpen = GUICtrlCreateButton("Open folder", 88, 344, 75, 25, $WS_GROUP)
	GUICtrlSetTip(-1, "Opens the folder, where dumps are saved", Default, 0, 1)
	$ButtonCancel = GUICtrlCreateButton("Cancel", 352, 344, 75, 25, $WS_GROUP)
	GUICtrlSetTip(-1, "Quits the tool", Default, 0, 1)
	$ButtonOk = GUICtrlCreateButton("Ok", 432, 344, 75, 25, $WS_GROUP)
	GUICtrlSetTip(-1, "Configuration is written to registry", Default, 0, 1)
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	If Not FileExists($gFileIniValuesSave) Then GUICtrlSetState($ButtonReset, $GUI_DISABLE)
	_SetValuesToUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)

	If GUICtrlRead($CheckboxActivate) <> $GUI_CHECKED Then _ChangeAccessUserModeDumpControl(False, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE, $ButtonCancel
				Exit
			Case $CheckboxActivate
				If GUICtrlRead($CheckboxActivate) = $GUI_CHECKED Then
					_ChangeAccessUserModeDumpControl(True, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				Else
					_ChangeAccessUserModeDumpControl(False, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				EndIf
			Case $ButtonOk
				If Not _CheckBackupIniFileValues() Then _SaveValuesToIniFile() ; returns 1 if backup has already been made
				GUICtrlSetState($ButtonReset, $GUI_ENABLE)
				_GetValuesFromUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				If _CompareUserDumpValues() Then
					MsgBox(262208,"Dump configurator","No value has changed.",15)
					ContinueLoop
				EndIf
				_RegistryWriteValues()
				_RegistryGetValues()
				_SetValuesToUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				MsgBox(64,"Dump configurator","The new configuration has been written to registry.",15)
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
					$iMsgBoxAnswer = MsgBox(52,"Dump configurator","The folder " & $lFolderDump & " does not exist. Would you like to create it now?")
					Select
						Case $iMsgBoxAnswer = 6 ;Yes
							DirCreate($lFolderDump)
							ShellExecute($lFolderDump)
;~ 						Case $iMsgBoxAnswer = 7 ;No
					EndSelect
				EndIf
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
		If @error Then MsgBox(0, "test", "RegWrite error: " & @error)
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
			MsgBox(262160,"Dump Configurator","Error in _SetValuesToUserDumpItems()" & @CRLF & @CRLF & "Weird value in $gaRegUserDumpValues[3]",10)
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

	$lVersionOnline = _INetGetSource("https://raw.github.com/torstenfeld/um-dumpcreator/registry/version.txt")
	If _VersionCompare($gVersion, $lVersionOnline) < 0 Then
		If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
		$iMsgBoxAnswer = MsgBox(4,"Dump configurator","There is a new version available. Please download it from " & @CRLF & "https://github.com/torstenfeld/um-dumpcreator/downloads" & @CRLF & @CRLF & _
			"Would you like to open the site now?", 15)
		Select
			Case $iMsgBoxAnswer = 6 ;Yes
				ShellExecuteWait("https://github.com/torstenfeld/um-dumpcreator/downloads")
				Sleep(4000)
				Exit 0
;~ 			Case $iMsgBoxAnswer = 7 ;No

		EndSelect
	EndIf



EndFunc