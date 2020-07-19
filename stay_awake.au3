; Stay Awake
;
; A utility for faking user activity to prevent computer from sleeping or switching 
; off the display. User activity is faked by moving the mouse to the same location 
; hence does not interfere with user GUI interaction.
;
; The internal sleep timer is reset upon any keyboard activity. Once the internal
; timer exceeds the sleep interval, the program stops faking user activity, after 
; which the Windows sleep timer takes over. In other words the total time before
; the computer goes to sleep is `Internal sleep interval` + `Windows sleep interval`
;
; Copyright: Peter van der Plas © 2020
;
#include <GUIConstantsEx.au3>
#include <Math.au3>
#include <Misc.au3>
#include <MsgBoxConstants.au3>
#include <Timers.au3>
#include <TrayConstants.au3>
#include <WinAPIShellEx.au3>
#include <WinAPISys.au3>
#include <WindowsConstants.au3>

Opt("TrayOnEventMode",1)
Opt("TrayMenuMode",1)

$AboutItem = TrayCreateItem("About")
TrayItemSetOnEvent(-1,"TrayCallbackMain")
TrayCreateItem("")
$SleepSub = TrayCreateMenu("Sleep after")
$Sleep30Item = TrayCreateItem("30 seconds", $SleepSub, -1, $TRAY_ITEM_RADIO)
TrayItemSetOnEvent(-1,"TrayCallbackSleepAfter")
$Sleep60Item = TrayCreateItem("1 minute", $SleepSub, -1, $TRAY_ITEM_RADIO)
TrayItemSetOnEvent(-1,"TrayCallbackSleepAfter")
$Sleep120Item = TrayCreateItem("2 minutes", $SleepSub, -1, $TRAY_ITEM_RADIO)
TrayItemSetOnEvent(-1,"TrayCallbackSleepAfter")
$Sleep300Item = TrayCreateItem("5 minutes", $SleepSub, -1, $TRAY_ITEM_RADIO)
TrayItemSetOnEvent(-1,"TrayCallbackSleepAfter")
$Sleep600Item = TrayCreateItem("10 minutes", $SleepSub, -1, $TRAY_ITEM_RADIO)
TrayItemSetState($Sleep600Item, $TRAY_CHECKED)
TrayItemSetOnEvent(-1,"TrayCallbackSleepAfter")
$Sleep1800Item = TrayCreateItem("30 minutes", $SleepSub, -1, $TRAY_ITEM_RADIO)
TrayItemSetOnEvent(-1,"TrayCallbackSleepAfter")
TrayCreateItem("", $SleepSub)
$SleepNeverItem = TrayCreateItem("Never", $SleepSub, -1, $TRAY_ITEM_RADIO)
TrayItemSetOnEvent(-1,"TrayCallbackSleepAfter")
TrayCreateItem("")
$ExitItem = TrayCreateItem("Exit")
TrayItemSetOnEvent(-1,"TrayCallbackMain")

Global Const $HWND_MESSAGE = (-3) ;create a message-only window
Global Const $HID_USAGE_PAGE_GENERIC = 0x1
Global Const $HID_USAGE_GENERIC_KEYBOARD = 0x6

Global $hTarget = GUICreate("main", 10, 10, Default, Default, Default, Default, $HWND_MESSAGE) ;Dummy window to recieve messages
GUIRegisterMsg($WM_INPUT, "WM_INPUT") 

$tRID = DllStructCreate($tagRAWINPUTDEVICE)
DllStructSetData($tRID, "UsagePage", $HID_USAGE_PAGE_GENERIC)
DllStructSetData($tRID, "Usage", $HID_USAGE_GENERIC_KEYBOARD)
DllStructSetData($tRID, "Flags", $RIDEV_INPUTSINK)
DllStructSetData($tRID, "hTarget", $hTarget)

$pRID = DllStructGetPtr($tRID)
_WinAPI_RegisterRawInputDevices($pRID)  

Global $IdleTime = 0
Global $TimerInterval = 5
Global $SleepAfter = 600

$Timer = _Timer_SetTimer($hTarget,$TimerInterval * 1000,"TimerCallback",-1)

UpdateToolTip()

Do
Until GUIGetMsg() = $GUI_EVENT_CLOSE


Func TrayCallbackSleepAfter()
	$SelectedItem = TrayItemGetText(@TRAY_ID)
	If $Sleep30Item=@TRAY_ID Then
        $SleepAfter = 30
	ElseIf $Sleep60Item=@TRAY_ID Then
        $SleepAfter = 60
	ElseIf $Sleep120Item=@TRAY_ID Then
        $SleepAfter = 120
	ElseIf $Sleep300Item=@TRAY_ID Then
        $SleepAfter = 300
	ElseIf $Sleep600Item=@TRAY_ID Then
        $SleepAfter = 600
	ElseIf $Sleep1800Item=@TRAY_ID Then
        $SleepAfter = 1800
	EndIf
    UpdateToolTip()
EndFunc

Func TrayCallbackMain()
	$SelectedItem = TrayItemGetText(@TRAY_ID)
	If $SelectedItem="Exit" Then
		Exit
	ElseIf $SelectedItem="About" Then
		Call("About")
	EndIf
EndFunc

Func About()
	MsgBox(064,"Stay awake","Prevent your computer from sleeping or switching off the display." & @CRLF & "Copyright Peter van der Plas ©2020")
EndFunc

; Update tray tooltip
Func UpdateToolTip()
    TraySetToolTip("No key stroke for " & StringFormat($IdleTime, "%d", 1) & " seconds (" & StringFormat(_Max(0,$SleepAfter-$IdleTime), "%d", 1) & " seconds before sleeping)")
EndFunc

; Increase idle time and touch the mouse if not going to sleep
Func TimerCallback($hWnd, $Msg, $iIDTimer, $dwTime)
    $IdleTime += $TimerInterval
    UpdateToolTip()
    If $IdleTime<$SleepAfter Then
        $CurPos = MouseGetPos ()
        MouseMove ( $CurPos[0] , $CurPos[1] ) ; moving mouse to same position is sufficient for faking mouse activity
    EndIf
EndFunc

; Reset idle time
Func WM_INPUT($hWnd, $iMsg, $wParam, $lParam)
  $IdleTime = 0
  Return $GUI_RUNDEFMSG
EndFunc