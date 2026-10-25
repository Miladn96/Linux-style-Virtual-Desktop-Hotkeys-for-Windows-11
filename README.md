# Linux-style Virtual Desktop Hotkeys for Windows 11

An [AutoHotkey v2](https://www.autohotkey.com/) script that brings the virtual desktop and app-switching workflow of Linux desktops (GNOME and similar) to Windows 11.

If you moved from Linux to Windows and miss switching workspaces with `Ctrl+Alt+Arrow`, carrying a window along with `Shift`, and `Super+Tab` / `Super+`` for app switching, this is for you.

## Hotkeys

| Hotkey | Action |
| --- | --- |
| `Ctrl` + `Alt` + `←` / `→` | Switch to the previous / next virtual desktop (wraps around) |
| `Ctrl` + `Alt` + `Shift` + `←` / `→` | Move the active window to the previous / next desktop and follow it |
| `Left Win` + `Tab` | Alt+Tab style switcher across **all windows on all desktops** |
| `Left Win` + `Shift` + `Tab` | Same switcher, reverse direction |
| `Left Win` + `` ` `` | Cycle between windows of the **current app** on the current desktop |
| `Left Win` + `Shift` + `` ` `` | Same, reverse direction |

The `` ` `` key is the physical key left of `1`, matched by scan code, so it works with any keyboard layout (including non-Latin layouts).

> The Windows default `Win+Tab` (Task View) is replaced by this script. Pin the Task View button to your taskbar if you still want it (Settings → Personalization → Taskbar). `Right Win` keeps the default Windows behavior.

## Requirements

- Windows 11, **24H2 build 26100.2605 or newer** (this is the requirement of the current `VirtualDesktopAccessor.dll`; check yours with `Win+R` → `winver`)
- [AutoHotkey v2](https://www.autohotkey.com/) (v1 will not work)
- [`VirtualDesktopAccessor.dll`](https://github.com/Ciantic/VirtualDesktopAccessor/releases) (not bundled; download it from the releases page)

## Installation

1. **Install AutoHotkey v2** from [autohotkey.com](https://www.autohotkey.com/).
2. **Download `VirtualDesktopAccessor.dll`** from the [releases page](https://github.com/Ciantic/VirtualDesktopAccessor/releases). You only need the DLL, not the source code. If Windows blocks it, right-click the file → **Properties** → tick **Unblock**.
3. **Put both files in the same folder** and keep that folder somewhere permanent, for example:
   ```
   C:\Users\<you>\Scripts\desktops\
       desktops.ahk
       VirtualDesktopAccessor.dll
   ```
4. **Make Alt+Tab show every desktop.** Open Settings → System → Multitasking and set *Pressing Alt + Tab shows windows that are open on* to **All desktops**. The `Win+Tab` switcher uses this setting.
5. **Run the script** by double-clicking `desktops.ahk`. A green **H** icon appears in the system tray.

### Start automatically with Windows

1. Press `Win+R`, type `shell:startup`, press Enter.
2. Create a shortcut to `desktops.ahk` inside that folder (keep the original files where they are).

### Updating after edits

Right-click the tray icon → **Reload Script**.

## How it works

- Desktop switching and moving windows use the exported functions of [VirtualDesktopAccessor.dll](https://github.com/Ciantic/VirtualDesktopAccessor) (`GoToDesktopNumber`, `MoveWindowToDesktopNumber`, and others), called through AutoHotkey's `DllCall`.
- `Win+Tab` uses AutoHotkey's built-in `AltTab` hotkey action, so the real Windows Alt+Tab switcher is shown.
- `Win+`` collects the windows that belong to the same executable as the active window, keeps only those on the current desktop, and activates the next one in z-order.

## Customization

Hotkeys are plain AutoHotkey syntax at the top level of `desktops.ahk`. Examples:

```autohotkey
; Use Ctrl+Alt+Up/Down instead of Left/Right
^!Up::SwitchBy(-1)
^!Down::SwitchBy(1)

; Stop at the first/last desktop instead of wrapping around:
; replace the Mod(...) expression in SwitchBy with
;   Max(0, Min(cnt - 1, cur + step))
```

See the [AutoHotkey hotkey docs](https://www.autohotkey.com/docs/v2/Hotkeys.htm) for modifier symbols.

## Troubleshooting

**"VirtualDesktopAccessor.dll was not found"**
The DLL must be in the same folder as `desktops.ahk`.

**"Could not load VirtualDesktopAccessor.dll" or hotkeys do nothing**
Unblock the DLL (Properties → Unblock) and make sure it matches your Windows build. Older Windows builds may need an older DLL release.

**Hotkeys do not work in some windows**
Windows does not let a normal process send input to elevated (Run as administrator) windows. Run the script as administrator too, or start it from Task Scheduler with *Run with highest privileges*.

**Win+Tab shows only the current desktop's windows**
Check step 4 of the installation (Settings → System → Multitasking).

**Start menu opens unexpectedly after using the Win hotkeys**
Add `#UseHook true` directly below `#Requires AutoHotkey v2.0` in `desktops.ahk`.

**Windows updates break desktop switching**
Virtual desktop internals are undocumented and change between Windows builds. Download the latest `VirtualDesktopAccessor.dll` release.

## Known limitations

- `Win+Tab` lists individual windows like the normal Alt+Tab. It does not group windows per app the way GNOME does; use `Win+`` for that.
- `Win+`` cycling order follows window z-order, so with three or more windows the sequence can differ from the Linux behavior.
- Only `Left Win` is remapped.

## Credits

- [Ciantic/VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor) by Jari Pennanen (MIT) provides the DLL that makes this possible.
- [AutoHotkey](https://www.autohotkey.com/) provides the scripting layer.

## License

MIT. Add a `LICENSE` file to your repository (GitHub can generate one when you create the repo or via *Add file → Create new file → LICENSE*).
