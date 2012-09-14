#include-once
#include <Localization.au3>
; ------------------------------------------------------------------------------
;
; Version:        1.0.0
; AutoIt Version: 3.3.2.0
; Language:       English
; Author:         doudou
; Description:    Automated loading of localized strings from INI files.
;
; ------------------------------------------------------------------------------

Global Const $_LR_IDS_APPTITLE  = $_LR_RESID_PREF & "AppTitle"

Func _LR_GetString($resID, $langID = $_LR_DEFAULTLANG)
    Local $result = ""
    $langID = _LR_GetMappedLangID(_Locale_StrLangID($langID))
    
    Local $tname = $_LR_STRINGTABLE_PREF & $langID
    If Not IsDeclared($tname) Then
        _LR_LoadStringTable(Default, $langID)
        $langID = _LR_GetMappedLangID(_Locale_StrLangID($langID))
        $tname = $_LR_STRINGTABLE_PREF & $langID
    EndIf
    
    If IsNumber($resID) Then
        $result = Execute("$" & $tname & "[" & Int($resID) & "][1]")
    Else
        Local $resName = $tname & "_" & $resID
        If IsDeclared($resName) Then
            $result = Eval($resName)
        Else
            Local $t = Eval($tname)
            If IsArray($t) Then
                For $i = 1 to $t[0][0]
                    If $t[$i][0] == $resID Then
                        $result = $t[$i][1]
                        ExitLoop
                    EndIf
                Next
                If 0 < StringLen($result) Then Assign($resName, $result, 2)
            EndIf
        EndIf
    EndIf
    
    If 0 = StringLen($result) Then
        ConsoleWrite("WARNING: resource not found (" & $resID & ", " & $langID & ")" & @CRLF)
        $result &= $resID
    EndIf
    Return $result
EndFunc ;==>_LR_GetString

Func _LR_LoadStringTable($module = Default, $langID = $_LR_DEFAULTLANG)
    Local $sLGID = _Locale_StrLangID($langID)
    If IsArray(Eval($_LR_STRINGTABLE_PREF & _LR_GetMappedLangID($sLGID))) Then Return True
    

    If Default = $module Then $module = @ScriptName
    If ".au3" = StringRight($module, 4) Or (@Compiled And ".exe" = StringRight($module, 4)) Then $module = StringLeft($module, StringLen($module) - 4)
    
    Local $moduleFile = $module & "_StringTable.ini"
    Local $secs = IniReadSectionNames($moduleFile)
    If @error Then
        $moduleFile = @ScriptDir & "\" & $module & "_StringTable.ini"
        $secs = IniReadSectionNames($moduleFile)
    EndIf
    If @error Then Return False
    
    Local $t = IniReadSection($moduleFile, $sLGID)
    If @error Then
        Local $pl = _Locale_GetPrimaryLangID($langID)
        For $sl = 0 To 0x20
            $sLGID = _Locale_StrLangID(_Locale_MakeLangID($pl, $sl))
            $t = Eval($_LR_STRINGTABLE_PREF & $sLGID)
            If IsArray($t) Then ExitLoop
            
            $t = IniReadSection($moduleFile, $sLGID)
            If 0 = @error Then ExitLoop
        Next
    EndIf
    
    If Not IsArray($t) Then
        Local $pl = 0
        For $sl = 0 To 0x02
            $sLGID = _Locale_StrLangID(_Locale_MakeLangID($pl, $sl))
            $t = Eval($_LR_STRINGTABLE_PREF & $sLGID)
            If IsArray($t) Then ExitLoop
            
            $t = IniReadSection($moduleFile, $sLGID)
            If 0 = @error Then ExitLoop
        Next
    EndIf
    
    If Not IsArray($t) Then
        If IsArray($secs) And 0 < $secs[0] Then
            $sLGID = $secs[1]
            $t = Eval($_LR_STRINGTABLE_PREF & $sLGID)
            If Not IsArray($t) Then $t = IniReadSection($moduleFile, $sLGID)
        EndIf
    EndIf
    
    If IsArray($t) Then
        Assign($_LR_STRINGTABLE_PREF & $sLGID, $t, 2)
        Assign($_LR_LGIDINDICATOR_PREF & _Locale_StrLangID($langID), $sLGID, 2)
        
        ConsoleWrite("String table " & $module & "(" & _Locale_StrLangID($langID) & ", " & $sLGID & ") loaded" & @CRLF)
    EndIf
    Return True
EndFunc ;==>_LR_LoadStringTable

Func _LR_Dispose()
EndFunc ;==>_LR_Dispose
