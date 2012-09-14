#include-once
#include <Localization.au3>
#include <WinAPI.au3>
; ------------------------------------------------------------------------------
;
; Version:        1.0.0
; AutoIt Version: 3.3.2.0
; Language:       English
; Author:         doudou
; Description:    Automated loading of localized strings from Win32 resources.
; Requirements:   WinAPI
;
; ------------------------------------------------------------------------------

Global Const $_LR_IDS_APPTITLE  = 1000

Global $_LR_RES_modules = 0

OnAutoItExitRegister("_LR_Dispose")

Func _LR_GetString($resID, $langID = $_LR_DEFAULTLANG)
    Local $result = ""
    Local $hInst = _LR_LoadStringTable(Default, $langID)
    If $hInst Then
        Local $sid = $resID
        If IsString($resID) Then $sid = Int(Eval($resID))
        $result = _WinAPI_LoadString($hInst, $sid)
    EndIf
    If 0 = StringLen($result) Then
        $langID = _LR_GetMappedLangID(_Locale_StrLangID($langID))
        ConsoleWrite("WARNING: resource not found (" & $resID & ", " & $langID & ")" & @LF)
        $result &= $resID
    EndIf
    Return $result
EndFunc ;==>_LR_GetString

Func _LR_LoadStringTable($module = Default, $langID = 0)
    Local $sLGID = _Locale_StrLangID($langID)
    If 0 = $langID Then $sLGID = _Locale_StrLangID($_LR_DEFAULTLANG)
    Local $result = Eval($_LR_STRINGTABLE_PREF & _LR_GetMappedLangID($sLGID))
    If @error Then
        $result = 0
    Else
        Return $result
    EndIf

    If Default = $module Then $module = @ScriptName
    If ".au3" = StringRight($module, 4) Or (@Compiled And ".exe" = StringRight($module, 4)) Then $module = StringLeft($module, StringLen($module) - 4)
    
    If @compiled And 0 = $langID Then $result = _WinAPI_GetModuleHandle("")
    If 0 = $result Then
        If 0 = $langID Then $langID = $_LR_DEFAULTLANG
        
        Local $pl = _Locale_GetPrimaryLangID($langID)
        For $sl = 0 To 0x20
            $sLGID = _Locale_StrLangID(_Locale_MakeLangID($pl, $sl))
            $result = Eval($_LR_STRINGTABLE_PREF & $sLGID)
            If @error Then $result = 0
            If $result Then ExitLoop
            
            $result = _LR_RES_LoadModule($module & "_" & $sLGID & ".dll")
            If $result Then ExitLoop
        Next
        
        If 0 = $result Then
            $pl = 0
            For $sl = 0 To 0x02
                $sLGID = _Locale_StrLangID(_Locale_MakeLangID($pl, $sl))
                $result = Eval($_LR_STRINGTABLE_PREF & $sLGID)
                If @error Then $result = 0
                If $result Then ExitLoop
                
                $result = _LR_RES_LoadModule($module & "_" & $sLGID & ".dll")
                If $result Then ExitLoop
            Next
        EndIf
        
        If 0 = $result Then
            $sLGID = _Locale_StrLangID($langID)
            $result = _LR_RES_LoadModule($module & ".dll")
            If 0 = $result And @compiled Then $result = _WinAPI_GetModuleHandle("")
        EndIf
    EndIf
    
    If $result Then
        Assign($_LR_STRINGTABLE_PREF & $sLGID, $result, 2)
        Assign($_LR_LGIDINDICATOR_PREF & _Locale_StrLangID($langID), $sLGID, 2)
        
        ConsoleWrite("String table " & $module & "(" & _Locale_StrLangID($langID) & ", " & $sLGID & ") loaded" & @LF)
    EndIf
    Return $result
EndFunc ;==>_LR_LoadStringTable

Func _LR_Dispose()
    If IsArray($_LR_RES_modules) Then
        ConsoleWrite("Disposing " & UBound($_LR_RES_modules) & " resource(s)" & @LF)
        For $i = 0 To UBound($_LR_RES_modules) - 1
            _WinAPI_FreeLibrary($_LR_RES_modules[$i])
        Next
    EndIf
    $_LR_RES_modules = 0
EndFunc ;==>_LR_Dispose

Func _LR_RES_LoadModule($moduleFile)
    Local $result = _WinAPI_GetModuleHandle($moduleFile)
    If $result Then Return $result
    
    $result = _WinAPI_LoadLibrary($moduleFile)
    If 0 = $result Then $result = _WinAPI_LoadLibrary(@ScriptDir & "\" & $moduleFile)
    If $result Then
        If IsArray($_LR_RES_modules) Then
            ReDim $_LR_RES_modules[UBound($_LR_RES_modules) + 1]
        Else
            Dim $_LR_RES_modules[1]
        EndIf
        $_LR_RES_modules[UBound($_LR_RES_modules) - 1] = $result
    EndIf
    Return $result
EndFunc ;==>_LR_RES_LoadModule