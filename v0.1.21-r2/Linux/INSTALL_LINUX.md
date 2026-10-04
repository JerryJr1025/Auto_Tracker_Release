# Trinovation Auto Count Tracker v0.1.21-r2 — Linux Installation

This guide is written for agents and uses simple steps.

## Before you start

You need:
- Linux with a normal desktop environment
- Internet connection for first setup
- A browser with Tampermonkey
- The approved Auto Tracker v0.1.21-r2 release folder
- Apps Script Web App `/exec` URL
- Registration Token
- Agent ID, full name, Department, and Pod

## Install Node.js first

On Ubuntu or Linux Mint, open Terminal and run:

```bash
sudo apt update
sudo apt install -y nodejs npm
```

Check that both are ready:

```bash
node --version
npm --version
```

Both commands should show a version number.

## Supported Linux file layouts

Recommended IT/repository package:

```text
Auto_Tracker.sh
backend/node/server.js
frontend/tampermonkey/Auto_Tracker.user.js
package.json
package-lock.json
```

A compact package may instead use an already-installed/approved `server.js`, and r2 can also find `TamperMonkey Mods` in the same folder. Rev2 compares controller version + revision before copying packaged code, so a same/newer Drive-updated runtime is not downgraded on the next launch. If `server.js` is missing but `Auto_Tracker.bat` is present, Linux can safely extract the embedded controller without requiring Python.

The Linux launcher runs from its own folder, and keeps `Logs`, `Reports`, `Backups`, runtime state, and `server.js` there.

## Start Auto Tracker

1. Open Terminal inside the Auto Tracker folder.
2. Make the launcher executable one time:

```bash
chmod +x Auto_Tracker.sh
```

3. Start it:

```bash
./Auto_Tracker.sh
```

4. The launcher creates a backup, checks ExcelJS, checks the controller, and checks the Tampermonkey userscript. The first ExcelJS install uses the lockfile/cache-aware fast path when available; later launches skip npm when ExcelJS is already ready.
5. If port 9000 already belongs to the same/newer Auto Tracker, the launcher reuses it and does not start a duplicate.
6. An unrelated port-9000 application is never killed automatically. An older verified tracker cannot be replaced while it has an active shift.
7. Open your labeling website with Tampermonkey enabled.
8. If Tampermonkey asks to install/update Auto Tracker, approve it.
9. Dock the tracker **Left** or **Right**.
10. Open **Settings → FIRST-TIME / DEVICE SETUP**.
11. Enter the Apps Script URL, Registration Token, Agent ID, Agent name, Last name, Department, and Pod.
12. Click **Complete / Update First-Time Setup**.
13. Click **Start Shift** when you begin working.

## If something goes wrong

Look inside the Auto Tracker `Logs` folder.

Common Linux logs:
- `linux_startup_errors_YYYY-MM-DD.log`
- `linux_runtime_errors_YYYY-MM-DD.log`

If `node --version` or `npm --version` does not work, fix Node.js/npm first, then run `./Auto_Tracker.sh` again.

Do not use `sudo` to run the tracker itself.


## Safe second launch

Starting `./Auto_Tracker.sh` again while the current Rev2 controller is already running is safe. The launcher verifies the local `/stats` identity and reuses the existing controller instead of killing it or starting another copy.

Do not use `sudo ./Auto_Tracker.sh`. Run it as the normal agent account so reports, logs, and device files keep the correct ownership.
