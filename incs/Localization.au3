#include-once
; ------------------------------------------------------------------------------
;
; Version:        1.0.0
; AutoIt Version: 3.3.2.0
; Language:       English
; Author:         doudou
; Description:    Common functions for localization library.
;                 
; ------------------------------------------------------------------------------
;ConsoleWrite("Localization OSLang=" & @OSLang & ", MUILang=" & @MUILang & @CRLF)

Global Const $_LR_DEFAULTLANG   = _Locale_GetDefaultLangID()

Global Const $_LR_STRINGTABLE_PREF = "_LR_stringTable_"
Global Const $_LR_LGIDINDICATOR_PREF = "_LR_loadedLGID_"
Global Const $_LR_RESID_PREF = "IDS_"

Func _Locale_IntLangID($langID)
    If IsNumber($langID) Then
        Return Int($langID)
    Else
        Return Int("0x" & $langID)
    EndIf    
EndFunc ;==>_Locale_IntLangID

Func _Locale_StrLangID($langID)
    If IsNumber($langID) Then
        Return StringFormat("%.4x", $langID)
    Else
        Return "" & $langID
    EndIf    
EndFunc ;==>_Locale_StrLangID

Func _Locale_GetDefaultLangID()
    If 0 <> Int(@MUILang) Then Return @MUILang
    Return @OSLang    
EndFunc ;==>_Locale_GetDefaultLangID

Func _Locale_GetPrimaryLangID($langID)
    Return BitAnd(0x3ff, _Locale_IntLangID($langID))
EndFunc ;==>_Locale_GetPrimaryLangID

Func _Locale_GetSublangID($langID)
    Return Int(_Locale_IntLangID($langID) / 0x400)
EndFunc ;==>_Locale_GetSublangID

Func _Locale_MakeLangID($primLangID, $sublangID)
    Return BitOr(_Locale_IntLangID($sublangID) * 0x400, _Locale_IntLangID($primLangID))    
EndFunc ;==>_Locale_MakeLangID

Func _LR_GetMappedLangID($langID)
    Local $s = $_LR_LGIDINDICATOR_PREF & _Locale_StrLangID($langID)
    If IsDeclared($s) Then Return Eval($s)
    Return $langID
EndFunc ;==>_LR_GetMappedLangID
