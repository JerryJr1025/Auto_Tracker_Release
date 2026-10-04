# Trinovation Auto Count Tracker v0.1.21-r2 — macOS Installation

This guide is written in simple steps for agents using a Mac.

## Before you start

You need:
- A Mac with internet connection
- A browser with Tampermonkey
- The approved Auto Tracker v0.1.21-r2 release folder
- Apps Script Web App `/exec` URL
- Registration Token
- Agent ID, full name, Department, and Pod

## Supported macOS file layout

Keep the launcher and controller files together in one writable folder such as Downloads or Documents. The recommended package contains:

```text
Auto_Tracker_macOS.command
server.js                         (or backend/node/server.js)
TamperMonkey Mods                 (or frontend/tampermonkey/Auto_Tracker.user.js)
package.json
package-lock.json
```

r2 recognizes the repository-style Tampermonkey path, the `Tampermonkey_Modifications/TamperMonkey Mods` path, and a same-folder `TamperMonkey Mods` file. It compares controller version + revision before replacing `server.js`, so a same/newer Drive-updated runtime is preserved. If a compatible `Auto_Tracker.bat` is included and `server.js` is missing, macOS can also recover the embedded controller fallback.

The launcher keeps `Logs`, `Reports`, `Backups`, runtime state, and the runtime controller inside this Auto Tracker folder.

## Start the installer

1. Put the Auto Tracker folder in **Downloads** or **Documents**.
2. Open the folder.
3. Double-click **Auto_Tracker_macOS.command**.
4. If macOS does not let the file run because it is not executable, open Terminal in the folder and run:

```bash
chmod +x Auto_Tracker_macOS.command
./Auto_Tracker_macOS.command
```

5. The installer checks Node.js.
6. If Homebrew is already installed, the script can offer to install Node.js with Homebrew.
7. If Homebrew is not installed, the script opens the official Node.js page. Install the LTS version, return to the tracker window, and press **R** to check again.
8. The tracker creates the backup **before** replacing controller files, then verifies ExcelJS, the controller, and Tampermonkey. The first ExcelJS install uses the lockfile/cache-aware fast path when available; later launches skip npm when ExcelJS is already ready.
9. If the same/newer Rev2 controller is already using port 9000, the launcher reuses it. It will not terminate an unrelated listener, and it will not replace an older tracker while an active shift is running.
10. Open your labeling website with Tampermonkey enabled.
11. Approve the Auto Tracker userscript Install/Update if Tampermonkey asks.
12. Dock the tracker **Left** or **Right**.
13. Open **Settings → FIRST-TIME / DEVICE SETUP**.
14. Enter the Apps Script URL, Registration Token, Agent ID, Agent name, Last name, Department, and Pod.
15. Click **Complete / Update First-Time Setup**.
16. Click **Start Shift** when you are ready to work.

## Important macOS safety note

The v0.1.21 installer does **not** turn off Gatekeeper and does not disable macOS certificate/security checks.

## If something goes wrong

Open the `Logs` folder inside Auto Tracker.

Look for:
- `macos_startup_errors_YYYY-MM-DD.log`
- `macos_runtime_errors_YYYY-MM-DD.log`

If the folder is read-only, move the whole Auto Tracker folder to Downloads or Documents and run it again.


## Safe second launch

Opening `Auto_Tracker_macOS.command` again while the approved Rev2 controller is already running is safe. The launcher verifies `127.0.0.1:9000/stats` and reuses the current controller instead of opening a duplicate.

If Finder refuses to run the command because the executable bit was lost during download/extraction, use only:

```bash
chmod +x Auto_Tracker_macOS.command
./Auto_Tracker_macOS.command
```

The installer does not require disabling Gatekeeper.
