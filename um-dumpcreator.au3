
#requireadmin

#region ### includes

	#include <ButtonConstants.au3>
	#include <EditConstants.au3>
	#include <GUIConstantsEx.au3>
	#include <StaticConstants.au3>
	#include <WindowsConstants.au3>

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

#endregion

#region ### main

	If Not FileExists($gDirTemp) Then DirCreate($gDirTemp)

	_DcMain()

#endregion

Func _DcMain()


	_RegistryGetValues()
;~ 	_ArrayDisplay($gaRegUserDumpValues, "$gaRegUserDumpValues")
	_DcGui()

EndFunc

Func _DcGui()

	#Region ### START Koda GUI section ### Form=
	$FormDcGui = GUICreate("Dump Configurator", 514, 376, -834, 241)
	$GroupUser = GUICtrlCreateGroup("User Mode", 8, 32, 497, 145)
	$CheckboxActivate = GUICtrlCreateCheckbox("Activate", 16, 48, 97, 17)
	GUICtrlSetState(-1, $GUI_CHECKED)
	$LabelDumpCount = GUICtrlCreateLabel("Dump count", 16, 72, 72, 17)
	$LabelDumpLocate = GUICtrlCreateLabel("Directory to store:", 16, 96, 72, 17)
	$LabelDumpType = GUICtrlCreateLabel("Type of dump:", 16, 120, 72, 17)
	$InputDumpCount = GUICtrlCreateInput("", 128, 72, 185, 21)
	$InputDumpLocate = GUICtrlCreateInput("", 128, 96, 185, 21)
	$RadioCustomDump = GUICtrlCreateRadio("Custom dump", 128, 120, 97, 17)
	$RadioMiniDump = GUICtrlCreateRadio("Mini dump", 232, 120, 97, 17)
	$RadioFullDump = GUICtrlCreateRadio("Full dump", 336, 120, 89, 17)
	$ButtonCustomDump = GUICtrlCreateButton("Custom dump", 128, 144, 75, 25, $WS_GROUP)
	$ButtonAvira = GUICtrlCreateButton("Avira recommendation", 264, 144, 115, 25, $WS_GROUP)
	$ButtonMicrosoft = GUICtrlCreateButton("MS recommendation", 384, 144, 115, 25, $WS_GROUP)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$GroupKernel = GUICtrlCreateGroup("Kernel mode", 8, 184, 497, 153)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$ButtonReset = GUICtrlCreateButton("Reset", 8, 344, 75, 25, $WS_GROUP)
	$ButtonCancel = GUICtrlCreateButton("Cancel", 352, 344, 75, 25, $WS_GROUP)
	$ButtonOk = GUICtrlCreateButton("Ok", 432, 344, 75, 25, $WS_GROUP)
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	_SetValuesToUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE, $ButtonCancel
				Exit
			Case $ButtonOk
				If Not _CheckBackupIniFileValues() Then _SaveValuesToIniFile() ; returns 1 if backup has already been made
				_GetValuesFromUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
				If _CompareUserDumpValues() Then
					MsgBox(262208,"Dump configurator","No value has changed.",15)
					ContinueLoop
				EndIf
				_RegistryWriteValues()
				_RegistryGetValues()
				_SetValuesToUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
			Case $ButtonAvira
				GUICtrlSetState($CheckboxActivate, $GUI_CHECKED)
				GUICtrlSetData($InputDumpCount, 10)
				If GUICtrlRead($InputDumpLocate) = "" Then GUICtrlSetData($InputDumpLocate, "%LOCALAPPDATA%\CrashDumps")
				GUICtrlSetState($RadioFullDump, $GUI_CHECKED)
			Case $ButtonMicrosoft
				GUICtrlSetState($CheckboxActivate, $GUI_CHECKED)
				GUICtrlSetData($InputDumpCount, 10)
				GUICtrlSetData($InputDumpLocate, "%LOCALAPPDATA%\CrashDumps")
				GUICtrlSetState($RadioMiniDump, $GUI_CHECKED)
			Case $ButtonReset
				_IniFileGetValues()
				_SetValuesToUserDumpItems($CheckboxActivate, $InputDumpCount, $InputDumpLocate, $RadioCustomDump, $RadioMiniDump, $RadioFullDump)
		EndSwitch
	WEnd

EndFunc

Func _RegistryGetValues()

	$lRegBase = $gRegBase & "\LocalDumps"
	$gaRegUserDumpValues[0] = False

	$gaRegUserDumpValues[1] = RegRead($lRegBase, "DumpFolder")
	$gaRegUserDumpValues[2] = RegRead($lRegBase, "DumpCount")
	$gaRegUserDumpValues[3] = RegRead($lRegBase, "DumpType")

	If $gaRegUserDumpValues[1] <> "" Then $gaRegUserDumpValues[0] = True

;~ 	_ArrayDisplay($gaRegUserDumpValues, "$gaRegUserDumpValues")
;~ 	Exit


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