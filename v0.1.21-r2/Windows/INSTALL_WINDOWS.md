# Trinovation Auto Count Tracker v0.1.21-r2 — Windows Installation

This guide is written for agents. Follow it from top to bottom. You do not need to understand the code.

## Before you start

You need:
- Windows 10 or Windows 11
- Internet connection for the first setup
- Chrome, Edge, Firefox, or another supported browser
- Tampermonkey installed in the browser
- The Auto Tracker r2 release files
- Your Apps Script Web App `/exec` URL
- Your Registration Token
- Your Agent ID, full name, Department, Pod, and Last Name

Never send your Registration Token or device token in chat or screenshots.

## Which files should the agent receive?

### Simple Windows package

The smallest supported r2 package is:

```text
Auto Tracker r2/
├─ Auto_Tracker.bat
└─ TamperMonkey Mods
```

Keep those two files in the **same folder**. Do not rename `TamperMonkey Mods`.

The BAT already contains a compatible embedded `server.js` fallback. It can also use these layouts when they are included:

```text
backend/node/server.js
frontend/tampermonkey/Auto_Tracker.user.js
server.js
Tampermonkey_Modifications/TamperMonkey Mods
```

The canonical repository layout is preferred for IT testing, but agents do not need the full source tree when the approved simple r2 package is used.

## Where the installed/runtime files go

The BAT resolves the user's real Windows Desktop location and uses:

```text
Desktop\JobTrackerServer\
├─ server.js
├─ package.json
├─ package-lock.json              (when supplied)
├─ node_modules\
├─ Tampermonkey_Modifications\
│  └─ TamperMonkey Mods
├─ Logs\
├─ Reports\
├─ Backups\
├─ Integrity_Quarantine\         (only when needed)
├─ report-upload-config.json      (after device setup)
├─ stats.json                     (after tracker use)
└─ tracker state/integrity files
```

Do not manually move individual runtime files out of `JobTrackerServer`.

## Install

1. Put the approved r2 release files together in one normal folder such as Downloads or Documents.
2. Double-click **Auto_Tracker.bat**.
3. On the first run, choose **Y** when it asks to run first-time setup.
4. Wait while the tracker checks Node.js, npm, ExcelJS, the controller, and Tampermonkey source. A completely fresh PC can take a few minutes while Node.js and ExcelJS are downloaded.
5. If Windows asks permission to install Node.js, allow the normal Node.js LTS installation. Rev2 uses the lockfile/cache-aware fast npm path when available and skips npm completely on later runs when ExcelJS is already ready.
6. When setup is successful, you should see the **Trinovation Auto Count Tracker** menu.
7. Choose **Start Tracker**.
8. If port 9000 already belongs to the same/newer approved Auto Tracker, Rev2 **reuses it** and does not start a duplicate controller.
9. If an older verified Auto Tracker is using port 9000, Rev2 will refuse to replace it while an active shift is running. End the shift normally first. An unrelated port-9000 program is never terminated automatically.
10. If Tampermonkey opens an Install/Update page, click **Install** or **Update** once.
11. Open the labeling website.
12. In the tracker, choose **Dock Left** or **Dock Right**, then open the **Settings** gear.
13. Open **FIRST-TIME / DEVICE SETUP**.
14. Enter the Apps Script Web App URL, Registration Token, Agent ID, Agent full name, Last Name, Department, and Pod.
15. Click **Complete / Update First-Time Setup**.
16. Confirm that the tracker says setup is complete.
17. Click **Start Shift** only when you are ready to work.

## What r2 fixes on Windows

r2 validates exact BAT labels, creates the startup-log location before controller preparation, supports both same-folder and repository-style sources, checks port 9000, and has a hard stop before the embedded JavaScript payload.

If you ever see repeated messages such as:

```text
'const' is not recognized as an internal or external command
```

stop that copy and report it to IT. An approved r2 BAT must not execute its embedded JavaScript through `cmd.exe`.

## If something goes wrong

Use **Setup / Repair** from the BAT menu first.

Windows setup logs:
`Desktop\JobTrackerServer\Logs\setup_windows.log`

Controller startup errors:
`Desktop\JobTrackerServer\Logs\controller_startup_errors.log`

Runtime diagnostic/error files are also stored under:
`Desktop\JobTrackerServer\Logs\`

Do not delete `stats.json`, `.tracker-integrity-key`, or the device upload configuration unless IT Support specifically asks you to.

If the update screen says **RELEASE CONTENT CHANGED**, stop. Do not bypass it. The approved Drive release needs to be corrected by IT.


## Break / Resume check after installing the newest r2 userscript

Before a large rollout, do this once on a canary agent:

1. Start Shift.
2. Start Break and confirm the countdown/focus screen appears.
3. Click **Resume**.
4. The Break focus screen must close immediately and the normal tracker dashboard must return.
5. Confirm Status becomes ACTIVE, or IDLE when appropriate if the full pause allowance already expired.

This check protects against an older intermediate r2 userscript that could keep a stale Break focus state after Resume.
