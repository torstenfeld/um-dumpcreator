

#region ### includes

	#include <ButtonConstants.au3>
	#include <EditConstants.au3>
	#include <GUIConstantsEx.au3>
	#include <StaticConstants.au3>
	#include <WindowsConstants.au3>

#endregion

#region ### main

	_DcMain()

#endregion

Func _DcMain()

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
	$Input1 = GUICtrlCreateInput("", 128, 72, 185, 21)
	$Input2 = GUICtrlCreateInput("", 128, 96, 185, 21)
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

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE, $ButtonCancel
				Exit

		EndSwitch
	WEnd




EndFunc