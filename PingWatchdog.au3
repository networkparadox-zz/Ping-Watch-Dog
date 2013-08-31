#cs ----------------------------------------------------------------------------

   AutoIt Version:	3.3.8.1
   Author:			Larry Wickham (Network Paradox)
   Repo:			https://github.com/networkpardox/Ping-Watch-Dog
   License:			
 
   Script Function:
   A simple windows utility written in AutoIt to ping and reboot if said ping fails.

The MIT License (MIT)

Copyright (c) 2013 networkpardox

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#ce ----------------------------------------------------------------------------
#include <Constants.au3>
#include <EventLog.au3>

#NoTrayIcon
Opt("TrayMenuMode", 3) ; Default tray menu items (Script Paused/Exit) will not be shown.

FileInstall("App-world-clock.ico","App-world-clock.ico")
FileInstall("LICENSE","LICENSE")
TraySetIcon("App-world-clock.ico")

$sScriptName = "Ping Watchdog 3.3.8.1"
$sConfigFileName = "PingWatchDog.ini"

If FileExists($sConfigFileName)  = 0 Then
   IniWrite($sConfigFileName,"Config","Hostname","google.com")
   IniWrite($sConfigFileName,"Config","Interval","360")
   IniWrite($sConfigFileName,"Config","Failures","3")
EndIf

Global $sHostname = IniRead($sConfigFileName,"Config","Hostname","google.com")
Global $iInterval = IniRead($sConfigFileName,"Config","Interval","360")
Global $iFailures = IniRead($sConfigFileName,"Config","Failures","3")
#cs ----------------------------------------------------------------------------

Advanced INI configuration options not normally needed

   $iAdvancedPingWaitTime
	  Passed to the ping command to adjust the amount of time to wait for a reply AutoIt default is 4000ms
   $iAdvancedDebug 
	  = 1 to enable debugging
	  Enables debugging and prevents reboots
   $iAdvancedEventLog 
	  <> -1 to disable
	  Disables use of the Event log
   $iAdvancedStartup
	  <> -1 to disable
	  Will ping at program start otherwise interval must elapse before the first test
	  
#ce ----------------------------------------------------------------------------
Global $iAdvancedPingWaitTime = IniRead($sConfigFileName,"Advanced","Ping Wait Time",-1)
Global $iAdvancedDebug = IniRead($sConfigFileName,"Advanced","Debug",-1)
Global $iAdvancedEventLog = IniRead($sConfigFileName,"Advanced","Disable Event Log",-1)
Global $iAdvancedStartup = IniRead($sConfigFileName,"Advanced","Ping At Startup",-1)

If $iAdvancedDebug = 1 Then MsgBox(-1,$sScriptName & ' Debug', "Advanced Configuration Options:" & @CRLF & "$iAdvancedPingWaitTime = " & $iAdvancedPingWaitTime & @CRLF & "$iAdvancedEventLog = " & $iAdvancedEventLog & @CRLF & "$iAdvancedStartup = " & $iAdvancedStartup  , 30)

; Initialize defaults
$hStartTime = TimerInit()			;Initialize the builtin autoit Timer
$iTotalFailures = 0					;Start the total number of failures at 0
$sResultMsg = "Never"				;Set the message displayed for the last ping to never


; Build the system tray menu
TrayCreateItem($sScriptName)
TrayCreateItem("")
Global $gConfig = TrayCreateMenu("Configuration")
Global $gHostname = TrayCreateItem("---", $gConfig)
Global $gInterval = TrayCreateItem("---", $gConfig)
Global $gFailures = TrayCreateItem("---", $gConfig)
TrayCreateItem("")
Global $gLastCheck = TrayCreateItem("---")
Global $gFailsSoFar = TrayCreateItem("---")
TrayCreateItem("")
Local $gAbout = TrayCreateItem("About")
Local $gExit = TrayCreateItem("Exit")

UpdateTrayMenu()

