#include-once
; ------------------------------------------------------------------------------
;
; Version:        1.0.0
; AutoIt Version: 3.3.2.0
; Language:       English
; Author:         doudou
; Description:    Utility functions for localization library.
;                 
; ------------------------------------------------------------------------------

Func _LR_MsgBox($flag, $resID, $titleID = Default, $timeout = -1)
    If Default = $titleID Then $titleID = $_LR_IDS_APPTITLE
    Return MsgBox($flag, _LR_GetString($titleID), _LR_GetString($resID), $timeout)
EndFunc ;==>_LR_MsgBox

Func _LR_FormatString($resID, $var1 = Default, $var2 = Default, $var3 = Default, $var4 = Default, $var5 = Default, $var6 = Default, $var7 = Default _ 
                        , $var8 = Default, $var9 = Default, $var10 = Default, $var11 = Default, $var12 = Default, $var13 = Default, $var14 = Default _ 
                        , $var15 = Default, $var16 = Default, $var17 = Default, $var18 = Default, $var19 = Default, $var20 = Default, $var21 = Default _ 
                        , $var22 = Default, $var23 = Default, $var24 = Default, $var25 = Default, $var26 = Default, $var27 = Default, $var28 = Default _ 
                        , $var29 = Default, $var30 = Default, $var31 = Default, $var32 = Default)
    
    Local $result = _LR_GetString($resID)
    If $result <> $resID Then $result = StringFormat($result, $var1, $var2, $var3, $var4, $var5, $var6, $var7 _ 
        , $var8, $var9, $var10, $var11, $var12, $var13, $var14 _ 
        , $var15, $var16, $var17, $var18, $var19, $var20, $var21 _ 
        , $var22, $var23, $var24, $var25, $var26, $var27, $var28 _ 
        , $var29, $var30, $var31, $var32)
    Return $result
EndFunc ;==>_LR_FormatString
