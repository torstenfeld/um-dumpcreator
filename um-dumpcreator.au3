
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

	Global $gDirTemp = @TempDir & "\dumpconfigurator"
	Global $gFileIniValuesSave = $gDirTemp & "\savedvalues.ini"

#endregion

#region ### main

	If Not FileExists($gDirTemp) Then DirCreate($gDirTemp)

	_DcMain()

#endregion

Func _DcMain()


	_RegistryGetValues()
	_DcGui()

EndFunc

Func _DcGui()

	#Region ### START Koda GUI section ### Form=
	$FormDcGui = GUICreate("Dump Configurator", 514, 376, -834, 241)
	$GroupUser = GUICtrlCreateGroup("User Mode", 8, 32, 497, 145)
	$CheckboxActivate = GUICtrlCreateCheckbox("Activate", 16, 48, 97, 17)
	GUICtrlSetState(-1, $GUI_CHECKED)
	$LabelDumpCount = GUICtrlCreateLabel("Dump count", 16, 72, 36, 17)
	$LabelDumpLocate = GUICtrlCreateLabel("Directory to store:", 16, 96, 36, 17)
	$LabelDumpType = GUICtrlCreateLabel("Type of dump:", 16, 120, 36, 17)
	$InputDumpCount = GUICtrlCreateInput("", 128, 72, 185, 21)
	$InputDumpLocate = GUICtrlCreateInput("", 128, 96, 185, 21)
	$RadioCustomDump = GUICtrlCreateRadio("Custom dump", 128, 120, 97, 17)
	$RadioMiniDump = GUICtrlCreateRadio("Mini dump", 232, 120, 97, 17)
	$RadioFullDump = GUICtrlCreateRadio("Full dump", 336, 120, 89, 17)
	$ButtonCustomDump = GUICtrlCreateButton("Custom dump", 128, 144, 75, 25, $WS_GROUP)
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
				If Not _CheckBackupIniFileValues() Then ; returns 1 if backup has already been made
					MsgBox(0, "test", "iniwritetest")
;~ 					IniWrite($gFileIniValuesSave, "backup", "true", "1")
					_SaveValuesToIniFile()
				EndIf
		EndSwitch
	WEnd

EndFunc

Func _RegistryGetValues()

	$lRegBase = $gRegBase & "\LocalDumps"
;~ 	$lRegBase = $gRegBase
;~ 	MsgBox(0, "test", "$lRegBase: " & $lRegBase)
	$gaRegUserDumpValues[0] = False

	$gaRegUserDumpValues[1] = RegRead($lRegBase, "DumpFolder")
;~ 	If @error Then MsgBox(0, "test", "error: " & @error)
	$gaRegUserDumpValues[2] = RegRead($lRegBase, "DumpCount")
	$gaRegUserDumpValues[3] = RegRead($lRegBase, "DumpType")

	If $gaRegUserDumpValues[1] <> "" Then $gaRegUserDumpValues[0] = True

;~ 	_ArrayDisplay($gaRegUserDumpValues, "$gaRegUserDumpValues")
;~ 	Exit


EndFunc

Func _SetValuesToUserDumpItems(ByRef $CheckboxActivate, ByRef $InputDumpCount, ByRef $InputDumpLocate, ByRef $RadioCustomDump, ByRef $RadioMiniDump, ByRef $RadioFullDump)

	If $gaRegUserDumpValues[0] Then
		GUICtrlSetState($CheckboxActivate, $GUI_CHECKED)
	Else
		GUICtrlSetState($CheckboxActivate, $GUI_UNCHECKED)
		Return SetError(1, 0, 0)
	EndIf

	GUICtrlSetData($InputDumpCount, $gaRegUserDumpValues[1])
	GUICtrlSetData($InputDumpLocate, $gaRegUserDumpValues[2])
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