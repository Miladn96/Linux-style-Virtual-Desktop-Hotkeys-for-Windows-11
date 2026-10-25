#Requires AutoHotkey v2.0
#SingleInstance Force

; =============================================================================
; Linux-style virtual desktop and app switching for Windows 11
;
; Ctrl+Alt+Left/Right              switch to previous/next desktop
; Ctrl+Alt+Shift+Left/Right        move active window to previous/next desktop and follow it
; Left Win+Tab (+Shift = reverse)  Alt+Tab switcher
; Left Win+` (+Shift = reverse)    cycle between windows of the current app
;
; Requires VirtualDesktopAccessor.dll in the same folder as this script.
; https://github.com/Ciantic/VirtualDesktopAccessor
; =============================================================================

; ---------- Load VirtualDesktopAccessor.dll ----------
dllPath := A_ScriptDir "\VirtualDesktopAccessor.dll"
if !FileExist(dllPath) {
    MsgBox "VirtualDesktopAccessor.dll was not found next to this script:`n`n" dllPath, "desktops.ahk", "Iconx"
    ExitApp
}

hModule := DllCall("LoadLibrary", "Str", dllPath, "Ptr")
if !hModule {
    MsgBox "Could not load VirtualDesktopAccessor.dll.`n`nMake sure it is not blocked (right-click > Properties > Unblock) "
        . "and that it matches your Windows build.", "desktops.ahk", "Iconx"
    ExitApp
}

; Look up an exported DLL function by name; abort with a clear message if it is missing
GetProc(name) {
    p := DllCall("GetProcAddress", "Ptr", hModule, "AStr", name, "Ptr")
    if !p {
        MsgBox "The DLL does not export '" name "'.`nTry a newer release of VirtualDesktopAccessor.dll.", "desktops.ahk", "Iconx"
        ExitApp
    }
    return p
}

GoToDesktop := GetProc("GoToDesktopNumber")
GetCurrent  := GetProc("GetCurrentDesktopNumber")
GetCount    := GetProc("GetDesktopCount")
MoveWin     := GetProc("MoveWindowToDesktopNumber")
IsOnCurrent := GetProc("IsWindowOnCurrentVirtualDesktop")

; ---------- Switch between desktops: Ctrl+Alt+Left/Right ----------
^!Left::SwitchBy(-1)
^!Right::SwitchBy(1)

; ---------- Move active window to previous/next desktop and follow it: Ctrl+Alt+Shift+Left/Right ----------
^!+Left::MoveActiveBy(-1)
^!+Right::MoveActiveBy(1)

SwitchBy(step) {
    cur := DllCall(GetCurrent, "Int")
    cnt := DllCall(GetCount, "Int")
    if (cur < 0 || cnt < 1)
        return                                                ; the DLL returns -1 on error
    DllCall(GoToDesktop, "Int", Mod(cur + step + cnt, cnt))   ; wraps around at both ends
}

MoveActiveBy(step) {
    hwnd := WinExist("A")
    if !hwnd
        return                                                ; no active window, nothing to move
    cur := DllCall(GetCurrent, "Int")
    cnt := DllCall(GetCount, "Int")
    if (cur < 0 || cnt < 1)
        return
    target := Mod(cur + step + cnt, cnt)
    DllCall(MoveWin, "Ptr", hwnd, "Int", target)
    DllCall(GoToDesktop, "Int", target)
}

; ---------- Left Win+Tab = Alt+Tab switcher ----------
; "&" combos cannot contain modifier symbols such as "+", so the reverse (Shift)
; variant is a separate hotkey that is only active while Shift is held.
; Holding Win keeps the switcher open; repeated Tab presses move the selection.
; The switcher honors Settings > System > Multitasking > "Pressing Alt+Tab shows windows that are open on".
#HotIf GetKeyState("Shift", "P")
LWin & Tab::ShiftAltTab
LWin & SC029::CycleSameApp(true)
#HotIf

LWin & Tab::AltTab

; ---------- Left Win+` = cycle between windows of the current app ----------
; SC029 is the physical key left of "1", so it works regardless of keyboard layout
LWin & SC029::CycleSameApp(false)

CycleSameApp(reverse := false) {
    ; bail out quietly if there is no active window (empty desktop, taskbar, etc.)
    active := WinExist("A")
    if !active
        return
    try exe := WinGetProcessName("ahk_id " active)
    catch
        return

    list := []
    for hwnd in WinGetList("ahk_exe " exe) {
        if WinGetTitle(hwnd) = ""
            continue                                          ; skip windows without a title
        if WinGetExStyle(hwnd) & 0x80
            continue                                          ; skip tool windows (WS_EX_TOOLWINDOW)
        if !DllCall(IsOnCurrent, "Ptr", hwnd, "Int")
            continue                                          ; only windows on the current desktop
        list.Push(hwnd)
    }
    if list.Length < 2
        return

    ; WinGetList is ordered top to bottom in z-order.
    ; Forward: bring the bottom-most window of this app to the front.
    ; Reverse: bring the second window to the front (steps back through the stack).
    WinActivate list[reverse ? 2 : list.Length]
}