TraySetState()
#cs ----------------------------------------------------------------------------
Main program loop
#ce ----------------------------------------------------------------------------
While 1
   Local $msg = TrayGetMsg()
   Select 	; Handle tray gui events
		 Case $msg = $gHostname
			$sNewHost = InputBox($sScriptName,"Enter hostname to ping",$sHostname)
			$iPingNewHost = Ping($sNewHost, $iAdvancedPingWaitTime) 
			If $iPingNewHost = 0 Then
			   $iAskNewHostFailed = MsgBox(0x24, $sScriptName, "Initial ping to " & $sNewHost & " failed. Do you want to keep it?")
			   If $iAskNewHostFailed = 6 Then $iPingNewHost = $iAskNewHostFailed
			EndIf
			If $iPingNewHost > 0 Then
			   IniWrite($sConfigFileName,"Config","Hostname",$sNewHost)
			   $sHostname = $sNewHost
			   UpdateTrayMenu ()
			EndIf
			ContinueLoop
			
		 Case $msg = $gInterval
			$iNewInterval = InputBox($sScriptName,"Enter ping interval in seconds",$iInterval)
			If $iNewInterval >= 1 Then
			   IniWrite($sConfigFileName,"Config","Interval",$iNewInterval)
			   $iInterval = $iNewInterval
			   UpdateTrayMenu ()
			Else
			   MsgBox(0x30, $sScriptName,"Invalid interval value entered. Configuration not saved",10)
			EndIf
			ContinueLoop
		 
		 Case $msg = $gFailures
			$iNewFails = InputBox($sScriptName,"Enter number of failures till reboot",$iFailures)
			If $iNewFails >= 1 Then
			   IniWrite($sConfigFileName,"Config","Failures",$iNewFails)
			   $iFailures = $iNewFails
			   UpdateTrayMenu ()
			Else 
			   MsgBox(0x30, $sScriptName,"Invalid number of failures value entered. Configuration not saved",10)
			EndIf
		   ContinueLoop
		 Case $msg = $gAbout
			ShellExecute("https://github.com/networkpardox/Ping-Watch-Dog")
			ContinueLoop
		 Case $msg = 0
			ContinueLoop
		 Case $msg = $gExit
            ExitLoop
   EndSelect
		 
   If TimerDiff($hStartTime) > ($iInterval * 1000) Or $iAdvancedStartup <> -1 Then  ; Do the testing
	  $iResult = Ping($sHostname, $iAdvancedPingWaitTime)
	  $iResultError = @error
	  If $iAdvancedDebug = 1 Then MsgBox(-1,$sScriptName & ' Debug', "$iResult = " & $iResult & @CRLF & "$iResultError = " & $iResultError , 10)
	  If $iResult > 0 Then
		 $sResultMsg = @HOUR & ':' & @MIN & ':' & @SEC & ' (' & $iResult & 'ms)'
		 $hStartTime = TimerInit()
		 $iTotalFailures = 0
		 UpdateTrayMenu ()
	  EndIf
	  If $iResult = 0 Then
		 If $iResultError = 1 Then $sResultMsg = "Host is offline :" & $sHostname
		 If $iResultError = 2 Then $sResultMsg = "Host is unreachable :" & $sHostname
		 If $iResultError = 3 Then $sResultMsg = "Bad destination :" & $sHostname
		 If $iResultError = 4 Then $sResultMsg = "Other error pinging " & $sHostname 
		 WriteEventLog(4, "Ping Failed : " & $sResultMsg)
		 $hStartTime = TimerInit()
		 $iTotalFailures = $iTotalFailures + 1
		 UpdateTrayMenu ()
	  EndIf
	  If $iTotalFailures = $iFailures Then
		 $gConfirm = MsgBox(0x40031,$sScriptName,"Rebooting ... after " & $iTotalFailures & " failures ", 10)
		 If $gConfirm = 2 Then ; User has cancelled reboot
			$hStartTime = TimerInit()
			$iTotalFailures = 0
			UpdateTrayMenu ()
		 Else
			WriteEventLog(1,"System reboot initiated by " & $sScriptName & " after " & $iTotalFailures & " failures pinging " & $sHostname)
			If $iAdvancedDebug = -1 Then Shutdown(6)
		 EndIf
	  EndIf
	  $iAdvancedStartup = -1
   EndIf
   
WEnd

#cs ----------------------------------------------------------------------------
   Function to update the data displayed on the tray menu
#ce ----------------------------------------------------------------------------
Func UpdateTrayMenu ()
   $sHostnameText = "Host: " & $sHostname
   $sIntervalText = "Interval: " & $iInterval & " seconds"
   $sFailuresText = "Failures: " & $iFailures
   $sLastCheckText = "Last Check: " & $sResultMsg
   $sFailsSoFarText = "Failures: " & $iTotalFailures & '/' & $iFailures

   TrayItemSetText($gHostname,$sHostnameText)
   TrayItemSetText($gInterval,$sIntervalText)
   TrayItemSetText($gFailures, $sFailuresText)
   TrayItemSetText($gLastCheck, $sLastCheckText)
   TrayItemSetText($gFailsSoFar, $sFailsSoFarText)
EndFunc


#cs ----------------------------------------------------------------------------
   Function to write to the Windows event Log
#ce ----------------------------------------------------------------------------
Func WriteEventLog($iType,$sDesc)
	  Local $hEventLog, $aData[4] = [3, 1, 2, 3]
	  
	  If $iAdvancedEventLog = -1 Then
		 If $iAdvancedDebug = 1 Then MsgBox(-1,$sScriptName & ' Debug', "Event log:" & @CRLF & " $iType = " & $iType & @CRLF & "$sDesc = " & $sDesc , 10)
		 $hEventLog = _EventLog__Open("", "Application")
			If $hEventLog = 0 And $iAdvancedDebug = 1 Then MsgBox(-1,$sScriptName & ' Debug', "Event log open failed" , 10)
		 $bResultEventLogReport = _EventLog__Report($hEventLog, $iType, 0, 2, @UserName, $sDesc, $aData)
			If $hEventLog = False And $iAdvancedDebug = 1 Then MsgBox(-1,$sScriptName & ' Debug', "Event log report failed" , 10)
		 _EventLog__Close($hEventLog)
	  EndIf
EndFunc   

Exit

