@echo off
REM Ver 0.0.5 Alpha || 2026-09-07 || JBallados
REM Ver 0.0.6 Alpha || 2026-09-07 || JBallados
REM Ver 0.0.7 Alpha || 2026-09-14 || JBallados
REM Ver 0.0.8 Alpha || 2026-09-15 || JBallados
REM Ver 0.0.10 Alpha || 2026-09-24 || JBallados
REM Ver 0.0.11 Alpha || 2026-09-24 || JBallados || Gdrive_Upload
REM Ver 0.0.12 Alpha || 2026-09-27 || JBallados || Start_UI_Settings_SecureDrive
REM Ver 0.1.13 Alpha || 2026-09-27 || JBallados || Master integration
REM Ver 0.1.14 Alpha || 2026-09-27 || JBallados || PerDeviceToken_AdaptiveContrast
REM Ver 0.1.15 Alpha || 2026-09-28 || JBallados || Remove_Rclone_Source_Cleanup
REM Ver 0.1.16 Alpha || 2026-09-28 || JBallados || FirstSetup_TL_Mac_ErrorLogging
REM Ver 0.1.21 Alpha || 2026-09-28 || JBallados || TeamLead_Overall
REM Ver 0.1.21 Alpha || 2026-10-03 || JBallados || OfficialBranding_LunchBreak_IdleAccuracy
REM Ver 0.1.21 Rev2 || 2026-10-03 || JBallados || Deployment_Hardening_Windows_Fallthrough_Fix
REM ===============================
title Trinovation Auto Count Tracker v0.1.21

:START
cls

set "DESKTOP_DIR=%USERPROFILE%\Desktop"
for /f "usebackq delims=" %%D in (`powershell -NoLogo -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do if not "%%D"=="" set "DESKTOP_DIR=%%D"
set "TARGET_DIR=%DESKTOP_DIR%\JobTrackerServer"
set "SETUP_MARKER=%TARGET_DIR%\.setup_complete"
set "TAMPERMONKEY_PROMPT_MARKER=%TARGET_DIR%\.tampermonkey_prompted"
set "INSTALL_SCRIPT_MARKER=%TARGET_DIR%\.install_tampermonkey_script"
set "UPLOAD_CONFIG=%TARGET_DIR%\report-upload-config.json"
set "TRACKER_ICON_SOURCE=%~dp0assets\trinovation.ico.b64"
set "TRACKER_ICON_TARGET=%TARGET_DIR%\assets\trinovation.ico"
set "TRACKER_SHORTCUT=%DESKTOP_DIR%\Trinovation Auto Count Tracker.lnk"
set "TAMPERMONKEY_SOURCE="
if exist "%~dp0frontend\tampermonkey\Auto_Tracker.user.js" set "TAMPERMONKEY_SOURCE=%~dp0frontend\tampermonkey\Auto_Tracker.user.js"
if not defined TAMPERMONKEY_SOURCE if exist "%~dp0Tampermonkey_Modifications\TamperMonkey Mods" set "TAMPERMONKEY_SOURCE=%~dp0Tampermonkey_Modifications\TamperMonkey Mods"
if not defined TAMPERMONKEY_SOURCE if exist "%~dp0TamperMonkey Mods" set "TAMPERMONKEY_SOURCE=%~dp0TamperMonkey Mods"
if not defined TAMPERMONKEY_SOURCE if exist "%TARGET_DIR%\Tampermonkey_Modifications\TamperMonkey Mods" set "TAMPERMONKEY_SOURCE=%TARGET_DIR%\Tampermonkey_Modifications\TamperMonkey Mods"
set "TRACKER_TAMPERMONKEY_SOURCE=%TAMPERMONKEY_SOURCE%"
set "TRACKER_CONTROLLER_SOURCE="
if exist "%~dp0backend\node\server.js" set "TRACKER_CONTROLLER_SOURCE=%~dp0backend\node\server.js"
if not defined TRACKER_CONTROLLER_SOURCE if exist "%~dp0server.js" set "TRACKER_CONTROLLER_SOURCE=%~dp0server.js"
set "EMBEDDED_CONTROLLER_VERSION=0.1.21"
set "EMBEDDED_CONTROLLER_REVISION=2"
if not defined TRACKER_MODE set "TRACKER_MODE=1"
call :CHECK_FIRST_TIME_SETUP
if errorlevel 1 exit /b 1

:MAIN_MENU
cls

echo ============================================================================
echo                 TRINOVATION AUTO COUNT TRACKER
echo                         v0.1.21 ALPHA
echo ============================================================================
echo.
echo Environment : Windows
echo Controller  : Local Node.js / Port 9000
echo Upload      : Apps Script / Per-Device Credential
echo Reports     : Break and Lunch tracked separately
echo.
echo [1] Start Tracker
echo [2] Mode 1 - Confirmation
echo [3] Mode 2 - Coverage
echo [4] Reports / Upload Status
echo [5] Setup / Repair
echo [6] Tampermonkey
echo [7] Exit
echo.
echo Current Mode : %TRACKER_MODE%
echo ==================================================

choice /C 1234567 /N /M "Select option: "

if errorlevel 7 goto MENU_EXIT
if errorlevel 6 goto MENU_TAMPERMONKEY
if errorlevel 5 goto MENU_SETUP
if errorlevel 4 goto MENU_REPORTS
if errorlevel 3 goto SELECT_MODE2
if errorlevel 2 goto SELECT_MODE1
if errorlevel 1 goto START_TRACKER

:MENU_EXIT
echo.
echo [INFO] Auto Tracker closed safely.
exit /b 0

:SELECT_MODE1
set "TRACKER_MODE=1"
echo.
echo [OK] Confirmation mode selected.
timeout /t 1 /nobreak >nul
goto MAIN_MENU

:SELECT_MODE2
set "TRACKER_MODE=2"
echo.
echo [OK] Coverage mode selected.
timeout /t 1 /nobreak >nul
goto MAIN_MENU

:MENU_REPORTS
cls
echo ==================================================
echo             REPORT / CLOUD UPLOAD
echo ==================================================
echo.
if exist "%UPLOAD_CONFIG%" (
    echo Apps Script Device Upload : CONFIGURED
) else (
    echo Apps Script Device Upload : NOT REGISTERED
)
echo.
echo [1] Device Upload Setup Instructions
echo [2] Test Apps Script Endpoint / Device State
echo [3] Open Local Reports Folder
echo [4] Back
echo.
choice /C 1234 /N /M "Select option: "
if errorlevel 4 goto MAIN_MENU
if errorlevel 3 goto OPEN_REPORTS_FOLDER
if errorlevel 2 goto TEST_REPORT_UPLOAD_MENU
if errorlevel 1 goto CONFIGURE_REPORT_UPLOAD_MENU

:CONFIGURE_REPORT_UPLOAD_MENU
call :SETUP_REPORT_UPLOAD
echo.
pause
goto MENU_REPORTS

:TEST_REPORT_UPLOAD_MENU
call :TEST_REPORT_UPLOAD_ENDPOINT
echo.
pause
goto MENU_REPORTS

:OPEN_REPORTS_FOLDER
if not exist "%TARGET_DIR%\Reports" mkdir "%TARGET_DIR%\Reports"
start "" explorer.exe "%TARGET_DIR%\Reports"
goto MENU_REPORTS

:MENU_SETUP
cls
call :RUN_SETUP
if errorlevel 1 (
    echo.
    echo [ERROR] Setup / Repair did not complete.
) else (
    >"%SETUP_MARKER%" echo Setup completed on %DATE% %TIME%
    echo.
    echo [OK] Setup / Repair completed.
)
pause
goto MAIN_MENU

:SETUP_REPORT_UPLOAD
echo.
echo ==================================================
echo       v0.1.21 FIRST-TIME DEVICE SETUP
echo ==================================================
echo.
echo Google Drive upload uses Apps Script only.
echo.
echo Steps:
echo   1. Start Tracker.
echo   2. Open the labeling tool with Tampermonkey enabled.
echo   3. Dock the tracker Left or Right.
echo   4. Click the Settings gear beside Minimize.
echo   5. Under CONTROLLER UPLOAD SETUP enter:
echo        - Apps Script /exec URL
echo        - Registration token
echo        - Agent ID
echo        - Agent name
echo        - Pod
echo   6. Click Register / Apply Device Upload Setup.
echo.
echo The controller keeps a unique Device ID and device token for this PC.
echo The registration token is not stored after registration.
if exist "%UPLOAD_CONFIG%" (
    echo.
    echo Current local device configuration:
    powershell -NoProfile -Command "$p='%UPLOAD_CONFIG%'; try{$c=Get-Content -Raw -LiteralPath $p|ConvertFrom-Json; Write-Host ('  Device ID : ' + [string]$c.deviceId); Write-Host ('  Agent ID  : ' + [string]$c.agentId); Write-Host ('  Pod       : ' + [string]$c.pod); Write-Host ('  Version   : ' + [string]$c.version)}catch{Write-Host '  Existing configuration requires re-registration.'}"
)
exit /b 0

:TEST_REPORT_UPLOAD_ENDPOINT
if not exist "%UPLOAD_CONFIG%" (
    echo [ERROR] Device upload is not registered on this PC.
    echo Use Tracker Settings ^> Controller Upload Setup first.
    exit /b 1
)
set "AUTO_TRACKER_UPLOAD_CONFIG=%UPLOAD_CONFIG%"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Stop';" ^
 "$cfg=Get-Content -LiteralPath $env:AUTO_TRACKER_UPLOAD_CONFIG -Raw | ConvertFrom-Json;" ^
 "$result=Invoke-RestMethod -Uri ([string]$cfg.endpoint) -Method Get -TimeoutSec 30;" ^
 "if($result.ok -ne $true -or [string]$result.status -ne 'ready'){throw 'The upload service did not report ready.'};" ^
 "Write-Host ('[OK] Upload service reachable: ' + [string]$result.service + ' v' + [string]$result.version);" ^
 "Write-Host ('[INFO] Auth mode: ' + [string]$result.authMode);" ^
 "Write-Host ('[INFO] Local Device ID: ' + [string]$cfg.deviceId);"
if errorlevel 1 (
    set "AUTO_TRACKER_UPLOAD_CONFIG="
    echo [ERROR] Could not verify the Apps Script upload endpoint.
    exit /b 1
)
set "AUTO_TRACKER_UPLOAD_CONFIG="
exit /b 0

:MENU_TAMPERMONKEY
cls
echo ==================================================
echo              TAMPERMONKEY
echo ==================================================
echo.
echo [1] Open Tampermonkey Extension Page
echo [2] Install / Update Current Auto Tracker
echo [3] Upgrade Legacy v0.0.8 Auto Tracker
echo [4] Load New TamperMonkey Mods Source
echo [5] Back
echo.
choice /C 12345 /N /M "Select option: "
if errorlevel 5 goto MAIN_MENU
if errorlevel 4 goto SELECT_AND_QUEUE_TAMPERMONKEY_SOURCE
if errorlevel 3 goto QUEUE_TAMPERMONKEY_LEGACY
if errorlevel 2 goto QUEUE_TAMPERMONKEY_UPDATE
if errorlevel 1 goto OPEN_TAMPERMONKEY

:OPEN_TAMPERMONKEY
start "" "https://www.tampermonkey.net/"
goto MENU_TAMPERMONKEY

:QUEUE_TAMPERMONKEY_UPDATE
call :SYNC_TAMPERMONKEY_SOURCE
if not exist "%TAMPERMONKEY_SOURCE%" (
    echo [ERROR] TamperMonkey Mods source was not found.
    pause
    goto MENU_TAMPERMONKEY
)
>"%INSTALL_SCRIPT_MARKER%" echo update
echo [OK] Auto Tracker v0.1.21 installer/updater is queued.
echo [INFO] The browser will open automatically after the controller starts.
echo [INFO] Tampermonkey will require one Install/Update confirmation click.
timeout /t 2 /nobreak >nul
goto START_TRACKER

:QUEUE_TAMPERMONKEY_LEGACY
call :SYNC_TAMPERMONKEY_SOURCE
if not exist "%TAMPERMONKEY_SOURCE%" (
    echo [ERROR] TamperMonkey Mods source was not found.
    pause
    goto MENU_TAMPERMONKEY
)
>"%INSTALL_SCRIPT_MARKER%" echo legacy-v008
echo [OK] Legacy v0.0.8 in-place upgrade is queued.
echo [INFO] Use this once on PCs that still have "Version 0.0.8 Alpha".
echo [INFO] Tampermonkey will require one Update confirmation click.
timeout /t 2 /nobreak >nul
goto START_TRACKER

:SELECT_AND_QUEUE_TAMPERMONKEY_SOURCE
call :SELECT_TAMPERMONKEY_UPDATE_SOURCE
if errorlevel 2 (
    pause
    goto MENU_TAMPERMONKEY
)
if errorlevel 1 (
    pause
    goto MENU_TAMPERMONKEY
)
>"%INSTALL_SCRIPT_MARKER%" echo update
echo [OK] New TamperMonkey Mods source loaded and update queued.
timeout /t 2 /nobreak >nul
goto START_TRACKER

:CHECK_FIRST_TIME_SETUP
if exist "%SETUP_MARKER%" exit /b 0
cls
echo ==================================================
echo          AUTO TRACKER FIRST-TIME SETUP
echo ==================================================
echo.
echo This computer has not completed Auto Tracker setup.
echo The setup will check Node.js, npm, and ExcelJS, then prepare
echo the Tampermonkey userscript installation.
echo No browser security or certificate checks will be disabled.
echo If Node.js is missing, WinGet uses only the "winget" source.
echo.
choice /C YN /N /M "Run first-time setup now? [Y/N]: "
if errorlevel 2 exit /b 1
call :RUN_SETUP
if errorlevel 1 (
    echo.
    echo [SETUP NOT COMPLETED] Auto Tracker did not mark this PC as installed.
    if defined SETUP_LOG echo [INFO] Setup log: %SETUP_LOG%
    echo [INFO] You can choose Setup / Repair and retry after correcting the message above.
    pause
    exit /b 1
)
>"%SETUP_MARKER%" echo Setup completed on %DATE% %TIME%
exit /b 0

:RUN_SETUP
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%" 2>nul
if not exist "%TARGET_DIR%" (
    echo [ERROR] Auto Tracker could not create: %TARGET_DIR%
    echo [INFO] Check Desktop folder permissions and try again.
    exit /b 1
)
if not exist "%TARGET_DIR%\Logs" mkdir "%TARGET_DIR%\Logs" 2>nul
if not exist "%TARGET_DIR%\Logs" (
    echo [ERROR] Auto Tracker could not create the Logs folder.
    exit /b 1
)
set "SETUP_LOG=%TARGET_DIR%\Logs\setup_windows.log"
>>"%SETUP_LOG%" echo.
>>"%SETUP_LOG%" echo [%DATE% %TIME%] Auto Tracker v0.1.21 setup started
>>"%SETUP_LOG%" echo [%DATE% %TIME%] Source folder: %~dp0
>>"%SETUP_LOG%" echo [%DATE% %TIME%] Target folder: %TARGET_DIR%

echo.
echo ==================================================
echo              SETUP / REPAIR
echo ==================================================
echo.
echo [STEP 1/5] Checking Node.js...
call :REFRESH_NODE_PATH
if errorlevel 1 (
    call :INSTALL_NODE_WINDOWS
    if errorlevel 1 exit /b 1
)

call :REFRESH_NODE_PATH
if errorlevel 1 (
    echo [ERROR] Node.js could not be detected after setup.
    echo [INFO] Keep this window open and use Setup / Repair again after Node.js finishes installing.
    >>"%SETUP_LOG%" echo [%DATE% %TIME%] ERROR Node.js not detected after setup
    exit /b 1
)

for /f "delims=" %%V in ('node --version 2^>nul') do set "NODE_VERSION=%%V"
echo [OK] Node.js: %NODE_VERSION%

npm --version >nul 2>nul
if errorlevel 1 (
    echo [ERROR] npm was not found even though Node.js is installed.
    echo [INFO] Please repair Node.js LTS from the official Node.js installer and run Setup / Repair again.
    >>"%SETUP_LOG%" echo [%DATE% %TIME%] ERROR npm not found
    exit /b 1
)
for /f "delims=" %%V in ('npm --version 2^>nul') do set "NPM_VERSION=%%V"
echo [OK] npm: %NPM_VERSION%

echo.
echo [STEP 2/5] Preparing Auto Tracker files...
if not exist "%TARGET_DIR%\assets" mkdir "%TARGET_DIR%\assets" 2>nul
if exist "%TRACKER_ICON_SOURCE%" (
    set "TRACKER_ICON_B64=%TRACKER_ICON_SOURCE%"
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
     "$ErrorActionPreference='Stop';" ^
     "$b64=(Get-Content -LiteralPath $env:TRACKER_ICON_B64 -Raw).Trim();" ^
     "[IO.File]::WriteAllBytes($env:TRACKER_ICON_TARGET,[Convert]::FromBase64String($b64));"
    set "TRACKER_ICON_B64="
    if errorlevel 1 (
        echo [WARN] Trinovation icon could not be prepared. Tracker will still work without the custom shortcut icon.
        >>"%SETUP_LOG%" echo [%DATE% %TIME%] WARN Trinovation icon decode failed
    ) else (
        echo [OK] Trinovation application icon prepared.
    )
) else (
    echo [WARN] assets\trinovation.ico.b64 was not included with this package.
    echo [INFO] Tracker installation can continue, but the Desktop shortcut will use the default Windows icon.
    >>"%SETUP_LOG%" echo [%DATE% %TIME%] WARN source icon missing
)
if exist "%~dp0package.json" copy /Y "%~dp0package.json" "%TARGET_DIR%\package.json" >nul
if exist "%~dp0package-lock.json" copy /Y "%~dp0package-lock.json" "%TARGET_DIR%\package-lock.json" >nul
cd /d "%TARGET_DIR%"
if not exist package.json (
    >package.json echo {
    >>package.json echo   "dependencies": {
    >>package.json echo     "exceljs": "4.4.0"
    >>package.json echo   }
    >>package.json echo }
)

echo.
echo [STEP 3/5] Installing/verifying Auto Tracker dependencies...
node -e "require('exceljs')" >nul 2>nul
if errorlevel 1 (
    echo [INFO] ExcelJS is not ready yet.
    echo [INFO] First-time dependency setup can take a few minutes on slower connections or PCs.
    echo [INFO] Using the fastest safe npm path available...
    if exist package-lock.json (
        call npm ci --omit=optional --prefer-offline --no-audit --no-fund --progress=false
    ) else (
        call npm install --save-exact exceljs@4.4.0 --omit=optional --prefer-offline --no-audit --no-fund --progress=false
    )
    if errorlevel 1 (
        echo [WARN] Fast dependency install failed. Retrying ExcelJS once with the standard registry path...
        >>"%SETUP_LOG%" echo [%DATE% %TIME%] WARN fast dependency install failed; retrying exact ExcelJS package
        timeout /t 2 /nobreak >nul
        call npm install --save-exact exceljs@4.4.0 --omit=optional --no-audit --no-fund --progress=false
    )
    if errorlevel 1 (
        echo [ERROR] npm could not install ExcelJS after retry.
        echo [INFO] Check the internet connection, then choose Setup / Repair again.
        >>"%SETUP_LOG%" echo [%DATE% %TIME%] ERROR ExcelJS install failed after retry
        exit /b 1
    )
) else (
    echo [OK] Existing Node dependencies are already available. No npm install needed.
)

node -e "require('exceljs')" >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ExcelJS verification failed after installation.
    >>"%SETUP_LOG%" echo [%DATE% %TIME%] ERROR ExcelJS verification failed
    exit /b 1
)
echo [OK] ExcelJS: READY

echo.
echo [STEP 4/5] Validating controller and Tampermonkey source...
if exist "%~dp0backend\node\server.js" (
    node --check "%~dp0backend\node\server.js" >>"%SETUP_LOG%" 2>&1
    if errorlevel 1 (
        echo [ERROR] Controller source validation failed.
        echo [INFO] Setup log: %SETUP_LOG%
        exit /b 1
    )
)
if not exist "%TAMPERMONKEY_SOURCE%" (
    echo [ERROR] Auto Tracker Tampermonkey source was not found.
    echo [INFO] Expected frontend\tampermonkey\Auto_Tracker.user.js, Tampermonkey_Modifications\TamperMonkey Mods, or a same-folder TamperMonkey Mods file.
    >>"%SETUP_LOG%" echo [%DATE% %TIME%] ERROR Tampermonkey source missing
    exit /b 1
)
node --check "%TAMPERMONKEY_SOURCE%" >>"%SETUP_LOG%" 2>&1
if errorlevel 1 (
    echo [ERROR] Tampermonkey userscript syntax validation failed.
    echo [INFO] Setup log: %SETUP_LOG%
    exit /b 1
)
echo [OK] Controller/userscript validation: PASSED

echo.
echo [STEP 5/5] Finishing Auto Tracker setup...
if exist "%UPLOAD_CONFIG%" (
    echo Apps Script device upload: CONFIGURED
) else (
    echo Apps Script device upload: NOT REGISTERED
)
echo [INFO] First-time device registration is completed from the docked tracker Settings UI.
echo [INFO] Prepare: Apps Script /exec URL, Registration Token, Department, Agent ID, Agent Name, Last Name, and Pod.
echo [INFO] Department + Pod control the exact Google Drive destination.
echo [INFO] Start the tracker, Dock Left/Right, open Settings, then use First-Time / Device Setup.

call :SYNC_TAMPERMONKEY_SOURCE
call :CREATE_APP_SHORTCUT
if errorlevel 1 (
    echo [WARN] Desktop shortcut could not be created. You can still start Auto Tracker from this BAT file.
    >>"%SETUP_LOG%" echo [%DATE% %TIME%] WARN Desktop shortcut creation failed
) else (
    echo [OK] Desktop shortcut: Trinovation Auto Count Tracker
)

if not exist "%TAMPERMONKEY_PROMPT_MARKER%" (
    echo.
    choice /C YN /N /M "Open the official Tampermonkey installation page? [Y/N]: "
    if not errorlevel 2 (
        start "" "https://www.tampermonkey.net/"
        echo Install Tampermonkey in your browser, then return here.
        pause
    )
    >"%TAMPERMONKEY_PROMPT_MARKER%" echo Tampermonkey prompt completed
)

if exist "%TARGET_DIR%\Tampermonkey_Modifications\TamperMonkey Mods" (
    choice /C YN /N /M "Open the Auto Tracker userscript when the controller starts? [Y/N]: "
    if not errorlevel 2 >"%INSTALL_SCRIPT_MARKER%" echo install
)

>>"%SETUP_LOG%" echo [%DATE% %TIME%] Setup completed successfully
echo.
echo [OK] Auto Tracker setup is complete. A restart is not required.
exit /b 0

:PREPARE_RUNTIME_CONTROLLER
if defined TRACKER_CONTROLLER_SOURCE if exist "%TRACKER_CONTROLLER_SOURCE%" (
    node --check "%TRACKER_CONTROLLER_SOURCE%" >>"%STARTUP_ERROR_LOG%" 2>&1
    if not errorlevel 1 (
        set "CURRENT_CONTROLLER_PATH=%TRACKER_CONTROLLER_SOURCE%"
        call :CONTROLLER_CANDIDATE_IS_CURRENT
        if not errorlevel 1 (
            if /I not "%TRACKER_CONTROLLER_SOURCE%"=="%TARGET_DIR%\server.js" (
                copy /Y "%TRACKER_CONTROLLER_SOURCE%" "%TARGET_DIR%\server.js" >nul
                if errorlevel 1 exit /b 1
            )
            node --check "%TARGET_DIR%\server.js" >>"%STARTUP_ERROR_LOG%" 2>&1
            if errorlevel 1 exit /b 1
            echo [OK] Controller loaded from "%TRACKER_CONTROLLER_SOURCE%".
            exit /b 0
        )
        echo [WARN] Packaged controller source is older than embedded v%EMBEDDED_CONTROLLER_VERSION%-r%EMBEDDED_CONTROLLER_REVISION%. It will not overwrite the installed controller.
    ) else (
        echo [WARN] Packaged controller source failed syntax validation and will be ignored.
    )
)

if exist "%TARGET_DIR%\server.js" (
    node --check "%TARGET_DIR%\server.js" >>"%STARTUP_ERROR_LOG%" 2>&1
    if not errorlevel 1 (
        set "CURRENT_CONTROLLER_PATH=%TARGET_DIR%\server.js"
        call :CONTROLLER_CANDIDATE_IS_CURRENT
        if not errorlevel 1 (
            echo [OK] Existing installed controller is current/newer than the embedded fallback. Keeping it.
            exit /b 0
        )
    )
)

set "startLine="
for /f "tokens=1 delims=:" %%A in ('findstr /n /c:"___JS_START___" "%~f0"') do set "startLine=%%A"
if not defined startLine exit /b 1
set /a "jsLine=startLine"
more +%jsLine% "%~f0" > "%TARGET_DIR%\server.js"
if errorlevel 1 exit /b 1
node --check "%TARGET_DIR%\server.js" >>"%STARTUP_ERROR_LOG%" 2>&1
if errorlevel 1 exit /b 1
echo [INFO] No current/newer runtime controller was available. Embedded v%EMBEDDED_CONTROLLER_VERSION%-r%EMBEDDED_CONTROLLER_REVISION% fallback loaded.
exit /b 0

:CONTROLLER_CANDIDATE_IS_CURRENT
set "CURRENT_CONTROLLER_VERSION="
set "CURRENT_CONTROLLER_REVISION=0"
for /f "tokens=4" %%V in ('findstr /R /C:"^const CONTROLLER_VERSION = " "%CURRENT_CONTROLLER_PATH%" 2^>nul') do set "CURRENT_CONTROLLER_VERSION=%%V"
for /f "tokens=4" %%R in ('findstr /R /C:"^const CONTROLLER_SOURCE_RELEASE_REVISION = " "%CURRENT_CONTROLLER_PATH%" 2^>nul') do set "CURRENT_CONTROLLER_REVISION=%%R"
if not defined CURRENT_CONTROLLER_VERSION exit /b 2
set "CURRENT_CONTROLLER_VERSION=%CURRENT_CONTROLLER_VERSION:'=%"
set "CURRENT_CONTROLLER_VERSION=%CURRENT_CONTROLLER_VERSION:;=%"
set "CURRENT_CONTROLLER_REVISION=%CURRENT_CONTROLLER_REVISION:;=%"
powershell.exe -NoLogo -NoProfile -Command "try{$current=[version]$env:CURRENT_CONTROLLER_VERSION;$embedded=[version]$env:EMBEDDED_CONTROLLER_VERSION;$revision=[int]$env:CURRENT_CONTROLLER_REVISION;$embeddedRevision=[int]$env:EMBEDDED_CONTROLLER_REVISION;if($current -gt $embedded -or ($current -eq $embedded -and $revision -ge $embeddedRevision)){exit 0}else{exit 4}}catch{exit 3}" >nul 2>&1
exit /b %errorlevel%

:CREATE_APP_SHORTCUT
set "TRACKER_SHORTCUT_TARGET=%~f0"
set "TRACKER_SHORTCUT_WORKDIR=%~dp0"
set "TRACKER_SHORTCUT_ICON=%TRACKER_ICON_TARGET%"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Stop';" ^
 "$ws=New-Object -ComObject WScript.Shell;" ^
 "$sc=$ws.CreateShortcut($env:TRACKER_SHORTCUT);" ^
 "$sc.TargetPath=$env:TRACKER_SHORTCUT_TARGET;" ^
 "$sc.WorkingDirectory=$env:TRACKER_SHORTCUT_WORKDIR;" ^
 "$sc.Description='Trinovation Auto Count Tracker';" ^
 "if(Test-Path -LiteralPath $env:TRACKER_SHORTCUT_ICON){$sc.IconLocation=$env:TRACKER_SHORTCUT_ICON + ',0'};" ^
 "$sc.Save();"
if errorlevel 1 exit /b 1
exit /b 0

:REFRESH_NODE_PATH
node --version >nul 2>nul
if not errorlevel 1 exit /b 0

if exist "%ProgramFiles%\nodejs\node.exe" (
    set "PATH=%ProgramFiles%\nodejs;%PATH%"
)
if exist "%LOCALAPPDATA%\Programs\nodejs\node.exe" (
    set "PATH=%LOCALAPPDATA%\Programs\nodejs;%PATH%"
)

node --version >nul 2>nul
if errorlevel 1 exit /b 1
exit /b 0

:INSTALL_NODE_WINDOWS
echo Node.js: NOT INSTALLED
echo.
echo Auto Tracker needs Node.js to run the local controller.
echo The automatic installer will use the WinGet "winget" source only.
echo It will not use the Microsoft Store source and will not disable certificate validation.
echo Windows may show a normal administrator/UAC confirmation for the Node.js installer.
echo.
choice /C YN /N /M "Allow Auto Tracker to install Node.js LTS? [Y/N]: "
if errorlevel 2 (
    echo [INFO] Node.js installation was skipped.
    exit /b 1
)

where winget >nul 2>nul
if not errorlevel 1 (
    echo.
    echo [INFO] Installing Node.js LTS from WinGet source "winget"...
    >>"%SETUP_LOG%" echo [%DATE% %TIME%] Running WinGet Node.js LTS install using --source winget
    winget install -e --id OpenJS.NodeJS.LTS --source winget --accept-package-agreements --accept-source-agreements
    if not errorlevel 1 (
        echo [INFO] WinGet completed. Waiting for Node.js to become available in this same Auto Tracker window...
        call :WAIT_FOR_NODE_READY
        if not errorlevel 1 (
            echo [OK] Node.js installation completed and is available now.
            exit /b 0
        )
        echo [WARN] Node.js is still not visible after automatic re-checks.
        echo [INFO] Auto Tracker will continue with the safe manual verification path.
    ) else (
        echo.
        echo [WARN] WinGet could not complete the Node.js installation.
        echo [INFO] Auto Tracker will use the official Node.js download page as a safe fallback.
        >>"%SETUP_LOG%" echo [%DATE% %TIME%] WARN WinGet Node.js installation failed
    )
) else (
    echo [INFO] Windows Package Manager ^(winget^) is not available on this PC.
)

call :WAIT_FOR_NODE_READY
if not errorlevel 1 exit /b 0
goto MANUAL_NODE_INSTALL

:WAIT_FOR_NODE_READY
set /a NODE_WAIT_ATTEMPT=0
:WAIT_FOR_NODE_READY_LOOP
call :REFRESH_NODE_PATH
if not errorlevel 1 exit /b 0
set /a NODE_WAIT_ATTEMPT+=1
if %NODE_WAIT_ATTEMPT% GEQ 6 exit /b 1
echo [INFO] Node.js is not visible yet. Re-checking... ^(%NODE_WAIT_ATTEMPT%/5^)
timeout /t 2 /nobreak >nul
goto WAIT_FOR_NODE_READY_LOOP

:MANUAL_NODE_INSTALL
echo.
echo ==================================================
echo          NODE.JS MANUAL FALLBACK
echo ==================================================
echo Auto Tracker is opening the official Node.js download page.
echo Install the LTS version. Keep this Auto Tracker window open.
echo You do NOT need to restart Auto Tracker after the installer finishes.
start "" "https://nodejs.org/en/download"

:WAIT_FOR_NODE_MANUAL
echo.
choice /C RT /N /M "After Node.js finishes installing, press R to re-check. Press T to stop setup: "
if errorlevel 2 (
    echo [INFO] Setup stopped before Node.js was installed.
    exit /b 1
)
call :REFRESH_NODE_PATH
if errorlevel 1 (
    echo [WARN] Node.js is still not detected.
    echo [INFO] Make sure the Node.js installer has completely finished, then try R again.
    goto WAIT_FOR_NODE_MANUAL
)
echo [OK] Node.js is available. Continuing setup...
exit /b 0

:SYNC_TAMPERMONKEY_SOURCE
if not defined TAMPERMONKEY_SOURCE exit /b 1
if not exist "%TAMPERMONKEY_SOURCE%" exit /b 1
if not exist "%~dp0Tampermonkey_Modifications" mkdir "%~dp0Tampermonkey_Modifications"
if not exist "%TARGET_DIR%\Tampermonkey_Modifications" mkdir "%TARGET_DIR%\Tampermonkey_Modifications"
set "TM_RUNTIME=%TARGET_DIR%\Tampermonkey_Modifications\TamperMonkey Mods"
if not exist "%TM_RUNTIME%" (
    copy /Y "%TAMPERMONKEY_SOURCE%" "%TM_RUNTIME%" >nul
    if errorlevel 1 exit /b 1
    echo [OK] Initial TamperMonkey Mods copied to controller runtime.
) else (
    fc /b "%TAMPERMONKEY_SOURCE%" "%TM_RUNTIME%" >nul 2>nul
    if errorlevel 1 (
        copy /Y "%TAMPERMONKEY_SOURCE%" "%TM_RUNTIME%" >nul
        if errorlevel 1 exit /b 1
        echo [UPDATED] Controller runtime TamperMonkey Mods synchronized.
    )
)
findstr /C:"// ==UserScript==" "%TM_RUNTIME%" >nul 2>nul
if errorlevel 1 exit /b 1
findstr /C:"// ==/UserScript==" "%TM_RUNTIME%" >nul 2>nul
if errorlevel 1 exit /b 1
exit /b 0

:SELECT_TAMPERMONKEY_UPDATE_SOURCE
REM Selects a userscript file, validates it, compares binary content,
REM and overwrites only when the selected source is different.
if not exist "%TARGET_DIR%\Tampermonkey_Modifications" mkdir "%TARGET_DIR%\Tampermonkey_Modifications"
set "SELECTED_TM_FILE="
for /f "usebackq delims=" %%F in (`powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $d=New-Object System.Windows.Forms.OpenFileDialog; $d.Title='Select the new TamperMonkey Mods file'; $d.Filter='TamperMonkey Mods|TamperMonkey Mods|JavaScript userscript (*.js)|*.js|All files (*.*)|*.*'; if($d.ShowDialog() -eq 'OK'){[Console]::WriteLine($d.FileName)}"`) do set "SELECTED_TM_FILE=%%F"
if not defined SELECTED_TM_FILE (
    echo [INFO] Tampermonkey update cancelled.
    exit /b 2
)
findstr /C:"// ==UserScript==" "%SELECTED_TM_FILE%" >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Selected file is not a valid Tampermonkey userscript.
    exit /b 1
)
findstr /C:"// ==/UserScript==" "%SELECTED_TM_FILE%" >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Selected file is missing the userscript metadata end marker.
    exit /b 1
)
set "TM_TARGET=%TAMPERMONKEY_SOURCE%"
if exist "%TM_TARGET%" (
    fc /b "%SELECTED_TM_FILE%" "%TM_TARGET%" >nul 2>nul
    if not errorlevel 1 (
        echo [CURRENT] Selected TamperMonkey Mods is identical to the controller copy.
        findstr /R /C:"^// @version " "%TM_TARGET%" 2>nul
        exit /b 2
    )
)
copy /Y "%SELECTED_TM_FILE%" "%TM_TARGET%" >nul
if errorlevel 1 (
    echo [ERROR] Could not replace the controller TamperMonkey Mods file.
    exit /b 1
)
echo [UPDATED] New TamperMonkey Mods content detected and copied.
findstr /R /C:"^// @version " "%TM_TARGET%" 2>nul
exit /b 0

:QUEUE_TAMPERMONKEY_SCRIPT
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
call :SYNC_TAMPERMONKEY_SOURCE
if not exist "%TARGET_DIR%\Tampermonkey_Modifications\TamperMonkey Mods" (
    echo [ERROR] TamperMonkey Mods was not found in the designated folder.
    exit /b 1
)
>"%INSTALL_SCRIPT_MARKER%" echo install
exit /b 0

:START_TRACKER
cls

set "BACKUP_DIR=%TARGET_DIR%\Backups"
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
if not exist "%TARGET_DIR%\Logs" mkdir "%TARGET_DIR%\Logs"
set "STARTUP_ERROR_LOG=%TARGET_DIR%\Logs\controller_startup_errors.log"
call :SYNC_TAMPERMONKEY_SOURCE
if errorlevel 1 (
    echo [ERROR] Tampermonkey source could not be prepared.
    echo [INFO] Expected one of:
    echo        %~dp0frontend\tampermonkey\Auto_Tracker.user.js
    echo        %~dp0Tampermonkey_Modifications\TamperMonkey Mods
    echo        %~dp0TamperMonkey Mods
    pause
    goto START
)
cd /d "%TARGET_DIR%"
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do if not defined LDT set "LDT=%%I"

if defined LDT (
    set "BACKUP_TIMESTAMP=%LDT:~0,8%_%LDT:~8,6%"
) else (
    set "BACKUP_TIMESTAMP=%RANDOM%_%RANDOM%"
)

set "CURRENT_BACKUP=%BACKUP_DIR%\%BACKUP_TIMESTAMP%"

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
if not exist "%CURRENT_BACKUP%" mkdir "%CURRENT_BACKUP%"

if exist server.js (
    copy /Y "server.js" "%CURRENT_BACKUP%\server.js" >nul
)

if exist stats.json (
    copy /Y "stats.json" "%CURRENT_BACKUP%\stats.json" >nul
)
if exist mode2_stats.json copy /Y "mode2_stats.json" "%CURRENT_BACKUP%\mode2_stats.json" >nul
if exist report-upload-config.json copy /Y "report-upload-config.json" "%CURRENT_BACKUP%\report-upload-config.json" >nul
if exist .tracker-integrity-key copy /Y ".tracker-integrity-key" "%CURRENT_BACKUP%\.tracker-integrity-key" >nul
if exist .tracker-integrity.json copy /Y ".tracker-integrity.json" "%CURRENT_BACKUP%\.tracker-integrity.json" >nul
if exist .tracker-report-settings.json copy /Y ".tracker-report-settings.json" "%CURRENT_BACKUP%\.tracker-report-settings.json" >nul
if exist .tracker-tampermonkey-identity.json copy /Y ".tracker-tampermonkey-identity.json" "%CURRENT_BACKUP%\.tracker-tampermonkey-identity.json" >nul
if exist .tracker-device-id copy /Y ".tracker-device-id" "%CURRENT_BACKUP%\.tracker-device-id" >nul
if exist Integrity_Quarantine xcopy /E /I /Y "Integrity_Quarantine" "%CURRENT_BACKUP%\Integrity_Quarantine" >nul
if exist Tampermonkey_Modifications xcopy /E /I /Y "Tampermonkey_Modifications" "%CURRENT_BACKUP%\Tampermonkey_Modifications" >nul

if exist dashboard.html (
    copy /Y "dashboard.html" "%CURRENT_BACKUP%\dashboard.html" >nul
)

if exist dashboard.js (
    copy /Y "dashboard.js" "%CURRENT_BACKUP%\dashboard.js" >nul
)

if exist dashboard.css (
    copy /Y "dashboard.css" "%CURRENT_BACKUP%\dashboard.css" >nul
)

if exist Logs (
    xcopy /E /I /Y "Logs" "%CURRENT_BACKUP%\Logs" >nul
)

if exist Reports (
    xcopy /E /I /Y "Reports" "%CURRENT_BACKUP%\Reports" >nul
)

echo Backup: %CURRENT_BACKUP%
echo Tampermonkey source: %TRACKER_TAMPERMONKEY_SOURCE%

call :PREPARE_RUNTIME_CONTROLLER
if errorlevel 1 (
    echo [ERROR] Auto Tracker could not prepare a valid controller.
    echo [INFO] Details were saved to: %STARTUP_ERROR_LOG%
    pause
    goto START
)

echo [OK] Node Controller verified on disk.
echo [INFO] Controller and Tampermonkey source passed setup validation.
echo Launching Node Backend Engine...
echo ==================================================

node --check server.js 2>> "%STARTUP_ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Controller syntax validation failed.
    echo [INFO] Details were saved to: %STARTUP_ERROR_LOG%
    pause
    goto START
)
echo [INFO] Human activity log: Logs\YYYY-MM-DD.txt
echo [INFO] Structured activity log: Logs\activity_YYYY-MM-DD.ndjson
echo [INFO] Structured error log: Logs\errors_YYYY-MM-DD.txt
set "TRACKER_REUSE_RUNNING_CONTROLLER="
call :ENSURE_PORT_9000_FREE
if errorlevel 1 (
    echo [ERROR] Auto Tracker could not safely claim local port 9000.
    echo [INFO] If the message above names another program, close that program or contact IT Support.
    echo [INFO] If an older Auto Tracker is stuck, use Setup / Repair or restart Windows, then try again.
    pause
    goto START
)
if defined TRACKER_REUSE_RUNNING_CONTROLLER (
    echo.
    echo [OK] Auto Tracker v%PORT_9000_TRACKER_VERSION%-r%PORT_9000_TRACKER_REVISION% is already running on port 9000.
    echo [INFO] Reusing the existing controller. A second copy will not be started.
    timeout /t 2 /nobreak >nul
    goto MAIN_MENU
)
node server.js

echo.
echo ==================================================
echo Server stopped.
echo ==================================================
echo.
echo [R] Restart Server
echo [Q] Quit
choice /C RQ /N /M "Select: "

if errorlevel 2 exit /b 0
if errorlevel 1 goto START
goto :EOF

:ENSURE_PORT_9000_FREE
set "PORT_9000_PID="
set "PORT_9000_PROCESS="
set "PORT_9000_IS_TRACKER=0"
set "PORT_9000_TRACKER_CURRENT=0"
set "PORT_9000_TRACKER_VERSION="
set "PORT_9000_TRACKER_REVISION=0"
set "PORT_9000_SHIFT_STARTED=0"

for /f "usebackq delims=" %%P in (`powershell.exe -NoLogo -NoProfile -Command "$c=@(Get-NetTCPConnection -LocalPort 9000 -State Listen -ErrorAction SilentlyContinue);if($c.Count -gt 0){[Console]::WriteLine($c[0].OwningProcess)}"`) do set "PORT_9000_PID=%%P"
if not defined PORT_9000_PID exit /b 0

for /f "usebackq delims=" %%Q in (`powershell.exe -NoLogo -NoProfile -Command "$p=Get-Process -Id %PORT_9000_PID% -ErrorAction SilentlyContinue;if($p){[Console]::WriteLine($p.ProcessName)}else{[Console]::WriteLine('unknown')}"`) do set "PORT_9000_PROCESS=%%Q"

for /f "usebackq tokens=1,2,3 delims=|" %%V in (`powershell.exe -NoLogo -NoProfile -Command "try{$s=Invoke-RestMethod -Uri 'http://127.0.0.1:9000/stats' -TimeoutSec 2 -ErrorAction Stop;if($null -ne $s.controllerVersion){$r=0;if($null -ne $s.controllerRevision){$r=[int]$s.controllerRevision};$active=if($s.shiftStarted){1}else{0};[Console]::WriteLine(([string]$s.controllerVersion)+'|'+$r+'|'+$active)}}catch{}"`) do (
    set "PORT_9000_TRACKER_VERSION=%%V"
    set "PORT_9000_TRACKER_REVISION=%%W"
    set "PORT_9000_SHIFT_STARTED=%%X"
    set "PORT_9000_IS_TRACKER=1"
)

echo.
echo [WARN] Port 9000 is already in use by PID %PORT_9000_PID% ^(%PORT_9000_PROCESS%^).

if "%PORT_9000_IS_TRACKER%"=="1" (
    powershell.exe -NoLogo -NoProfile -Command "try{$current=[version]$env:PORT_9000_TRACKER_VERSION;$embedded=[version]$env:EMBEDDED_CONTROLLER_VERSION;$revision=[int]$env:PORT_9000_TRACKER_REVISION;$embeddedRevision=[int]$env:EMBEDDED_CONTROLLER_REVISION;if($current -gt $embedded -or ($current -eq $embedded -and $revision -ge $embeddedRevision)){exit 0}else{exit 4}}catch{exit 3}" >nul 2>&1
    if not errorlevel 1 set "PORT_9000_TRACKER_CURRENT=1"
    echo [INFO] Verified Auto Tracker controller detected: v%PORT_9000_TRACKER_VERSION%-r%PORT_9000_TRACKER_REVISION%.
)

if "%PORT_9000_TRACKER_CURRENT%"=="1" (
    set "TRACKER_REUSE_RUNNING_CONTROLLER=1"
    exit /b 0
)

if not "%PORT_9000_IS_TRACKER%"=="1" (
    echo [ERROR] The listener did not identify itself as Trinovation Auto Tracker.
    echo [INFO] For safety, this launcher will not terminate an unrelated program.
    exit /b 1
)

if /I not "%PORT_9000_PROCESS%"=="node" (
    echo [ERROR] The verified tracker listener is not a Node.js process. It will not be terminated automatically.
    exit /b 1
)

if "%PORT_9000_SHIFT_STARTED%"=="1" (
    echo [ERROR] An older Auto Tracker has an active shift.
    echo [INFO] End the shift normally before replacing/restarting the controller so counters and reports are preserved.
    exit /b 1
)

choice /C YN /N /M "An older Auto Tracker is running. Stop it and start Rev2? [Y/N]: "
if errorlevel 2 exit /b 1
taskkill /PID %PORT_9000_PID% /T /F >nul 2>&1
if errorlevel 1 powershell.exe -NoLogo -NoProfile -Command "Stop-Process -Id %PORT_9000_PID% -Force -ErrorAction SilentlyContinue" >nul 2>&1

for /L %%W in (1,1,10) do (
    powershell.exe -NoLogo -NoProfile -Command "if(@(Get-NetTCPConnection -LocalPort 9000 -State Listen -ErrorAction SilentlyContinue).Count -gt 0){exit 1}else{exit 0}" >nul 2>&1
    if not errorlevel 1 (
        echo [OK] Old Auto Tracker controller stopped.
        exit /b 0
    )
    timeout /t 1 /nobreak >nul
)
echo [ERROR] The previous Auto Tracker did not release port 9000 after 10 seconds.
exit /b 1

:: DO NOT TOUCH THE LINE BELOW
___JS_START___
const http = require('http');
const readline = require('readline');
const fs = require('fs');
const path = require('path');
const https = require('https');
const { exec, execFile, execFileSync } = require('child_process');
const crypto = require('crypto');
const jobTasks = {};


// =========================================
// FUNCTION DEBUG LOG
// Search: debugLog
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
const debugLog = (...args) => {

    if (process.env.TRACKER_DEBUG === '1') console.log(...args);

};
const ExcelJS = require("exceljs");
let trackingMode = Number(process.env.TRACKER_MODE) || null;
const statsFile = path.join(__dirname, 'stats.json');
const DATA_DIR = __dirname;
const mode2StatsFile = path.join(DATA_DIR, "mode2_stats.json");
const logsFolder = path.join(__dirname, "Logs");
const reportsFolder = path.join(__dirname, "Reports");
const reportUploadConfigFile = path.join(__dirname, "report-upload-config.json");
const deviceIdentityFile = path.join(__dirname, ".tracker-device-id");
const tampermonkeyScriptFile = process.env.TRACKER_TAMPERMONKEY_SOURCE
    ? path.resolve(process.env.TRACKER_TAMPERMONKEY_SOURCE)
    : path.join(__dirname, "Tampermonkey_Modifications", "TamperMonkey Mods");
const controllerSourceFile = process.env.TRACKER_CONTROLLER_SOURCE
    ? path.resolve(process.env.TRACKER_CONTROLLER_SOURCE)
    : null;
const installTampermonkeyMarker = path.join(__dirname, ".install_tampermonkey_script");

const integrityKeyFile = path.join(__dirname, '.tracker-integrity-key');
const integrityManifestFile = path.join(__dirname, '.tracker-integrity.json');
const integrityQuarantineFolder = path.join(__dirname, 'Integrity_Quarantine');
const reportSettingsFile = path.join(__dirname, '.tracker-report-settings.json');
const tampermonkeyIdentityFile = path.join(__dirname, '.tracker-tampermonkey-identity.json');
const uploadVerificationFile = path.join(__dirname, '.tracker-upload-verification.json');
const uploadQueueFile = path.join(__dirname, '.tracker-upload-queue.json');
const browserIdentityFile = path.join(__dirname, '.tracker-browser.json');
const REPORT_SHEET_PROTECTION_LABEL = 'auto-tracker-v12-report';
const BIO_SESSION_SECONDS = Math.max(1, Number(process.env.TRACKER_BIO_SECONDS || 15 * 60));
const HBIO_SESSION_SECONDS = Math.max(1, Number(process.env.TRACKER_HBIO_SECONDS || 10 * 60));
const SPECIAL_SESSION_COUNT = Math.max(1, Math.floor(Number(process.env.TRACKER_SPECIAL_SESSION_COUNT || 1)));
const PRODUCTIVITY_MIN_ACTIVE_SECONDS = Math.max(60, Math.floor(Number(process.env.TRACKER_PRODUCTIVITY_MIN_ACTIVE_SECONDS || 5 * 60)));
const CONTROLLER_VERSION = '0.1.21';
const CONTROLLER_SOURCE_RELEASE_REVISION = 2;
const CONTROLLER_RELEASE_REVISION = Math.max(
    CONTROLLER_SOURCE_RELEASE_REVISION,
    Math.max(0, Math.floor(Number(process.env.TRACKER_RELEASE_REVISION ?? CONTROLLER_SOURCE_RELEASE_REVISION)))
);
const SHIFT_WORK_MINUTES = Math.max(1, Math.floor(Number(process.env.TRACKER_SHIFT_WORK_MINUTES || 360)));
const SHIFT_BREAK_MINUTES = Math.max(0, Math.floor(Number(process.env.TRACKER_SHIFT_BREAK_MINUTES || 30)));
const DAY_SHIFT_LUNCH_MINUTES = Math.max(SHIFT_BREAK_MINUTES, Math.floor(Number(process.env.TRACKER_DAY_SHIFT_LUNCH_MINUTES || 60)));
const ENCORD_WORK_MINUTES = Math.max(1, Math.floor(Number(process.env.TRACKER_ENCORD_WORK_MINUTES || 480)));
const ENCORD_BREAK_MINUTES = Math.max(0, Math.floor(Number(process.env.TRACKER_ENCORD_BREAK_MINUTES || 30)));
const ENCORD_LUNCH_MINUTES = Math.max(0, Math.floor(Number(process.env.TRACKER_ENCORD_LUNCH_MINUTES || 60)));
const DAY_SHIFT_START_HOUR = Math.max(0, Math.min(23, Math.floor(Number(process.env.TRACKER_DAY_SHIFT_START_HOUR || 8))));
const DAY_SHIFT_END_HOUR = Math.max(DAY_SHIFT_START_HOUR, Math.min(23, Math.floor(Number(process.env.TRACKER_DAY_SHIFT_END_HOUR || 11))));
const SHIFT_REGULAR_WINDOW_MINUTES = SHIFT_WORK_MINUTES + SHIFT_BREAK_MINUTES;
const LOCAL_RETENTION_DAYS = Math.max(1, Math.floor(Number(process.env.TRACKER_LOCAL_RETENTION_DAYS || 7)));
const IDLE_HIGHLIGHT_SECONDS = 60 * 60;
const MAX_API_BODY_BYTES = Math.max(64 * 1024, Math.floor(Number(process.env.TRACKER_MAX_API_BODY_BYTES || 1024 * 1024)));

const LOG_SCHEMA_VERSION = 2;
const PROCESS_INSTANCE_ID = 'PROC-' + crypto.randomBytes(6).toString('hex').toUpperCase();

function createTraceId(prefix = 'TRACE') {
    const safePrefix = String(prefix || 'TRACE').toUpperCase().replace(/[^A-Z0-9_-]/g, '').slice(0, 12) || 'TRACE';
    return safePrefix + '-' + Date.now().toString(36).toUpperCase() + '-' + crypto.randomBytes(4).toString('hex').toUpperCase();
}

function trackerRuntimeLogContext() {
    return {
        controllerVersion: CONTROLLER_VERSION,
        controllerRevision: CONTROLLER_RELEASE_REVISION,
        processInstanceId: PROCESS_INSTANCE_ID,
        pid: process.pid,
        nodeVersion: process.version,
        platform: process.platform,
        arch: process.arch
    };
}

function sanitizeStructuredLogValue(value, maxStringLength = 2000) {
    try {
        return JSON.parse(JSON.stringify(value == null ? {} : value, (key, item) => {
            if (/token|secret|password|authorization|cookie|fileBase64/i.test(key)) return item ? '[REDACTED]' : item;
            if (typeof item === 'string') return redactSensitiveLogText(item, maxStringLength);
            return item;
        }));
    } catch {
        return { loggingError: 'Context could not be serialized safely.' };
    }
}

function collectErrorCauses(error) {
    const causes = [];
    const seen = new Set();
    let current = error;
    while (current && causes.length < 5 && !seen.has(current)) {
        seen.add(current);
        causes.push({
            name: redactSensitiveLogText(current.name || 'Error', 120),
            message: redactSensitiveLogText(current.message || String(current), 1200),
            code: redactSensitiveLogText(current.code || '', 160)
        });
        current = current.cause instanceof Error ? current.cause : null;
    }
    return causes;
}

function resolveSupportHint(errorCode, component, message) {
    const haystack = (String(errorCode || '') + ' ' + String(component || '') + ' ' + String(message || '')).toUpperCase();
    if (/UPLOAD|DRIVE|APPS.?SCRIPT|DEVICE_(TOKEN|REGISTRATION)|CHECKSUM/.test(haystack)) {
        return 'Check device registration, Apps Script endpoint reachability, upload credentials, and the local retry queue.';
    }
    if (/REPORT|WORKBOOK|EXCEL|SNAPSHOT/.test(haystack)) {
        return 'Check report settings, signed snapshot integrity, Reports folder permissions, and the most recent report-generation event.';
    }
    if (/INTEGRITY|QUARANTINE/.test(haystack)) {
        return 'Inspect Integrity_Quarantine and restore controller-managed state before retrying the operation.';
    }
    if (/FRONTEND|TAMPERMONKEY|API|SSE|CONNECTION|JSON/.test(haystack)) {
        return 'Confirm 127.0.0.1:9000 is reachable, the controller is running, and controller/userscript versions and revisions match.';
    }
    if (/BROWSER|UPDATE|RELEASE/.test(haystack)) {
        return 'Check browser detection, update/release configuration, and whether the update URL can be opened from this device.';
    }
    if (/RETENTION|DELETE|PERMISSION|EACCES|EPERM/.test(haystack)) {
        return 'Check filesystem permissions and retention state. Do not manually remove unverified report bundles.';
    }
    return 'Use the trace ID and nearby activity events to identify the action immediately before this error.';
}

function writeStructuredActivityLog(eventName, details = {}, options = {}) {
    try {
        if (!fs.existsSync(logsFolder)) fs.mkdirSync(logsFolder, { recursive: true });
        const now = new Date();
        const dateKey = new Intl.DateTimeFormat('en-CA', {
            timeZone: 'Asia/Manila',
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }).format(now);
        const severity = String(options.severity || 'INFO').toUpperCase();
        const component = String(options.component || 'TRACKER').toUpperCase().replace(/[^A-Z0-9_-]/g, '').slice(0, 24) || 'TRACKER';
        const eventCode = String(options.eventCode || ('EVT-' + component + '-GENERAL')).toUpperCase().replace(/[^A-Z0-9_-]/g, '').slice(0, 96);
        const traceId = redactSensitiveLogText(options.traceId || '', 120);
        const record = {
            schemaVersion: LOG_SCHEMA_VERSION,
            eventId: createTraceId('EVT'),
            traceId: traceId || null,
            timestampIso: now.toISOString(),
            timestampPH: now.toLocaleString('en-US', { timeZone: 'Asia/Manila', hour12: true }),
            severity,
            component,
            eventCode,
            eventName: String(eventName || 'tracker.activity').slice(0, 120),
            runtime: trackerRuntimeLogContext(),
            details: sanitizeStructuredLogValue(details, 3000)
        };
        fs.appendFileSync(path.join(logsFolder, 'activity_' + dateKey + '.ndjson'), JSON.stringify(record) + '\n', 'utf8');
        return record;
    } catch {
        return null;
    }
}


// =========================================
// FUNCTION REDACT SENSITIVE LOG TEXT
// Search: redactSensitiveLogText
// Ver 0.1.16 Alpha || 2026-09-28 || JBallados || Error_Log_Redaction
// =========================================
function redactSensitiveLogText(value, maxLength = 8000) {

    let text = String(value ?? '');
    text = text
        .replace(/(Bearer\s+)[A-Za-z0-9._~+\/-]+/gi, '$1[REDACTED]')
        .replace(/((?:registrationToken|deviceToken|teamLeadToken|authorization|password|secret|cookie)\s*["']?\s*[:=]\s*["']?)[^"',}\s]+/gi, '$1[REDACTED]')
        .replace(/\b[a-f0-9]{64}\b/gi, '[REDACTED_TOKEN]');
    return text.slice(0, Math.max(0, Number(maxLength) || 0));

}

// =========================================
// FUNCTION WRITE CONTROLLER ERROR LOG
// Search: writeControllerErrorLog
// Ver 0.1.16 Alpha || 2026-09-28 || JBallados || Error_Logging
// =========================================
function writeControllerErrorLog(source, error, context = {}) {

    try {
        if (!fs.existsSync(logsFolder)) fs.mkdirSync(logsFolder, { recursive: true });
        const now = new Date();
        const dateKey = new Intl.DateTimeFormat('en-CA', {
            timeZone: 'Asia/Manila',
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }).format(now);
        const timestampPH = now.toLocaleString('en-US', {
            timeZone: 'Asia/Manila',
            hour12: true
        });
        const redactedContext = sanitizeStructuredLogValue(context || {}, 2500);
        const message = redactSensitiveLogText(error instanceof Error ? error.message : String(error || 'Unknown error'), 3000);
        const stack = error instanceof Error && error.stack ? redactSensitiveLogText(error.stack, 10000) : '';
        const severity = String(redactedContext.severity || 'ERROR').toUpperCase();
        const component = String(redactedContext.component || source || 'CTRL').toUpperCase().replace(/[^A-Z0-9_-]/g, '').slice(0, 24) || 'CTRL';
        const errorCode = String(redactedContext.errorCode || ('ERR-' + component + '-GENERIC')).toUpperCase().replace(/[^A-Z0-9_-]/g, '').slice(0, 96);
        const traceId = redactSensitiveLogText(redactedContext.traceId || '', 120) || createTraceId('ERRTRACE');
        const supportHint = redactSensitiveLogText(
            redactedContext.supportHint || resolveSupportHint(errorCode, component, message),
            1200
        );
        const record = {
            schemaVersion: LOG_SCHEMA_VERSION,
            eventId: createTraceId('ERR'),
            traceId,
            timestamp: timestampPH,
            timestampIso: now.toISOString(),
            timestampPH,
            severity,
            component,
            errorCode,
            source: String(source || 'CONTROLLER').slice(0, 80),
            controllerVersion: CONTROLLER_VERSION,
            controllerRevision: CONTROLLER_RELEASE_REVISION,
            errorName: redactSensitiveLogText(error instanceof Error ? error.name : 'Error', 120),
            message,
            stack,
            causeChain: error instanceof Error ? collectErrorCauses(error) : [],
            supportHint,
            runtime: trackerRuntimeLogContext(),
            context: redactedContext
        };
        fs.appendFileSync(path.join(logsFolder, 'errors_' + dateKey + '.txt'), JSON.stringify(record) + '\n', 'utf8');
        writeStructuredActivityLog('tracker.error', {
            errorCode,
            source: record.source,
            message,
            supportHint
        }, {
            severity,
            component,
            eventCode: 'EVT-' + component + '-ERROR',
            traceId
        });
        return record;
    } catch {
        return null;
    }

}

function getRecentDiagnosticErrors(limit = 20) {

    const maxItems = Math.max(1, Math.min(100, Number(limit) || 20));
    if (!fs.existsSync(logsFolder)) return [];
    const files = fs.readdirSync(logsFolder)
        .filter(name => /^errors_\d{4}-\d{2}-\d{2}\.txt$/i.test(name))
        .map(name => ({ name, fullPath: path.join(logsFolder, name) }))
        .sort((a, b) => b.name.localeCompare(a.name));

    const records = [];
    for (const file of files) {
        let lines = [];
        try { lines = fs.readFileSync(file.fullPath, 'utf8').split(/\r?\n/).filter(Boolean).reverse(); } catch { continue; }
        for (const line of lines) {
            try {
                const parsed = JSON.parse(line);
                records.push({
                    eventId: parsed.eventId || '',
                    traceId: parsed.traceId || '',
                    timestamp: parsed.timestampPH || parsed.timestamp || '',
                    severity: parsed.severity || 'ERROR',
                    component: parsed.component || parsed.source || 'CTRL',
                    errorCode: parsed.errorCode || 'ERR-CTRL-GENERIC',
                    source: parsed.source || '',
                    controllerVersion: parsed.controllerVersion || CONTROLLER_VERSION,
                    controllerRevision: parsed.controllerRevision ?? CONTROLLER_RELEASE_REVISION,
                    message: redactSensitiveLogText(parsed.message || '', 1000),
                    supportHint: redactSensitiveLogText(parsed.supportHint || '', 1000)
                });
            } catch {
                records.push({
                    eventId: '',
                    traceId: '',
                    timestamp: '',
                    severity: 'ERROR',
                    component: 'CTRL',
                    errorCode: 'ERR-CTRL-LEGACY',
                    source: 'LEGACY',
                    controllerVersion: CONTROLLER_VERSION,
                    controllerRevision: CONTROLLER_RELEASE_REVISION,
                    message: redactSensitiveLogText(line, 1000),
                    supportHint: 'Legacy log entry. Review nearby activity events for additional context.'
                });
            }
            if (records.length >= maxItems) return records;
        }
    }
    return records;

}

function buildDiagnosticExportText() {

    const upload = getPublicReportUploadSettings();
    const browser = loadTrackerBrowserInfo();
    const queue = readJsonStateFile(uploadQueueFile, { version: 1, items: [] });
    const recentErrors = getRecentDiagnosticErrors(50);
    const lines = [
        'TRINOVATION AUTO COUNT TRACKER - DIAGNOSTIC EXPORT',
        'Generated: ' + new Date().toLocaleString('en-US', { timeZone: 'Asia/Manila', hour12: true }),
        'Controller: v' + CONTROLLER_VERSION + '-r' + CONTROLLER_RELEASE_REVISION,
        'Process Instance: ' + PROCESS_INSTANCE_ID,
        'Log Schema: v' + LOG_SCHEMA_VERSION,
        'Tampermonkey Source: v' + (getTampermonkeyScriptInfo().version || 'Unknown'),
        'Browser: ' + (browser?.name || 'Unknown'),
        'System Health: ' + getSystemHealth().status,
        'Device Registration: ' + (upload.deviceRegistered ? 'Registered' : 'Not Registered'),
        'Agent ID: ' + (upload.agentId || 'Not configured'),
        'Department: ' + (upload.department || 'OOS'),
        'Pod: ' + (upload.pod || 'Not configured'),
        'Shift Active: ' + (shiftStarted ? 'Yes' : 'No'),
        'Shift Report Date: ' + (shiftReportDate || 'N/A'),
        'Pending Uploads: ' + (Array.isArray(queue.items) ? queue.items.length : 0),
        'Latest Release: ' + (latestReleaseState?.latestVersion ? 'v' + latestReleaseState.latestVersion : 'Unknown'),
        '',
        'RECENT ERRORS'
    ];
    if (!recentErrors.length) lines.push('No recent structured errors.');
    for (const item of recentErrors) {
        lines.push(
            '[' + (item.timestamp || 'Unknown time') + ']'
            + ' [' + item.severity + ']'
            + ' [' + item.component + ']'
            + ' [' + item.errorCode + ']'
            + (item.traceId ? ' [Trace:' + item.traceId + ']' : '')
            + ' ' + item.message
            + (item.supportHint ? ' | Suggested check: ' + item.supportHint : '')
        );
    }
    lines.push('', 'Sensitive credential values are redacted/not included in this export.');
    return lines.join('\n');

}

// =========================================
// FUNCTION INSTALL CONTROLLER ERROR HANDLERS
// Search: installControllerErrorHandlers
// Ver 0.1.16 Alpha || 2026-09-28 || JBallados || Error_Logging
// =========================================
function installControllerErrorHandlers() {

    process.on('unhandledRejection', reason => {
        const error = reason instanceof Error ? reason : new Error(String(reason || 'Unhandled rejection'));
        writeControllerErrorLog('UNHANDLED_REJECTION', error);
        console.error('[ERROR LOG] Unhandled rejection:', error.message);
    });
    process.on('uncaughtException', error => {
        writeControllerErrorLog('UNCAUGHT_EXCEPTION', error);
        console.error('[ERROR LOG] Uncaught exception:', error.message);
        setTimeout(() => process.exit(1), 100);
    });

}

installControllerErrorHandlers();

function sanitizeLastName(value) {
    return String(value || '').trim()
        .replace(/[<>:"/\\|?*\x00-\x1F]/g, '_')
        .replace(/\s+/g, '_')
        .replace(/_+/g, '_')
        .replace(/^_+|_+$/g, '')
        .slice(0, 80);
}

function normalizeDepartment(value, fallback = '') {
    const department = String(value || fallback || '').trim().toUpperCase();
    if (department === 'CWH') return 'OOS';
    return ['OOS', 'ENCORD'].includes(department) ? department : '';
}

function sha256Text(value) {
    return crypto.createHash('sha256').update(String(value)).digest('hex');
}

function sha256File(filePath) {
    if (!filePath || !fs.existsSync(filePath)) return null;
    return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex');
}

function ensureIntegrityKey() {
    if (process.env.TRACKER_INTEGRITY_KEY) return String(process.env.TRACKER_INTEGRITY_KEY);
    if (fs.existsSync(integrityKeyFile)) return fs.readFileSync(integrityKeyFile, 'utf8').trim();
    const key = crypto.randomBytes(32).toString('hex');
    fs.writeFileSync(integrityKeyFile, key + '\n', { encoding: 'utf8', mode: 0o600 });
    try { fs.chmodSync(integrityKeyFile, 0o600); } catch {}
    return key;
}

const integrityKey = ensureIntegrityKey();

// =========================================
// FUNCTION ENSURE LOCAL DEVICE ID
// Search: ensureLocalDeviceId
// Ver 0.1.14 Alpha || 2026-09-27 || JBallados || Per_Device_Credentials
// =========================================
function ensureLocalDeviceId() {

    if (process.env.TRACKER_DEVICE_ID && /^DEV-[A-Za-z0-9_-]{8,64}$/.test(String(process.env.TRACKER_DEVICE_ID))) {
        return String(process.env.TRACKER_DEVICE_ID);
    }
    try {
        if (fs.existsSync(deviceIdentityFile)) {
            const existing = String(fs.readFileSync(deviceIdentityFile, 'utf8') || '').trim();
            if (/^DEV-[A-Za-z0-9_-]{8,64}$/.test(existing)) return existing;
        }
    } catch {}

    const deviceId = 'DEV-' + crypto.randomUUID().replace(/-/g, '').slice(0, 16).toUpperCase();
    fs.writeFileSync(deviceIdentityFile, deviceId + '\n', { encoding: 'utf8', mode: 0o600 });
    try { fs.chmodSync(deviceIdentityFile, 0o600); } catch {}
    return deviceId;

}

const localDeviceId = ensureLocalDeviceId();
let integrityCompromised = false;

function hmacBuffer(buffer) {
    return crypto.createHmac('sha256', integrityKey).update(buffer).digest('hex');
}

function readIntegrityManifest() {
    try {
        if (!fs.existsSync(integrityManifestFile)) return { version: 1, files: {} };
        const parsed = JSON.parse(fs.readFileSync(integrityManifestFile, 'utf8'));
        return { version: 1, ...parsed, files: { ...(parsed.files || {}) } };
    } catch {
        return { version: 1, files: {} };
    }
}

function writeIntegrityManifest(manifest) {
    const temp = integrityManifestFile + '.tmp';
    fs.writeFileSync(temp, JSON.stringify(manifest, null, 2), 'utf8');
    fs.renameSync(temp, integrityManifestFile);
}

function recordFileIntegrity(filePath, label) {
    if (!fs.existsSync(filePath)) return;
    const raw = fs.readFileSync(filePath);
    const manifest = readIntegrityManifest();
    manifest.files[label] = {
        sha256: crypto.createHash('sha256').update(raw).digest('hex'),
        hmac: hmacBuffer(raw),
        updatedAt: Date.now()
    };
    writeIntegrityManifest(manifest);
}

function quarantineIntegrityFailure(filePath, label) {
    try {
        fs.mkdirSync(integrityQuarantineFolder, { recursive: true });
        const stamp = new Date().toISOString().replace(/[:.]/g, '-');
        fs.copyFileSync(filePath, path.join(integrityQuarantineFolder, stamp + '_' + label + path.extname(filePath)));
    } catch (error) {
        console.error('Could not quarantine integrity failure:', error.message);
    }
}

function verifyFileIntegrity(filePath, label, adoptIfMissing = true) {
    if (!fs.existsSync(filePath)) return true;
    const raw = fs.readFileSync(filePath);
    const manifest = readIntegrityManifest();
    const expected = manifest.files[label];
    if (!expected) {
        if (adoptIfMissing) {
            recordFileIntegrity(filePath, label);
            console.log('Integrity baseline created for ' + path.basename(filePath) + '.');
            return true;
        }
        return false;
    }
    const actualSha = crypto.createHash('sha256').update(raw).digest('hex');
    const actualHmac = hmacBuffer(raw);
    const ok = expected.sha256 === actualSha && expected.hmac === actualHmac;
    if (!ok) {
        integrityCompromised = true;
        quarantineIntegrityFailure(filePath, label);
        console.error('INTEGRITY CHECK FAILED: ' + path.basename(filePath) + ' changed outside the controller.');
    }
    return ok;
}

function writeProtectedJson(filePath, data, label) {
    const temp = filePath + '.tmp';
    fs.writeFileSync(temp, JSON.stringify(data, null, 2), 'utf8');
    fs.renameSync(temp, filePath);
    recordFileIntegrity(filePath, label);
}

function assertStateIntegrity() {
    const statsOk = verifyFileIntegrity(statsFile, 'stats', true);
    const mode2Ok = verifyFileIntegrity(mode2StatsFile, 'mode2_stats', true);
    if (!statsOk || !mode2Ok || integrityCompromised) {
        throw new Error('INTEGRITY_CHECK_FAILED: controller state was modified outside Auto Tracker. Check Integrity_Quarantine.');
    }
}

function reportProtectionPassword() {
    return crypto.createHmac('sha256', integrityKey).update(REPORT_SHEET_PROTECTION_LABEL).digest('hex').slice(0, 24);
}

// =========================================
// FUNCTION CURRENT DAILY REPORT TARGET
// Search: currentDailyReportTarget
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function currentDailyReportTarget(lastName, reportDate, department = getShiftDepartment()) {

    const reportDepartment = normalizeDepartment(department || 'OOS', 'OOS') || 'OOS';
    const stem = sanitizeLastName(lastName) + '_' + reportDate + '_' + reportDepartment;
    return {
        version: null,
        stem,
        reportPath: path.join(reportsFolder, stem + '.xlsx'),
        logPath: path.join(reportsFolder, stem + '.txt'),
        snapshotPath: path.join(reportsFolder, stem + '.snapshot.json'),
        integrityPath: path.join(reportsFolder, stem + '.integrity.json')
    };

}

// =========================================
// FUNCTION PREPARE REPORT TARGET FOR OVERWRITE
// Search: prepareReportTargetForOverwrite
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function prepareReportTargetForOverwrite(target) {

    for (const filePath of [target.reportPath, target.logPath, target.snapshotPath, target.integrityPath]) {
        try {
            if (fs.existsSync(filePath)) fs.chmodSync(filePath, 0o644);
        } catch {}
    }

}

let reportSettings = {
    lastName: ''
};

// =========================================
// FUNCTION LOAD REPORT SETTINGS
// Search: loadReportSettings
// Ver 0.1.15 Alpha || 2026-09-28 || JBallados || AppsScript_Only_Cleanup
// Ver 0.1.16 Alpha || 2026-09-28 || JBallados || First_Time_Setup
// =========================================
function loadReportSettings() {

    if (!fs.existsSync(reportSettingsFile)) return reportSettings;
    try {
        const parsed = JSON.parse(fs.readFileSync(reportSettingsFile, 'utf8'));
        const { hmac, ...core } = parsed || {};
        const expected = crypto.createHmac('sha256', integrityKey).update(JSON.stringify(core)).digest('hex');
        if (!hmac || hmac !== expected) {
            console.error('REPORT SETTINGS INTEGRITY FAILED: ignoring local report settings.');
            return reportSettings;
        }
        reportSettings = {
            lastName: sanitizeLastName(core.lastName)
        };
    } catch (error) {
        console.error('Could not load report settings:', error.message);
    }
    return reportSettings;

}

// =========================================
// FUNCTION SAVE REPORT SETTINGS
// Search: saveReportSettings
// Ver 0.1.15 Alpha || 2026-09-28 || JBallados || AppsScript_Only_Cleanup
// Ver 0.1.16 Alpha || 2026-09-28 || JBallados || First_Time_Setup
// =========================================
function saveReportSettings(nextSettings) {

    const core = {
        lastName: sanitizeLastName(nextSettings?.lastName),
        updatedAt: Date.now()
    };
    const hmac = crypto.createHmac('sha256', integrityKey).update(JSON.stringify(core)).digest('hex');
    const temp = reportSettingsFile + '.tmp';
    fs.writeFileSync(temp, JSON.stringify({ ...core, hmac }, null, 2), 'utf8');
    fs.renameSync(temp, reportSettingsFile);
    try { fs.chmodSync(reportSettingsFile, 0o600); } catch {}
    reportSettings = { lastName: core.lastName };
    return reportSettings;

}

// =========================================
// FUNCTION GET PUBLIC REPORT SETTINGS
// Search: getPublicReportSettings
// Ver 0.1.15 Alpha || 2026-09-28 || JBallados || AppsScript_Only_Cleanup
// Ver 0.1.16 Alpha || 2026-09-28 || JBallados || First_Time_Setup
// =========================================
function getPublicReportSettings() {

    const appsScript = loadReportUploadConfig();
    return {
        lastName: reportSettings.lastName,
        driveConfigured: Boolean(appsScript),
        driveMode: appsScript ? 'apps-script' : 'unconfigured',
        podNumber: appsScript ? (String(appsScript.pod || '').match(/\d+/)?.[0] || null) : null,
        podLabel: appsScript?.pod || null,
        setupComplete: Boolean(appsScript && reportSettings.lastName && appsScript.lastName === reportSettings.lastName),
        reportFileExample: reportSettings.lastName ? reportSettings.lastName + '_YYYY-MM-DD_' + (normalizeDepartment(appsScript?.department || shiftDepartment || 'OOS', 'OOS') || 'OOS') + '.xlsx' : ''
    };

}

// =========================================
// FUNCTION CONFIGURE REPORT SETTINGS
// Search: configureReportSettings
// Ver 0.1.15 Alpha || 2026-09-28 || JBallados || AppsScript_Only_Cleanup
// Ver 0.1.16 Alpha || 2026-09-28 || JBallados || First_Time_Setup
// =========================================
function configureReportSettings(payload) {

    const lastName = sanitizeLastName(payload?.lastName || reportSettings.lastName);
    if (!lastName) return { success: false, error: 'LAST_NAME_REQUIRED' };
    saveReportSettings({ lastName });
    return { success: true, reportSettings: getPublicReportSettings() };

}

function copyDailyLogSnapshot(targetPath, reportDate) {
    const datedSource = path.join(logsFolder, String(reportDate || '') + '.txt');
    const source = fs.existsSync(datedSource) ? datedSource : getTodayLogFile();
    if (fs.existsSync(source)) fs.copyFileSync(source, targetPath);
    else fs.writeFileSync(targetPath, '', 'utf8');
}

// =========================================
// FUNCTION WRITE SIGNED SOURCE SNAPSHOT
// Search: writeSignedSourceSnapshot
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function writeSignedSourceSnapshot(target, reportDate, sourceSnapshot) {

    const core = {
        schemaVersion: 2,
        reportDate,
        generatedAt: Date.now(),
        source: sourceSnapshot
    };
    const hmac = crypto.createHmac('sha256', integrityKey).update(JSON.stringify(core)).digest('hex');
    fs.writeFileSync(target.snapshotPath, JSON.stringify({ ...core, hmac }, null, 2), 'utf8');
    return target.snapshotPath;

}

// =========================================
// FUNCTION CREATE REPORT INTEGRITY MANIFEST
// Search: createReportIntegrityManifest
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function createReportIntegrityManifest(target, reportDate, sourceSnapshot) {

    const core = {
        schemaVersion: 2,
        reportDate,
        generatedAt: Date.now(),
        reportFile: path.basename(target.reportPath),
        reportSha256: sha256File(target.reportPath),
        logFile: path.basename(target.logPath),
        logSha256: sha256File(target.logPath),
        sourceSnapshotFile: path.basename(target.snapshotPath),
        sourceSnapshotSha256: sha256File(target.snapshotPath),
        sourceContentSha256: sha256Text(JSON.stringify(sourceSnapshot)),
        statsSha256: sha256File(statsFile),
        mode2StatsSha256: sha256File(mode2StatsFile)
    };
    const manifest = { ...core, hmac: crypto.createHmac('sha256', integrityKey).update(JSON.stringify(core)).digest('hex') };
    fs.writeFileSync(target.integrityPath, JSON.stringify(manifest, null, 2), 'utf8');
    return manifest;

}

function verifyGeneratedReport(reportPath) {
    const integrityPath = String(reportPath || '').replace(/\.xlsx$/i, '.integrity.json');
    if (!fs.existsSync(reportPath) || !fs.existsSync(integrityPath)) return { ok: false, error: 'REPORT_OR_MANIFEST_MISSING' };
    try {
        const manifest = JSON.parse(fs.readFileSync(integrityPath, 'utf8'));
        const { hmac, ...core } = manifest;
        const signed = crypto.createHmac('sha256', integrityKey).update(JSON.stringify(core)).digest('hex');
        const reportOk = core.reportSha256 === sha256File(reportPath);
        const logPath = path.join(path.dirname(reportPath), core.logFile || '');
        const logOk = Boolean(core.logFile) && fs.existsSync(logPath) && core.logSha256 === sha256File(logPath);
        const snapshotPath = path.join(path.dirname(reportPath), core.sourceSnapshotFile || '');
        let snapshotOk = false;
        let snapshotSignatureOk = false;
        if (core.sourceSnapshotFile && fs.existsSync(snapshotPath) && core.sourceSnapshotSha256 === sha256File(snapshotPath)) {
            try {
                const snapshot = JSON.parse(fs.readFileSync(snapshotPath, 'utf8'));
                const { hmac: snapshotHmac, ...snapshotCore } = snapshot;
                const expectedSnapshotHmac = crypto.createHmac('sha256', integrityKey).update(JSON.stringify(snapshotCore)).digest('hex');
                snapshotSignatureOk = snapshotHmac === expectedSnapshotHmac;
                snapshotOk = snapshotSignatureOk;
            } catch {}
        }
        return {
            ok: Boolean(hmac === signed && reportOk && logOk && snapshotOk),
            reportOk,
            logOk,
            snapshotOk,
            signatureOk: hmac === signed,
            snapshotSignatureOk
        };
    } catch (error) {
        return { ok: false, error: error.message };
    }
}

function findLatestGeneratedReport() {
    if (!fs.existsSync(reportsFolder)) return null;
    return fs.readdirSync(reportsFolder)
        .filter(name => /\.xlsx$/i.test(name))
        .map(name => path.join(reportsFolder, name))
        .sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs)[0] || null;
}

// =========================================
// FUNCTION MARK REPORT BUNDLE READ ONLY
// Search: markReportBundleReadOnly
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function markReportBundleReadOnly(target) {

    for (const filePath of [target.reportPath, target.logPath, target.snapshotPath, target.integrityPath]) {
        try { if (fs.existsSync(filePath)) fs.chmodSync(filePath, 0o444); } catch {}
    }

}
if (!fs.existsSync(reportsFolder)) {
    fs.mkdirSync(reportsFolder, {
        recursive: true
    });
}
if (!fs.existsSync(logsFolder)) {
    fs.mkdirSync(logsFolder);
}
loadReportSettings();
const SHIFT = {
    interval1: { name: "Interval 1", startOffsetMinutes: 0, endOffsetMinutes: 120 },
    interval2: { name: "Interval 2", startOffsetMinutes: 120, endOffsetMinutes: 240 },
    interval3: { name: "Interval 3", startOffsetMinutes: 240, endOffsetMinutes: SHIFT_REGULAR_WINDOW_MINUTES },
    workMinutes: SHIFT_WORK_MINUTES,
    breakMinutes: SHIFT_BREAK_MINUTES,
    dayShiftLunchMinutes: DAY_SHIFT_LUNCH_MINUTES,
    dayShiftStartHour: DAY_SHIFT_START_HOUR,
    dayShiftEndHour: DAY_SHIFT_END_HOUR,
    regularWindowMinutes: SHIFT_REGULAR_WINDOW_MINUTES
};
let allTimeTasks = 0;
let totalTaskCompleted = 0;
let totalJobsCompleted = 0;
let trackerStartupComplete = false;
let latestReleaseState = { configured: false, updateAvailable: false, latestVersion: null, release: null, checkedAt: null };
let lastUpdateInstallState = { state: 'NONE', version: null, revision: null, stagedAt: null, backupFolder: null, restartRequired: false };
let lastReportStatus = { state: 'NONE', generatedAt: null, reportFileName: null, drive: null };
let mode2TaskCompleted = 0;
let mode2JobsCompleted = 0;
let mode2DeletedBoxes = 0;
let mode2EmptyAreaConfirmation = 0;
let mode2EmptyAreaNoMatchFound = 0;
let mode2UnblurredPerson = 0;
let mode2SkippedTask = 0;
let mode2Stats = {
    mode2TaskCompleted: 0,
    mode2JobsCompleted: 0,
    mode2DeletedBoxes: 0,
    mode2EmptyAreaConfirmation: 0,
    mode2EmptyAreaNoMatchFound: 0,
    mode2UnblurredPerson: 0,
    mode2SkippedTask: 0
};
let statsCoverageRecoverySnapshot = null;

// =========================================
// FUNCTION SYNC MODE2 STATS
// Search: syncMode2Stats
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function syncMode2Stats() {

    mode2Stats.mode2DeletedBoxes = mode2DeletedBoxes;
    mode2Stats.mode2TaskCompleted = mode2TaskCompleted;
    mode2Stats.mode2JobsCompleted = mode2JobsCompleted;
    mode2Stats.mode2EmptyAreaConfirmation = mode2EmptyAreaConfirmation;
    mode2Stats.mode2EmptyAreaNoMatchFound = mode2EmptyAreaNoMatchFound;
    mode2Stats.mode2UnblurredPerson = mode2UnblurredPerson;
    mode2Stats.mode2SkippedTask = mode2SkippedTask;

}
let completedJobs = [];
let currentJobId = "";
let currentJobUrl = "";
let currentJobDescription = "";
let jobStartedAt = Date.now();
let jobConfirmed = false;
const idleSessions = [];
let lastTotalTasksDone = 0;
let lastLogTimePH = "RESET DONE";
let lastStatusPH = "WAITING";
let shiftStarted = false;
let shiftStartedAt = null;
let shiftEndedAt = null;
let shiftReportDate = null;
let shiftDepartment = null;
let earlyManualIntervalAdvance = null;
let overtimeStats = { tasks: 0, jobs: 0, activeMs: 0, idleMs: 0, breakMs: 0, bioMs: 0, hbioMs: 0 };
let idleStartTime = null;
let idleStartDisplay = "";
let totalIdleSeconds = 0;
let totalActiveSeconds = 0;
let modeTiming = {
    mode1: {
        activeMs: 0,
        idleMs: 0,
        breakMs: 0,
        bioMs: 0,
        hbioMs: 0
    },
    mode2: {
        activeMs: 0,
        idleMs: 0,
        breakMs: 0,
        bioMs: 0,
        hbioMs: 0
    }
};
let legacyUnassignedTiming = {
    activeSeconds: 0,
    idleSeconds: 0
};
let timingSegmentStartedAt = Date.now();
let timingSegmentMode = trackingMode;
let timingSegmentStatus = lastStatusPH;
let lastJobFinished = null;
let clients = [];
let idleReason = "Unknown";
let pendingJobId = "";
let pendingJobUrl = "";
let pendingJobDescription = "";
const processedSubmitRequests = new Map();
const REQUEST_ID_EXPIRY_MS = 5 * 60 * 1000;

// =========================================
// FUNCTION CLEANUP PROCESSED SUBMIT REQUESTS
// Search: cleanupProcessedSubmitRequests
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function cleanupProcessedSubmitRequests(now = Date.now()) {

    const referenceTime = Number(now || Date.now());
    for (const [requestId, timestamp] of processedSubmitRequests) {
        if (!Number.isFinite(Number(timestamp)) || referenceTime - Number(timestamp) > REQUEST_ID_EXPIRY_MS) {
            processedSubmitRequests.delete(requestId);
        }
    }

}

function restoreProcessedSubmitRequests(raw, now = Date.now()) {

    processedSubmitRequests.clear();
    const referenceTime = Number(now || Date.now());
    const entries = Array.isArray(raw)
        ? raw
        : raw && typeof raw === 'object'
            ? Object.entries(raw)
            : [];
    for (const entry of entries) {
        if (!Array.isArray(entry) || entry.length < 2) continue;
        const requestId = String(entry[0] || '').trim();
        const timestamp = Number(entry[1] || 0);
        if (!requestId || !Number.isFinite(timestamp) || timestamp <= 0) continue;
        if (referenceTime - timestamp < 0 || referenceTime - timestamp > REQUEST_ID_EXPIRY_MS) continue;
        processedSubmitRequests.set(requestId, timestamp);
    }

}
// =========================================
// FUNCTION MODE KEY FOR
// Search: modeKeyFor
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// =========================================
function modeKeyFor(mode) {

    if (Number(mode) === 1) return 'mode1';
    if (Number(mode) === 2) return 'mode2';
    return null;

}

// =========================================
// FUNCTION MODE TIMING SNAPSHOT FROM RAW
// Search: modeTimingSnapshotFromRaw
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function modeTimingSnapshotFromRaw(rawTiming, legacy = legacyUnassignedTiming) {

    const readMode = key => {
        const sourceMode = rawTiming?.[key] || {};
        return {
            activeSeconds: Math.max(0, Math.floor(Number(sourceMode.activeMs || 0) / 1000)),
            idleSeconds: Math.max(0, Math.floor(Number(sourceMode.idleMs || 0) / 1000)),
            breakSeconds: Math.max(0, Math.floor(Number(sourceMode.breakMs || 0) / 1000)),
            bioSeconds: Math.max(0, Math.floor(Number(sourceMode.bioMs || 0) / 1000)),
            hbioSeconds: Math.max(0, Math.floor(Number(sourceMode.hbioMs || 0) / 1000))
        };
    };
    const mode1 = readMode('mode1');
    const mode2 = readMode('mode2');
    const unassigned = {
        activeSeconds: Math.max(0, Math.floor(Number(legacy?.activeSeconds || 0))),
        idleSeconds: Math.max(0, Math.floor(Number(legacy?.idleSeconds || 0))),
        breakSeconds: 0,
        bioSeconds: 0,
        hbioSeconds: 0
    };
    return {
        mode1,
        mode2,
        unassigned,
        combined: {
            activeSeconds: mode1.activeSeconds + mode2.activeSeconds + unassigned.activeSeconds,
            idleSeconds: mode1.idleSeconds + mode2.idleSeconds + unassigned.idleSeconds,
            breakSeconds: mode1.breakSeconds + mode2.breakSeconds,
            bioSeconds: mode1.bioSeconds + mode2.bioSeconds,
            hbioSeconds: mode1.hbioSeconds + mode2.hbioSeconds
        }
    };

}

// =========================================
// FUNCTION GET MODE TIMING SNAPSHOT
// Search: getModeTimingSnapshot
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function getModeTimingSnapshot(now = Date.now()) {

    const copy = {
        mode1: { ...modeTiming.mode1 },
        mode2: { ...modeTiming.mode2 }
    };
    const key = modeKeyFor(timingSegmentMode);
    if (shiftStarted && key) {
        const elapsed = Math.max(0, now - timingSegmentStartedAt);
        const status = String(timingSegmentStatus || 'ACTIVE').toUpperCase();
        const field = status === 'IDLE' ? 'idleMs'
            : status === 'BREAK' ? 'breakMs'
            : status === 'BIO' ? 'bioMs'
            : status === 'HBIO' ? 'hbioMs'
            : 'activeMs';
        copy[key][field] += elapsed;
    }
    return modeTimingSnapshotFromRaw(copy, legacyUnassignedTiming);

}

// =========================================
// FUNCTION SYNC LEGACY TIMING
// Search: syncLegacyTiming
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// =========================================
function syncLegacyTiming(now = Date.now()) {

    const snapshot = getModeTimingSnapshot(now);
    totalActiveSeconds = snapshot.combined.activeSeconds;
    totalIdleSeconds = snapshot.combined.idleSeconds;

}

// =========================================
// FUNCTION SETTLE MODE TIMING
// Search: settleModeTiming
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function settleModeTiming(now = Date.now()) {

    const key = modeKeyFor(timingSegmentMode);
    const elapsed = Math.max(0, now - timingSegmentStartedAt);
    if (shiftStarted && key && elapsed > 0) {
        const status = String(timingSegmentStatus || 'ACTIVE').toUpperCase();
        const field = status === 'IDLE' ? 'idleMs'
            : status === 'BREAK' ? 'breakMs'
            : status === 'BIO' ? 'bioMs'
            : status === 'HBIO' ? 'hbioMs'
            : 'activeMs';
        modeTiming[key][field] += elapsed;
        accumulateOvertimeTiming(timingSegmentStartedAt, now, status);
    }
    timingSegmentStartedAt = now;
    syncLegacyTiming(now);

}

// =========================================
// FUNCTION SWITCH TIMING STATE
// Search: switchTimingState
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// =========================================
function switchTimingState(nextMode, nextStatus, now = Date.now()) {

    settleModeTiming(now);
    timingSegmentMode = Number(nextMode);
    timingSegmentStatus = nextStatus || 'ACTIVE';
    timingSegmentStartedAt = now;
    syncLegacyTiming(now);

}

// =========================================
// FUNCTION RESET MODE TIMING
// Search: resetModeTiming
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function resetModeTiming() {

    modeTiming = {
        mode1: { activeMs: 0, idleMs: 0, breakMs: 0, bioMs: 0, hbioMs: 0 },
        mode2: { activeMs: 0, idleMs: 0, breakMs: 0, bioMs: 0, hbioMs: 0 }
    };
    legacyUnassignedTiming = { activeSeconds: 0, idleSeconds: 0 };
    timingSegmentStartedAt = Date.now();
    timingSegmentMode = trackingMode;
    timingSegmentStatus = lastStatusPH;
    syncLegacyTiming();

}

// =========================================
// FUNCTION LOAD MODE TIMING
// Search: loadModeTiming
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function loadModeTiming(stats) {

    const saved = stats?.modeTiming;
    const readMode = key => ({
        activeMs: Math.max(0, Number(saved?.[key]?.activeMs ?? Number(saved?.[key]?.activeSeconds || 0) * 1000) || 0),
        idleMs: Math.max(0, Number(saved?.[key]?.idleMs ?? Number(saved?.[key]?.idleSeconds || 0) * 1000) || 0),
        breakMs: Math.max(0, Number(saved?.[key]?.breakMs ?? Number(saved?.[key]?.breakSeconds || 0) * 1000) || 0),
        bioMs: Math.max(0, Number(saved?.[key]?.bioMs ?? Number(saved?.[key]?.bioSeconds || 0) * 1000) || 0),
        hbioMs: Math.max(0, Number(saved?.[key]?.hbioMs ?? Number(saved?.[key]?.hbioSeconds || 0) * 1000) || 0)
    });
    modeTiming = {
        mode1: readMode('mode1'),
        mode2: readMode('mode2')
    };
    if (saved) {
        legacyUnassignedTiming = {
            activeSeconds: Math.max(0, Number(stats?.legacyUnassignedTiming?.activeSeconds || 0)),
            idleSeconds: Math.max(0, Number(stats?.legacyUnassignedTiming?.idleSeconds || 0))
        };
    } else {
        legacyUnassignedTiming = {
            activeSeconds: Math.max(0, Number(stats?.totalActiveSeconds || 0)),
            idleSeconds: Math.max(0, Number(stats?.totalIdleSeconds || 0))
        };
    }
    timingSegmentStartedAt = Date.now();
    timingSegmentMode = trackingMode;
    timingSegmentStatus = lastStatusPH;
    syncLegacyTiming();

}

// =========================================
// FUNCTION FINISH IDLE SESSION
// Search: finishIdleSession
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// =========================================
function normalizeClientTimingTimestamp(value, fallback = Date.now()) {

    const now = Number(fallback || Date.now());
    const candidate = Number(value);
    if (!Number.isFinite(candidate) || candidate <= 0) return now;
    const shiftFloor = Math.max(0, Number(shiftStartedAt || 0));
    const segmentFloor = Math.max(0, Number(timingSegmentStartedAt || 0));
    const lowerBound = Math.max(shiftFloor, segmentFloor, now - 12 * 60 * 60 * 1000);
    return Math.min(now, Math.max(lowerBound, candidate));

}

function finishIdleSession(endTime = Date.now()) {

    if (!idleStartTime) return 0;
    const idleSeconds = Math.max(0, Math.floor((endTime - idleStartTime) / 1000));
    jobIdleSeconds += idleSeconds;
    const idleEndDisplay = new Date(endTime).toLocaleTimeString('en-US', {
        timeZone: 'Asia/Manila',
        hour12: true
    });
    idleSessions.push({
        jobId: currentJobId,
        mode: jobTrackingMode,
        started: idleStartDisplay,
        ended: idleEndDisplay,
        duration: idleSeconds
    });
    fs.appendFileSync(getTodayLogFile(), `
	=========================================================
	IDLE SESSION
	Date          : ${new Date(endTime).toLocaleDateString('en-US', { timeZone: 'Asia/Manila' })}
	Job ID        : ${currentJobId}
	Mode          : ${jobTrackingMode === 2 ? 'COVERAGE' : 'CONFIRMATION'}
	Idle Started  : ${idleStartDisplay}
	Idle Ended    : ${idleEndDisplay}
	Duration      : ${formatDuration(idleSeconds)}
	=========================================================
`);
    idleStartTime = null;
    idleStartDisplay = '';
    return idleSeconds;

}

// =========================================
// FUNCTION CALCULATE EFFICIENCY
// Search: calculateEfficiency
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// =========================================
function calculateEfficiency(activeSeconds, idleSeconds) {

    const active = Math.max(0, Number(activeSeconds || 0));
    const idle = Math.max(0, Number(idleSeconds || 0));
    const tracked = active + idle;
    if (tracked <= 0) return null;
    return Math.round(active / tracked * 10000) / 100;

}

// =========================================
// FUNCTION CALCULATE PRODUCTIVITY
// Search: calculateProductivity
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// =========================================
function calculateProductivity(tasks, activeSeconds) {

    const active = Math.max(0, Number(activeSeconds || 0));
    if (active < PRODUCTIVITY_MIN_ACTIVE_SECONDS) return null;
    return Math.round(Number(tasks || 0) / (active / 3600) * 100) / 100;

}

// =========================================
// FUNCTION FORMAT PRODUCTIVITY
// Search: formatProductivity
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function formatProductivity(tasks, activeSeconds) {

    const active = Math.max(0, Number(activeSeconds || 0));
    const productivity = calculateProductivity(tasks, active);
    if (productivity !== null) return productivity + ' tasks/hour';
    if (active <= 0) return 'N/A';
    return 'N/A (minimum ' + Math.ceil(PRODUCTIVITY_MIN_ACTIVE_SECONDS / 60) + 'm active)';

}

let intervalHistory = [];
let currentIntervalNumber = 1;
let currentInterval = {
    number: 1,
    started: Date.now(),
    ended: null,
    tasks: 0,
    jobs: 0,
    jobRecords: []
};
let intervalStats = {
    interval1: {
        jobs: [],
        tasks: 0,
        idle: 0,
        active: 0
    },
    interval2: {
        jobs: [],
        tasks: 0,
        idle: 0,
        active: 0
    },
    interval3: {
        jobs: [],
        tasks: 0,
        idle: 0,
        active: 0
    }
};
let onBreak = false;
let breakTimer = null;
let breakStart = null;
let breakSessions = [];

// =========================================
// FUNCTION GET BREAK USED SECONDS
// Search: getBreakUsedSeconds
// Ver 0.0.8 Alpha || 2026-09-15 || JBallados
// =========================================
function getBreakUsedSeconds(now = Date.now(), requestedKind = 'AUTO') {

    const policy = getShiftPolicy();
    let kind = String(requestedKind || 'AUTO').trim().toUpperCase();
    if (kind === 'AUTO') kind = currentBreakKind() || policy.pauseKinds[0];
    let used = 0;
    for (const session of breakSessions) {
        if (session && session.ended && pauseSessionKind(session) === kind) {
            used += Math.max(0, Number(session.duration || 0));
        }
    }
    if (onBreak && breakStart && currentBreakKind() === kind) {
        used += Math.max(0, Math.floor((now - breakStart) / 1000));
    }
    return used;

}

// =========================================
// FUNCTION GET BREAK STATE
// Search: getBreakState
// Ver 0.0.8 Alpha || 2026-09-15 || JBallados
// Ver 0.1.21 Rev1 || 2026-10-03 || JBallados || Department_Pause_Policy
// =========================================
function getBreakState(now = Date.now(), requestedKind = 'AUTO') {

    const policy = getShiftPolicy();
    const requested = String(requestedKind || 'AUTO').trim().toUpperCase();
    const kind = requested === 'AUTO' ? (currentBreakKind() || policy.pauseKinds[0]) : requested;
    const supported = policy.pauseKinds.includes(kind);
    if (!supported) {
        return {
            onBreak: false,
            totalSeconds: 0,
            usedSeconds: 0,
            remainingSeconds: 0,
            available: false,
            expired: true,
            supported: false,
            allowanceMinutes: 0,
            kind,
            label: kind === 'LUNCH' ? 'Lunch Break' : 'Break',
            activeKind: currentBreakKind(),
            availableKinds: [...policy.pauseKinds],
            department: policy.department
        };
    }
    const allowanceMinutes = getShiftBreakMinutes(shiftStartedAt, kind);
    const totalSeconds = Math.max(0, Number(allowanceMinutes || 0) * 60);
    const usedSeconds = Math.min(totalSeconds, getBreakUsedSeconds(now, kind));
    const remainingSeconds = Math.max(0, totalSeconds - usedSeconds);
    const activeKind = currentBreakKind();
    return {
        onBreak: Boolean(onBreak && activeKind === kind),
        anyPauseActive: Boolean(onBreak),
        totalSeconds,
        usedSeconds,
        remainingSeconds,
        available: !onBreak && remainingSeconds > 0,
        expired: remainingSeconds <= 0,
        supported: true,
        allowanceMinutes,
        kind,
        label: getShiftBreakLabel(shiftStartedAt, kind),
        activeKind,
        availableKinds: [...policy.pauseKinds],
        department: policy.department
    };

}

function getPauseStates(now = Date.now()) {
    return { break: getBreakState(now, 'BREAK'), lunch: getBreakState(now, 'LUNCH') };
}


function createSpecialAllowance(type) {
    const totalSeconds = type === 'HBIO' ? HBIO_SESSION_SECONDS : BIO_SESSION_SECONDS;
    return {
        type,
        totalSeconds,
        maxSessions: SPECIAL_SESSION_COUNT,
        usedSeconds: Array(SPECIAL_SESSION_COUNT).fill(0),
        history: []
    };
}

let specialSessions = {
    date: coverageDate(),
    BIO: createSpecialAllowance('BIO'),
    HBIO: createSpecialAllowance('HBIO'),
    active: null
};
let specialSessionTimer = null;

function normalizeSpecialAllowance(raw, type) {
    const base = createSpecialAllowance(type);
    const source = raw || {};
    const used = Array.isArray(source.usedSeconds) ? source.usedSeconds : [];
    base.usedSeconds = Array.from({ length: SPECIAL_SESSION_COUNT }, (_, index) =>
        Math.min(base.totalSeconds, Math.max(0, Math.floor(Number(used[index] || 0))))
    );
    base.history = Array.isArray(source.history) ? source.history : [];
    return base;
}

function normalizeSpecialSessions(raw) {
    const today = trackingDate();
    const source = raw || {};
    return {
        date: source.date || today,
        BIO: normalizeSpecialAllowance(source.BIO, 'BIO'),
        HBIO: normalizeSpecialAllowance(source.HBIO, 'HBIO'),
        active: source.active && ['BIO', 'HBIO'].includes(source.active.type) ? {
            type: source.active.type,
            sessionIndex: Math.max(0, Math.min(SPECIAL_SESSION_COUNT - 1, Number(source.active.sessionIndex || 0))),
            startedAt: Number(source.active.startedAt || Date.now()),
            remainingAtStart: Math.max(0, Number(source.active.remainingAtStart || 0)),
            mode: Number(source.active.mode) === 2 ? 2 : 1
        } : null
    };
}

function resetSpecialSessions(date = trackingDate()) {
    if (specialSessionTimer !== null) clearTimeout(specialSessionTimer);
    specialSessionTimer = null;
    specialSessions = {
        date,
        BIO: createSpecialAllowance('BIO'),
        HBIO: createSpecialAllowance('HBIO'),
        active: null
    };
    if (lastStatusPH === 'BIO' || lastStatusPH === 'HBIO') {
        switchTimingState(trackingMode, 'ACTIVE', Date.now());
        lastStatusPH = 'ACTIVE';
    }
}

function ensureSpecialSessionDate() {
    const today = trackingDate();
    if (specialSessions.date === today) return;
    resetSpecialSessions(today);
    saveStats();
    broadcastToBrowser('special_sessions_daily_reset');
}

function getSpecialAllowanceState(type, now = Date.now()) {
    const allowance = specialSessions[type];
    if (!allowance) return null;
    const used = [...allowance.usedSeconds];
    if (specialSessions.active?.type === type) {
        const active = specialSessions.active;
        const elapsed = Math.max(0, Math.floor((now - active.startedAt) / 1000));
        const liveUsed = Math.min(active.remainingAtStart, elapsed);
        used[active.sessionIndex] = Math.min(allowance.totalSeconds, used[active.sessionIndex] + liveUsed);
    }
    let currentIndex = used.findIndex(value => value < allowance.totalSeconds);
    if (currentIndex < 0) currentIndex = allowance.maxSessions;
    const exhausted = currentIndex >= allowance.maxSessions;
    const currentRemaining = exhausted ? 0 : Math.max(0, allowance.totalSeconds - used[currentIndex]);
    const sessionsRemainingAfterCurrent = exhausted ? 0 : Math.max(0, allowance.maxSessions - currentIndex - 1);
    return {
        type,
        totalSecondsPerSession: allowance.totalSeconds,
        maxSessions: allowance.maxSessions,
        currentSession: exhausted ? allowance.maxSessions : currentIndex + 1,
        currentRemainingSeconds: currentRemaining,
        sessionsRemainingAfterCurrent,
        exhausted,
        usedSeconds: used,
        active: specialSessions.active?.type === type
    };
}

function getSpecialSessionState(now = Date.now()) {
    return {
        date: specialSessions.date,
        activeType: specialSessions.active?.type || null,
        BIO: getSpecialAllowanceState('BIO', now),
        HBIO: getSpecialAllowanceState('HBIO', now)
    };
}

function startSpecialSession(type) {
    const normalized = String(type || '').toUpperCase();
    if (!['BIO', 'HBIO'].includes(normalized)) {
        return { success: false, error: 'INVALID_SPECIAL_SESSION' };
    }
    ensureSpecialSessionDate();
    if (onBreak || specialSessions.active) {
        return {
            success: false,
            error: 'PAUSE_ALREADY_ACTIVE',
            message: 'Resume the current Break/BIO/HBIO session before starting another.',
            status: lastStatusPH,
            breakState: getBreakState(),
            specialSessionState: getSpecialSessionState()
        };
    }
    const allowance = specialSessions[normalized];
    const sessionIndex = allowance.usedSeconds.findIndex(value => value < allowance.totalSeconds);
    if (sessionIndex < 0) {
        return {
            success: false,
            error: normalized + '_ALLOWANCE_FINISHED',
            message: normalized + ' daily session allowance is fully consumed.',
            status: lastStatusPH,
            specialSessionState: getSpecialSessionState()
        };
    }
    const remainingAtStart = Math.max(0, allowance.totalSeconds - allowance.usedSeconds[sessionIndex]);
    if (remainingAtStart <= 0) {
        return { success: false, error: normalized + '_ALLOWANCE_FINISHED', specialSessionState: getSpecialSessionState() };
    }

    const startedAt = Date.now();
    if (lastStatusPH === 'IDLE' && idleStartTime) finishIdleSession(startedAt);
    switchTimingState(trackingMode, normalized, startedAt);
    lastStatusPH = normalized;
    idleStartTime = null;
    idleStartDisplay = '';
    specialSessions.active = {
        type: normalized,
        sessionIndex,
        startedAt,
        remainingAtStart,
        mode: Number(trackingMode) === 2 ? 2 : 1
    };
    logWithTimestamp(normalized + ' STARTED | Session ' + (sessionIndex + 1) + '/' + allowance.maxSessions + ' | Remaining: ' + formatDuration(remainingAtStart));
    saveStats();
    broadcastToBrowser('special_session_started');
    scheduleDashboard();

    if (specialSessionTimer !== null) clearTimeout(specialSessionTimer);
    specialSessionTimer = setTimeout(() => {
        endSpecialSession({ expired: true });
    }, remainingAtStart * 1000);

    return {
        success: true,
        status: normalized,
        agentStatus: normalized,
        trackingMode,
        breakState: getBreakState(),
        specialSessionState: getSpecialSessionState(),
        modeTiming: getModeTimingSnapshot(),
        intervalCounters: getIntervalCounters()
    };
}

function endSpecialSession(options = {}) {
    const active = specialSessions.active;
    if (!active) {
        return {
            success: false,
            error: 'NO_SPECIAL_SESSION_ACTIVE',
            status: lastStatusPH,
            specialSessionState: getSpecialSessionState()
        };
    }
    if (specialSessionTimer !== null) clearTimeout(specialSessionTimer);
    specialSessionTimer = null;

    const endedAt = Date.now();
    const allowance = specialSessions[active.type];
    const rawSeconds = Math.max(0, Math.floor((endedAt - active.startedAt) / 1000));
    const duration = options.expired ? active.remainingAtStart : Math.min(active.remainingAtStart, rawSeconds);
    allowance.usedSeconds[active.sessionIndex] = Math.min(
        allowance.totalSeconds,
        allowance.usedSeconds[active.sessionIndex] + duration
    );
    if (jobConfirmed) {
        if (active.type === 'BIO') jobBioSeconds += duration;
        if (active.type === 'HBIO') jobHbioSeconds += duration;
    }
    const remaining = Math.max(0, allowance.totalSeconds - allowance.usedSeconds[active.sessionIndex]);
    allowance.history.push({
        type: active.type,
        session: active.sessionIndex + 1,
        mode: active.mode,
        startedAt: active.startedAt,
        endedAt,
        duration,
        remaining,
        endedBy: options.expired ? 'AUTO' : 'MANUAL'
    });
    specialSessions.active = null;
    switchTimingState(trackingMode, 'ACTIVE', endedAt);
    lastStatusPH = 'ACTIVE';
    idleStartTime = null;
    idleStartDisplay = '';
    idleReason = 'Unknown';
    const fullyConsumed = remaining <= 0;
    logWithTimestamp(active.type + ' ENDED | Session ' + (active.sessionIndex + 1) + '/' + allowance.maxSessions + ' | Used: ' + formatDuration(duration) + ' | Remaining: ' + formatDuration(remaining) + ' | ' + (options.expired ? 'AUTO' : 'MANUAL'));
    saveStats();
    const message = fullyConsumed
        ? active.type + ' session ' + (active.sessionIndex + 1) + ' fully consumed. Next use will move to the next session.'
        : active.type + ' paused with ' + formatDuration(remaining) + ' remaining in session ' + (active.sessionIndex + 1) + '.';
    broadcastToBrowser(options.expired ? 'special_session_expired' : 'special_session_ended', { message });
    scheduleDashboard();
    return {
        success: true,
        status: 'ACTIVE',
        agentStatus: 'ACTIVE',
        message,
        trackingMode,
        breakState: getBreakState(),
        specialSessionState: getSpecialSessionState(),
        modeTiming: getModeTimingSnapshot(),
        intervalCounters: getIntervalCounters()
    };
}

function resumePauseSession() {
    if (specialSessions.active) return endSpecialSession({ expired: false });
    return endBreak({ expired: false });
}

function restoreSpecialSessionAfterLoad() {
    ensureSpecialSessionDate();
    const active = specialSessions.active;
    if (!active) return;
    const allowance = specialSessions[active.type];
    const elapsed = Math.max(0, Math.floor((Date.now() - active.startedAt) / 1000));
    if (elapsed >= active.remainingAtStart) {
        endSpecialSession({ expired: true });
        return;
    }
    const remaining = Math.max(1, active.remainingAtStart - elapsed);
    lastStatusPH = active.type;
    switchTimingState(active.mode, active.type, Date.now());
    if (specialSessionTimer !== null) clearTimeout(specialSessionTimer);
    specialSessionTimer = setTimeout(() => endSpecialSession({ expired: true }), remaining * 1000);
}

let jobTaskCount = 0;
let jobIdleSeconds = 0;
let jobBreakSeconds = 0;
let jobBioSeconds = 0;
let jobHbioSeconds = 0;
let jobTrackingMode = trackingMode;
let jobStartTime = Date.now();
let previousJobId = "None";
let coverageLastPosition = 0;
let coverageTaskCount = 0;
let coverageLastEventKey = "";

// =========================================
// FUNCTION CALCULATE COVERAGE DELTA
// Search: calculateCoverageDelta
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function calculateCoverageDelta(currentPosition, totalTasks) {

    currentPosition = Number(currentPosition) || 0;
    totalTasks = Number(totalTasks) || 0;
    if (currentPosition < 0) {
        currentPosition = 0;
    }
    if (totalTasks > 0 && currentPosition > totalTasks) {
        currentPosition = totalTasks;
    }
    if (coverageLastPosition <= 0) {
        coverageLastPosition = currentPosition;
        debugLog("📌 Coverage baseline established:", currentPosition, "/", totalTasks);
        return 0;
    }
    if (currentPosition <= coverageLastPosition) {
        debugLog("⏸️ No new coverage:", coverageLastPosition, "→", currentPosition);
        return 0;
    }
    const delta = currentPosition - coverageLastPosition;
    coverageLastPosition = currentPosition;
    console.log("📈 Coverage progress:", coverageLastPosition - delta, "→", currentPosition, "| Accepted:", delta);
    return delta;

}
jobTaskCount = 0;
jobIdleSeconds = 0;
jobStartTime = Date.now();
previousJobId = "None";
idleStartTime = null;
idleStartDisplay = "";

// =========================================
// FUNCTION GET INTERVAL KEY
// Search: getIntervalKey
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function getIntervalKey(number) {

    return `interval${number}`;

}

// =========================================
// FUNCTION GET INTERVAL NAME
// Search: getIntervalName
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function getIntervalName(number) {

    if (number === 1) return "1ST";
    if (number === 2) return "2ND";
    if (number === 3) return "3RD";
    return `${number}TH`;

}

// =========================================
// FUNCTION SHIFT SCHEDULE
// Search: getShiftSchedule
// Ver 0.1.18 Alpha || 2026-09-29 || JBallados || Dynamic_Shift
// Ver 0.1.21 Alpha || 2026-10-03 || JBallados || DayShift_Lunch_Policy
// =========================================
function getPhilippineHour(timestamp) {

    const time = Number(timestamp || 0);
    if (!time) return null;
    const parts = new Intl.DateTimeFormat('en-US', {
        timeZone: 'Asia/Manila',
        hour: '2-digit',
        hourCycle: 'h23'
    }).formatToParts(new Date(time));
    const hourPart = parts.find(part => part.type === 'hour');
    const hour = Number(hourPart?.value);
    return Number.isFinite(hour) ? hour : null;

}

function isDayShiftStart(anchor = shiftStartedAt) {

    const hour = getPhilippineHour(anchor);
    return hour !== null && hour >= SHIFT.dayShiftStartHour && hour <= SHIFT.dayShiftEndHour;

}

function getShiftDepartment() {
    const configured = loadReportUploadConfig();
    return normalizeDepartment(shiftDepartment || configured?.department || 'OOS', 'OOS') || 'OOS';
}

function getShiftPolicy(anchor = shiftStartedAt, department = getShiftDepartment()) {
    const normalizedDepartment = normalizeDepartment(department, 'OOS') || 'OOS';
    const dayShift = isDayShiftStart(anchor);
    if (normalizedDepartment === 'ENCORD') {
        return {
            department: 'ENCORD',
            dayShift,
            shiftType: 'ENCORD',
            workMinutes: ENCORD_WORK_MINUTES,
            breakMinutes: ENCORD_BREAK_MINUTES,
            lunchMinutes: ENCORD_LUNCH_MINUTES,
            pauseKinds: ['BREAK', 'LUNCH'],
            breakType: 'BREAK_AND_LUNCH',
            intervalCount: 2,
            regularWindowMinutes: ENCORD_WORK_MINUTES + ENCORD_BREAK_MINUTES + ENCORD_LUNCH_MINUTES
        };
    }
    const breakMinutes = dayShift ? 0 : SHIFT.breakMinutes;
    const lunchMinutes = dayShift ? SHIFT.dayShiftLunchMinutes : 0;
    return {
        department: 'OOS',
        dayShift,
        shiftType: dayShift ? 'DAY' : 'NON_DAY',
        workMinutes: SHIFT.workMinutes,
        breakMinutes,
        lunchMinutes,
        pauseKinds: [dayShift ? 'LUNCH' : 'BREAK'],
        breakType: dayShift ? 'LUNCH' : 'BREAK',
        intervalCount: 3,
        regularWindowMinutes: SHIFT.workMinutes + breakMinutes + lunchMinutes
    };
}

function currentBreakKind(anchor = shiftStartedAt) {
    for (let i = breakSessions.length - 1; i >= 0; i--) {
        const session = breakSessions[i];
        if (session && !session.ended) return pauseSessionKind(session, anchor);
    }
    return null;
}

function getShiftBreakMinutes(anchor = shiftStartedAt, requestedKind = 'AUTO') {
    const policy = getShiftPolicy(anchor);
    let kind = String(requestedKind || 'AUTO').trim().toUpperCase();
    if (kind === 'AUTO') kind = currentBreakKind(anchor) || policy.pauseKinds[0];
    if (kind === 'LUNCH') return Math.max(0, Number(policy.lunchMinutes || 0));
    if (kind === 'BREAK') return Math.max(0, Number(policy.breakMinutes || 0));
    return 0;
}

function getShiftBreakLabel(anchor = shiftStartedAt, requestedKind = 'AUTO') {
    const policy = getShiftPolicy(anchor);
    let kind = String(requestedKind || 'AUTO').trim().toUpperCase();
    if (kind === 'AUTO') kind = currentBreakKind(anchor) || policy.pauseKinds[0];
    return kind === 'LUNCH' ? 'Lunch Break' : 'Break';
}

function getShiftSchedule(anchor = shiftStartedAt, department = getShiftDepartment()) {

    const start = Number(anchor || 0);
    if (!start) return null;
    const minute = 60 * 1000;
    const policy = getShiftPolicy(start, department);
    const regularEnd = start + policy.regularWindowMinutes * minute;
    let interval1End;
    let interval2End;
    let interval3 = null;
    if (policy.intervalCount === 2) {
        interval1End = start + Math.floor(policy.regularWindowMinutes / 2) * minute;
        interval2End = regularEnd;
    } else {
        interval1End = start + SHIFT.interval1.endOffsetMinutes * minute;
        interval2End = start + SHIFT.interval2.endOffsetMinutes * minute;
        interval3 = { startedAt: interval2End, endedAt: regularEnd };
    }
    return {
        shiftStartedAt: start,
        shiftReportDate: shiftReportDate || coverageDate(start),
        department: policy.department,
        workMinutes: policy.workMinutes,
        breakMinutes: policy.breakMinutes,
        lunchMinutes: policy.lunchMinutes,
        breakLabel: policy.breakType === 'BREAK_AND_LUNCH' ? 'Break + Lunch' : getShiftBreakLabel(start, policy.breakType),
        breakType: policy.breakType,
        shiftType: policy.shiftType,
        dayShift: policy.dayShift,
        intervalCount: policy.intervalCount,
        regularWindowMinutes: policy.regularWindowMinutes,
        regularEndAt: regularEnd,
        overtimeStartsAt: regularEnd,
        interval1: { startedAt: start, endedAt: interval1End },
        interval2: { startedAt: interval1End, endedAt: interval2End },
        interval3
    };

}

function splitPauseSeconds(seconds, anchor = shiftStartedAt, department = getShiftDepartment()) {

    const totalSeconds = Math.max(0, Math.floor(Number(seconds || 0)));
    const policy = getShiftPolicy(anchor, department);
    if (policy.breakType === 'BREAK_AND_LUNCH') {
        return { breakSeconds: totalSeconds, lunchSeconds: 0, breakType: 'BREAK_AND_LUNCH', shiftType: policy.shiftType };
    }
    const lunch = policy.breakType === 'LUNCH';
    return {
        breakSeconds: lunch ? 0 : totalSeconds,
        lunchSeconds: lunch ? totalSeconds : 0,
        breakType: lunch ? 'LUNCH' : 'BREAK',
        shiftType: policy.shiftType
    };

}

function pauseSessionKind(session, anchor = shiftStartedAt, department = getShiftDepartment()) {

    const explicit = String(session?.kind || '').trim().toUpperCase();
    if (explicit === 'LUNCH' || explicit === 'BREAK') return explicit;
    const label = String(session?.label || '').trim().toUpperCase();
    if (label.includes('LUNCH')) return 'LUNCH';
    const policy = getShiftPolicy(anchor, department);
    return policy.pauseKinds.length === 1 ? policy.pauseKinds[0] : 'BREAK';

}

function isOvertimeAt(timestamp = Date.now(), anchor = shiftStartedAt) {
    const schedule = getShiftSchedule(anchor);
    return Boolean(schedule && Number(timestamp) >= schedule.overtimeStartsAt);
}

function overtimeTimingSnapshot(now = Date.now()) {
    const copy = { ...overtimeStats };
    if (shiftStarted && shiftStartedAt && isOvertimeAt(now)) {
        const overlapStart = Math.max(Number(timingSegmentStartedAt || now), getShiftSchedule().overtimeStartsAt);
        const elapsed = Math.max(0, now - overlapStart);
        const status = String(timingSegmentStatus || 'ACTIVE').toUpperCase();
        const field = status === 'IDLE' ? 'idleMs'
            : status === 'BREAK' ? 'breakMs'
            : status === 'BIO' ? 'bioMs'
            : status === 'HBIO' ? 'hbioMs'
            : 'activeMs';
        copy[field] = Math.max(0, Number(copy[field] || 0)) + elapsed;
    }
    return {
        tasks: Math.max(0, Number(copy.tasks || 0)),
        jobs: Math.max(0, Number(copy.jobs || 0)),
        activeSeconds: Math.floor(Math.max(0, Number(copy.activeMs || 0)) / 1000),
        idleSeconds: Math.floor(Math.max(0, Number(copy.idleMs || 0)) / 1000),
        breakSeconds: Math.floor(Math.max(0, Number(copy.breakMs || 0)) / 1000),
        bioSeconds: Math.floor(Math.max(0, Number(copy.bioMs || 0)) / 1000),
        hbioSeconds: Math.floor(Math.max(0, Number(copy.hbioMs || 0)) / 1000)
    };
}

function accumulateOvertimeTiming(startedAt, endedAt, status) {
    const schedule = getShiftSchedule();
    if (!schedule) return;
    const from = Math.max(Number(startedAt || 0), schedule.overtimeStartsAt);
    const to = Number(endedAt || 0);
    const elapsed = Math.max(0, to - from);
    if (!elapsed) return;
    const normalized = String(status || 'ACTIVE').toUpperCase();
    const field = normalized === 'IDLE' ? 'idleMs'
        : normalized === 'BREAK' ? 'breakMs'
        : normalized === 'BIO' ? 'bioMs'
        : normalized === 'HBIO' ? 'hbioMs'
        : 'activeMs';
    overtimeStats[field] = Math.max(0, Number(overtimeStats[field] || 0)) + elapsed;
}

// =========================================
// FUNCTION GET INTERVAL FOR TIMESTAMP
// Search: getIntervalForTimestamp
// Ver 0.1.18 Alpha || 2026-09-29 || JBallados || Dynamic_Shift
// =========================================
function getIntervalForTimestamp(timestamp, anchor = shiftStartedAt) {

    const time = Number(timestamp || 0);
    const schedule = getShiftSchedule(anchor);
    if (!time || !schedule) return null;
    if (schedule.interval1 && time >= schedule.interval1.startedAt && time < schedule.interval1.endedAt) return 'interval1';
    if (schedule.interval2 && time >= schedule.interval2.startedAt && time < schedule.interval2.endedAt) return 'interval2';
    if (schedule.interval3 && time >= schedule.interval3.startedAt && time < schedule.interval3.endedAt) return 'interval3';
    if (time >= schedule.overtimeStartsAt) return 'overtime';
    return null;

}
// End Modification Ver 0.1.18 Alpha

// =========================================
// FUNCTION ENSURE CURRENT SHIFT INTERVAL
// Search: ensureCurrentShiftInterval
// Ver 0.1.18 Alpha || 2026-09-29 || JBallados
// =========================================
function scheduledIntervalNumberAt(now = Date.now(), schedule = getShiftSchedule()) {
    if (!schedule) return null;
    let desiredNumber = 1;
    if (schedule.interval2 && Number(now) >= schedule.interval2.startedAt) desiredNumber = 2;
    if (schedule.intervalCount >= 3 && schedule.interval3 && Number(now) >= schedule.interval3.startedAt) desiredNumber = 3;
    return Math.min(desiredNumber, Math.max(1, Number(schedule.intervalCount || 3)));
}

function currentManualIntervalResetState(now = Date.now()) {
    const schedule = getShiftSchedule();
    const scheduledIntervalNumber = scheduledIntervalNumberAt(now, schedule);
    const lock = earlyManualIntervalAdvance ? { ...earlyManualIntervalAdvance } : null;
    return {
        locked: Boolean(lock && Number(now) < Number(lock.scheduledBoundaryAt || 0)),
        scheduledIntervalNumber,
        currentIntervalNumber,
        lock
    };
}

function ensureCurrentShiftInterval(now = Date.now()) {

    if (!shiftStarted || !shiftStartedAt) return false;
    const schedule = getShiftSchedule();
    if (!schedule) return false;

    const desiredNumber = scheduledIntervalNumberAt(now, schedule);
    let legacyPrematureRepair = false;

    // Compatibility repair for v0.1.18 and other legacy builds where one manual
    // Reset click could advance an already auto-advanced interval again.
    // A legitimate v0.1.20+ early reset always has earlyManualIntervalAdvance,
    // so only an ahead-of-schedule legacy state without that lock is repaired.
    if (
        currentInterval
        && Number(currentIntervalNumber || 1) > Number(desiredNumber || 1)
        && !earlyManualIntervalAdvance
    ) {
        const previousNumber = Number(currentIntervalNumber || currentInterval.number || 1);
        currentIntervalNumber = desiredNumber;
        currentInterval.number = desiredNumber;
        legacyPrematureRepair = true;
        logWithTimestamp(
            'LEGACY PREMATURE INTERVAL REPAIRED: '
            + getIntervalName(previousNumber) + ' was ahead of the scheduled '
            + getIntervalName(desiredNumber) + '; current interval was reassigned without clearing counters.',
            'WARN',
            'INTERVAL',
            {
                eventCode: 'EVT-INTERVAL-LEGACY-PREMATURE-REPAIR',
                previousIntervalNumber: previousNumber,
                scheduledIntervalNumber: desiredNumber
            }
        );
    }

    let lockReleased = false;
    if (earlyManualIntervalAdvance && Number(now) >= Number(earlyManualIntervalAdvance.scheduledBoundaryAt || 0)) {
        const releasedLock = earlyManualIntervalAdvance;
        earlyManualIntervalAdvance = null;
        lockReleased = true;
        logWithTimestamp(
            'EARLY MANUAL INTERVAL LOCK RELEASED: scheduled boundary reached for '
            + getIntervalName(releasedLock.fromInterval) + ' -> ' + getIntervalName(releasedLock.toInterval)
            + '; no extra interval reset performed.',
            'INFO',
            'INTERVAL',
            { eventCode: 'EVT-INTERVAL-MANUAL-LOCK-RELEASED' }
        );
    }

    if (!currentInterval) {
        const desiredInterval = schedule['interval' + desiredNumber];
        const startedAt = Number(desiredInterval?.startedAt || schedule.interval1.startedAt);
        startNewInterval(desiredNumber, startedAt);
        saveStats();
        broadcastToBrowser('interval_auto_changed', {
            automatic: true,
            currentIntervalNumber: desiredNumber
        });
        return true;
    }

    let changed = false;
    const maxRegularIntervals = Math.max(1, Number(schedule.intervalCount || 3));
    while (currentIntervalNumber < desiredNumber && currentIntervalNumber < maxRegularIntervals) {
        const currentKey = 'interval' + currentIntervalNumber;
        const boundary = Number(schedule[currentKey]?.endedAt || now);
        const previousName = getIntervalName(currentIntervalNumber);
        closeCurrentInterval(boundary);
        startNewInterval(currentIntervalNumber + 1, boundary);
        logWithTimestamp(
            'INTERVAL AUTO CHANGE: ' + previousName + ' closed at ' + getPHTime(boundary)
            + '; ' + getIntervalName(currentIntervalNumber) + ' started.',
            'INFO',
            'INTERVAL'
        );
        changed = true;
    }

    if (changed || lockReleased || legacyPrematureRepair) {
        saveStats();
        broadcastToBrowser(
            legacyPrematureRepair
                ? 'interval_legacy_repaired'
                : (changed ? 'interval_auto_changed' : 'interval_manual_lock_released'),
            {
                automatic: changed,
                lockReleased,
                legacyPrematureRepair,
                currentIntervalNumber,
                currentInterval,
                manualIntervalReset: currentManualIntervalResetState(now)
            }
        );
        scheduleDashboard();
    }
    return changed || lockReleased || legacyPrematureRepair;

}
// End Modification Ver 0.1.18 Alpha

// =========================================
// FUNCTION GET PHTIME
// Search: getPHTime
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function getPHTime(timestamp = Date.now()) {

    return new Date(timestamp).toLocaleTimeString("en-US", {
        timeZone: "Asia/Manila",
        hour12: true
    });

}

// =========================================
// FUNCTION START NEW INTERVAL
// Search: startNewInterval
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function startNewInterval(number = 1, startTime = Date.now()) {

    currentIntervalNumber = number;
    currentInterval = {
        number: number,
        started: startTime,
        ended: null,
        tasks: 0,
        jobs: 0,
        confirmation: {
            taskCompleted: 0,
            jobsCompleted: 0
        },
        jobRecords: []
    };
    allTimeTasks = 0;
    totalTaskCompleted = intervalHistory.reduce((sum, interval) => sum + confirmationTotalsFor(interval).taskCompleted, 0);

}

// =========================================
// FUNCTION CURRENT COVERAGE TOTALS
// Search: currentCoverageTotals
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function currentCoverageTotals() {

    const totals = {
        taskCompleted: mode2TaskCompleted,
        jobsCompleted: mode2JobsCompleted,
        emptyAreaConfirmation: mode2EmptyAreaConfirmation,
        emptyAreaNoMatchFound: mode2EmptyAreaNoMatchFound,
        unblurredPerson: mode2UnblurredPerson,
        deletedBoxes: mode2DeletedBoxes,
        skippedTask: mode2SkippedTask
    };
    for (const interval of intervalHistory) {
        for (const key of Object.keys(totals)) {
            totals[key] = Math.max(0, totals[key] - (interval.coverage?.[key] || 0));
        }
    }
    return totals;

}

// =========================================
// FUNCTION CONFIRMATION TOTALS FOR
// Search: confirmationTotalsFor
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function confirmationTotalsFor(interval) {

    if (!interval) return {
        taskCompleted: 0,
        jobsCompleted: 0
    };
    if (interval.confirmation) return interval.confirmation;
    const coverage = interval.coverage || {};
    return {
        taskCompleted: Math.max(0, (interval.tasks || 0) - (coverage.taskCompleted || 0)),
        jobsCompleted: Math.max(0, (interval.jobs || 0) - (coverage.jobsCompleted || 0))
    };

}

// =========================================
// FUNCTION CURRENT CONFIRMATION TOTALS
// Search: currentConfirmationTotals
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function currentConfirmationTotals() {

    if (!currentInterval) return confirmationTotalsFor(null);
    if (!currentInterval.confirmation) {
        currentInterval.confirmation = confirmationTotalsFor(currentInterval);
    }
    return currentInterval.confirmation;

}

// =========================================
// FUNCTION GET INTERVAL COUNTERS
// Search: getIntervalCounters
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function getIntervalCounters() {

    return {
        mode1: currentConfirmationTotals(),
        mode2: currentCoverageTotals()
    };

}

// =========================================
// FUNCTION RESET INTERVAL
// Search: resetInterval
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function resetInterval(options = {}) {

    const resetTime = Date.now();
    if (!shiftStarted || !shiftStartedAt) {
        return {
            success: false,
            error: 'SHIFT_NOT_STARTED',
            message: 'Start the shift before resetting an interval.'
        };
    }

    // First catch up any boundary that has already passed.
    ensureCurrentShiftInterval(resetTime);

    const schedule = getShiftSchedule();
    const scheduledIntervalNumber = scheduledIntervalNumberAt(resetTime, schedule);
    const currentNumber = Number(currentIntervalNumber || 1);

    if (currentNumber > scheduledIntervalNumber) {
        const boundaryAt = Number(
            earlyManualIntervalAdvance?.scheduledBoundaryAt
            || schedule?.['interval' + scheduledIntervalNumber]?.endedAt
            || 0
        );
        const message = 'Manual interval reset is locked because this interval was already started early. '
            + 'Wait for the scheduled boundary at ' + getPHTime(boundaryAt) + '.';
        logWithTimestamp(
            'EARLY MANUAL INTERVAL RESET BLOCKED: ' + message,
            'WARN',
            'INTERVAL',
            { eventCode: 'EVT-INTERVAL-MANUAL-RESET-BLOCKED', currentIntervalNumber: currentNumber, scheduledIntervalNumber, boundaryAt }
        );
        return {
            success: false,
            error: 'EARLY_INTERVAL_RESET_LOCKED',
            message,
            warning: true,
            currentIntervalNumber: currentNumber,
            scheduledIntervalNumber,
            unlockAt: boundaryAt,
            manualIntervalReset: currentManualIntervalResetState(resetTime)
        };
    }

    const maxRegularIntervals = Math.max(1, Number(schedule?.intervalCount || 3));
    if (currentNumber >= maxRegularIntervals) {
        return {
            success: false,
            error: 'FINAL_INTERVAL_ACTIVE',
            message: 'The final regular interval (' + getIntervalName(maxRegularIntervals) + ') is already active. There is no next regular interval to start.',
            currentIntervalNumber: currentNumber,
            maxRegularIntervals,
            manualIntervalReset: currentManualIntervalResetState(resetTime)
        };
    }

    const currentKey = 'interval' + currentNumber;
    const scheduledBoundaryAt = Number(schedule?.[currentKey]?.endedAt || 0);
    const early = Boolean(scheduledBoundaryAt && resetTime < scheduledBoundaryAt);

    if (early && options.confirmEarly !== true) {
        const warningMessage = 'This reset is before the scheduled ' + getIntervalName(currentNumber)
            + ' interval boundary at ' + getPHTime(scheduledBoundaryAt)
            + '. If you continue, ' + getIntervalName(currentNumber + 1)
            + ' starts early and another manual reset will be blocked until that boundary.';
        logWithTimestamp(
            'EARLY MANUAL INTERVAL RESET WARNING ISSUED: ' + warningMessage,
            'WARN',
            'INTERVAL',
            { eventCode: 'EVT-INTERVAL-EARLY-RESET-WARNING', currentIntervalNumber: currentNumber, nextIntervalNumber: currentNumber + 1, scheduledBoundaryAt }
        );
        return {
            success: false,
            error: 'EARLY_INTERVAL_RESET_CONFIRMATION_REQUIRED',
            requiresConfirmation: true,
            warning: true,
            message: warningMessage,
            currentIntervalNumber: currentNumber,
            nextIntervalNumber: currentNumber + 1,
            scheduledBoundaryAt,
            manualIntervalReset: currentManualIntervalResetState(resetTime)
        };
    }

    const oldIntervalName = getIntervalName(currentNumber);
    closeCurrentInterval(resetTime);
    startNewInterval(currentNumber + 1, resetTime);

    if (early) {
        earlyManualIntervalAdvance = {
            fromInterval: currentNumber,
            toInterval: currentNumber + 1,
            resetAt: resetTime,
            scheduledBoundaryAt
        };
    } else {
        earlyManualIntervalAdvance = null;
    }

    lastLogTimePH = getPHTime(resetTime);
    saveStats();
    const message = early
        ? `EARLY INTERVAL RESET CONFIRMED: ${oldIntervalName} saved; ${getIntervalName(currentIntervalNumber)} started early. Manual reset locked until ${getPHTime(scheduledBoundaryAt)}.`
        : `INTERVAL RESET: ${oldIntervalName} saved; ${getIntervalName(currentIntervalNumber)} started.`;
    logWithTimestamp(
        message,
        early ? 'WARN' : 'INFO',
        'INTERVAL',
        {
            eventCode: early ? 'EVT-INTERVAL-EARLY-RESET-CONFIRMED' : 'EVT-INTERVAL-MANUAL-RESET',
            scheduledBoundaryAt: scheduledBoundaryAt || null
        }
    );
    broadcastToBrowser('interval_reset', {
        manual: true,
        early,
        currentIntervalNumber,
        scheduledBoundaryAt: early ? scheduledBoundaryAt : null,
        manualIntervalReset: currentManualIntervalResetState(resetTime)
    });
    scheduleDashboard();
    return {
        success: true,
        status: early ? 'EARLY_RESET_CONFIRMED' : 'RESET',
        early,
        warning: early,
        message,
        currentIntervalNumber,
        scheduledBoundaryAt: early ? scheduledBoundaryAt : null,
        manualIntervalReset: currentManualIntervalResetState(resetTime)
    };

}

// =========================================
// FUNCTION CLOSE CURRENT INTERVAL
// Search: closeCurrentInterval
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function closeCurrentInterval(endTime = Date.now()) {

    if (!currentInterval) return;
    const coverage = currentCoverageTotals();
    if (trackingMode === 2) {
        currentInterval.tasks = coverage.taskCompleted;
        currentInterval.jobs = coverage.jobsCompleted;
    }
    currentInterval.coverage = coverage;
    currentInterval.ended = endTime;
    if (currentInterval.tasks > 0 || currentInterval.jobs > 0 || Object.values(coverage).some(value => value > 0)) {
        intervalHistory.push({
            confirmation: {
                ...currentConfirmationTotals()
            },
            coverage: {
                ...coverage
            },
            number: currentInterval.number,
            started: currentInterval.started,
            ended: currentInterval.ended,
            tasks: currentInterval.tasks,
            jobs: currentInterval.jobs,
            jobRecords: currentInterval.jobRecords || []
        });
    }
    totalTaskCompleted = intervalHistory.reduce((sum, interval) => sum + confirmationTotalsFor(interval).taskCompleted, 0);

}

// =========================================
// FUNCTION BEGIN NEXT INTERVAL
// Search: beginNextInterval
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function beginNextInterval() {

    let nextNumber = currentIntervalNumber + 1;
    if (nextNumber > 3) {
        nextNumber = 3;
    }
    startNewInterval(nextNumber, Date.now());

}

// =========================================
// FUNCTION ADD JOB TO CURRENT INTERVAL
// Search: addJobToCurrentInterval
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// =========================================
function addJobToCurrentInterval(job) {

    if (!currentInterval) {
        startNewInterval(currentIntervalNumber || 1);
    }
    const recordMode = Number(job.mode) === 2 ? 2 : Number(job.mode) === 1 ? 1 : trackingMode;
    if (recordMode === 1) {
        currentConfirmationTotals().jobsCompleted += 1;
        currentInterval.jobs += 1;
    }
    currentInterval.jobRecords.push({
        jobId: job.jobId,
        mode: recordMode,
        tasks: job.tasks || 0,
        idle: job.idle || 0,
        break: job.break || 0,
        bio: job.bio || 0,
        hbio: job.hbio || 0,
        active: job.active || 0,
        duration: job.duration || 0,
        started: job.started || Date.now(),
        finished: job.finished || Date.now()
    });
    saveStats();

}

// =========================================
// FUNCTION LOAD STATS
// Search: loadStats
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function loadStats() {

    if (!fs.existsSync(statsFile)) {
        resetModeTiming();
        return;
    }
    if (!verifyFileIntegrity(statsFile, 'stats', true)) {
        console.error('Refusing to load modified stats.json. A copy was saved to Integrity_Quarantine.');
        resetModeTiming();
        return;
    }
    const stats = JSON.parse(fs.readFileSync(statsFile, 'utf8'));
    let statsMtimeMs = 0;
    try { statsMtimeMs = Number(fs.statSync(statsFile).mtimeMs || 0); } catch {}
    statsCoverageRecoverySnapshot = stats?.mode2 && typeof stats.mode2 === 'object'
        ? {
            date: String(stats.date || stats.shiftReportDate || ''),
            mtimeMs: statsMtimeMs,
            taskCompleted: Math.max(0, Number(stats.mode2.taskCompleted || 0)),
            jobsCompleted: Math.max(0, Number(stats.mode2.jobsCompleted || 0)),
            deletedBoxes: Math.max(0, Number(stats.mode2.deletedBoxes || 0)),
            emptyAreaConfirmation: Math.max(0, Number(stats.mode2.emptyAreaConfirmation || 0)),
            emptyAreaNoMatchFound: Math.max(0, Number(stats.mode2.emptyAreaNoMatchFound || 0)),
            unblurredPerson: Math.max(0, Number(stats.mode2.unblurredPerson || 0)),
            skippedTask: Math.max(0, Number(stats.mode2.skippedTask || 0))
        }
        : null;
    const today = coverageDate();
    const statsDate = stats.date || null;
    const savedShiftIsActive = Boolean(stats.shiftStarted && Number(stats.shiftStartedAt || 0));
    if (statsDate !== null && statsDate !== today && !savedShiftIsActive) {
        generateReport(stats).then(success => {
            logWithTimestamp(success ? 'DAILY REPORT GENERATED FOR PREVIOUS DATE: ' + statsDate : 'NO DATA TO GENERATE DAILY REPORT FOR PREVIOUS DATE: ' + statsDate);
        }).catch(err => {
            console.error('Error generating previous day report:', err);
        });
        allTimeTasks = 0;
        totalTaskCompleted = 0;
        totalJobsCompleted = 0;
        lastJobFinished = null;
        completedJobs = [];
        intervalStats = {
            interval1: { jobs: [], tasks: 0, idle: 0, active: 0 },
            interval2: { jobs: [], tasks: 0, idle: 0, active: 0 },
            interval3: { jobs: [], tasks: 0, idle: 0, active: 0 }
        };
        intervalHistory = [];
        startNewInterval(1);
        breakSessions = [];
        shiftStarted = false;
        shiftStartedAt = null;
        shiftEndedAt = null;
        shiftReportDate = null;
        overtimeStats = { tasks: 0, jobs: 0, activeMs: 0, idleMs: 0, breakMs: 0, bioMs: 0, hbioMs: 0 };
        earlyManualIntervalAdvance = null;
        lastStatusPH = 'WAITING';
        resetModeTiming();
        resetSpecialSessions(today);
    } else {
        allTimeTasks = stats.allTimeTasks || 0;
        totalTaskCompleted = stats.totalTaskCompleted || 0;
        totalJobsCompleted = stats.totalJobsCompleted || 0;
        lastJobFinished = stats.lastJobFinished || null;
        completedJobs = stats.completedJobs || [];
        intervalHistory = stats.intervalHistory || [];
        breakSessions = stats.breakSessions || [];
        specialSessions = normalizeSpecialSessions(stats.specialSessions);
        const legacyTimingTotal = Math.max(0, Number(stats.totalActiveSeconds || 0)) + Math.max(0, Number(stats.totalIdleSeconds || 0));
        const legacyActivity = legacyTimingTotal > 0 || Number(stats.totalTaskCompleted || 0) > 0 || Number(stats.mode2?.taskCompleted || 0) > 0;
        shiftStarted = typeof stats.shiftStarted === 'boolean' ? stats.shiftStarted : legacyActivity;
        shiftStartedAt = Number(stats.shiftStartedAt || 0) || null;
        shiftEndedAt = Number(stats.shiftEndedAt || 0) || null;
        shiftReportDate = stats.shiftReportDate || (shiftStartedAt ? coverageDate(shiftStartedAt) : null);
        shiftDepartment = normalizeDepartment(stats.shiftDepartment || loadReportUploadConfig()?.department || 'OOS', 'OOS') || 'OOS';
        earlyManualIntervalAdvance = stats.earlyManualIntervalAdvance && typeof stats.earlyManualIntervalAdvance === 'object'
            ? {
                fromInterval: Number(stats.earlyManualIntervalAdvance.fromInterval || 0),
                toInterval: Number(stats.earlyManualIntervalAdvance.toInterval || 0),
                resetAt: Number(stats.earlyManualIntervalAdvance.resetAt || 0),
                scheduledBoundaryAt: Number(stats.earlyManualIntervalAdvance.scheduledBoundaryAt || 0)
            }
            : null;
        overtimeStats = {
            tasks: Math.max(0, Number(stats.overtimeStats?.tasks || 0)),
            jobs: Math.max(0, Number(stats.overtimeStats?.jobs || 0)),
            activeMs: Math.max(0, Number(stats.overtimeStats?.activeMs || 0)),
            idleMs: Math.max(0, Number(stats.overtimeStats?.idleMs || 0)),
            breakMs: Math.max(0, Number(stats.overtimeStats?.breakMs || 0)),
            bioMs: Math.max(0, Number(stats.overtimeStats?.bioMs || 0)),
            hbioMs: Math.max(0, Number(stats.overtimeStats?.hbioMs || 0))
        };
        lastStatusPH = shiftStarted ? String(stats.agentStatus || 'ACTIVE').toUpperCase() : 'WAITING';
        currentIntervalNumber = stats.currentIntervalNumber || 1;
        if (stats.currentInterval) {
            currentInterval = stats.currentInterval;
            totalTaskCompleted = intervalHistory.reduce((sum, interval) => sum + confirmationTotalsFor(interval).taskCompleted, 0) + currentConfirmationTotals().taskCompleted;
        } else {
            startNewInterval(1);
        }
        restoreProcessedSubmitRequests(stats.processedSubmitRequests);
        loadModeTiming(stats);
    }

}

// =========================================
// FUNCTION COVERAGE DATE
// Search: coverageDate
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function coverageDate(timestamp = Date.now()) {

    return new Intl.DateTimeFormat('en-CA', {
        timeZone: 'Asia/Manila',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
    }).format(new Date(timestamp));

}

function trackingDate(timestamp = Date.now()) {
    if (shiftReportDate) return String(shiftReportDate);
    if (shiftStartedAt) return coverageDate(shiftStartedAt);
    return coverageDate(timestamp);
}
let mode2Date = coverageDate();
let coverageSubmittedTasks = {};

// =========================================
// FUNCTION ENSURE COVERAGE DATE
// Search: ensureCoverageDate
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function ensureCoverageDate() {

    ensureSpecialSessionDate();
    const expectedDate = trackingDate();
    if (mode2Date === expectedDate) return;
    mode2Date = expectedDate;
    resetCoverageCounters(true);
    saveStats();
    broadcastToBrowser('coverage_daily_reset');

}

// =========================================
// FUNCTION LOAD MODE2 STATS
// Search: loadMode2Stats
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function loadMode2Stats() {

    const expectedDate = trackingDate();
    const statsCandidate = statsCoverageRecoverySnapshot
        && String(statsCoverageRecoverySnapshot.date || '') === String(expectedDate)
        ? statsCoverageRecoverySnapshot
        : null;
    let mode2Candidate = null;
    let mode2IntegrityFailed = false;

    try {
        if (fs.existsSync(mode2StatsFile)) {
            if (!verifyFileIntegrity(mode2StatsFile, 'mode2_stats', true)) {
                mode2IntegrityFailed = true;
                throw new Error('INTEGRITY_CHECK_FAILED_MODE2');
            }
            const raw = fs.readFileSync(mode2StatsFile, 'utf8');
            const saved = JSON.parse(raw);
            const fileMtimeMs = Number(fs.statSync(mode2StatsFile).mtimeMs || 0);
            const savedDate = String(saved.date || coverageDate(fileMtimeMs));
            if (savedDate === String(expectedDate)) {
                mode2Candidate = {
                    date: savedDate,
                    mtimeMs: fileMtimeMs,
                    taskCompleted: Math.max(0, Number(saved.mode2TaskCompleted ?? saved.totalTaskCompleted) || 0),
                    jobsCompleted: Math.max(0, Number(saved.mode2JobsCompleted ?? saved.totalJobsCompleted) || 0),
                    deletedBoxes: Math.max(0, Number(saved.mode2DeletedBoxes) || 0),
                    emptyAreaConfirmation: Math.max(0, Number(saved.mode2EmptyAreaConfirmation ?? saved.emptyAreaConfirmation) || 0),
                    emptyAreaNoMatchFound: Math.max(0, Number(saved.mode2EmptyAreaNoMatchFound ?? saved.emptyAreaNoMatchFound) || 0),
                    unblurredPerson: Math.max(0, Number(saved.mode2UnblurredPerson ?? saved.unblurredPerson) || 0),
                    skippedTask: Math.max(0, Number(saved.mode2SkippedTask ?? saved.skippedTask) || 0),
                    submittedTasks: saved.submittedTasks && typeof saved.submittedTasks === 'object' ? saved.submittedTasks : {}
                };
            }
        }
    } catch (error) {
        console.error('❌ Failed to load Mode 2 statistics:', error);
    }

    const selected = statsCandidate && (!mode2Candidate || Number(statsCandidate.mtimeMs || 0) >= Number(mode2Candidate.mtimeMs || 0))
        ? { ...statsCandidate, source: 'stats.json' }
        : mode2Candidate
            ? { ...mode2Candidate, source: 'mode2_stats.json' }
            : null;

    if (!selected) {
        mode2Date = expectedDate;
        mode2TaskCompleted = 0;
        mode2JobsCompleted = 0;
        mode2DeletedBoxes = 0;
        mode2EmptyAreaConfirmation = 0;
        mode2EmptyAreaNoMatchFound = 0;
        mode2UnblurredPerson = 0;
        mode2SkippedTask = 0;
        coverageSubmittedTasks = {};
        syncMode2Stats();
        saveMode2Stats();
        if (mode2IntegrityFailed) {
            logWithTimestamp(
                'COVERAGE RECOVERY WARNING: mode2_stats.json failed integrity and no valid stats.json Coverage snapshot was available; Coverage counters were initialized to zero.',
                'WARN',
                'TRACKER',
                { eventCode:'EVT-COVERAGE-RECOVERY-NO-SNAPSHOT' }
            );
        }
        return;
    }

    mode2Date = expectedDate;
    mode2TaskCompleted = selected.taskCompleted;
    mode2JobsCompleted = selected.jobsCompleted;
    mode2DeletedBoxes = selected.deletedBoxes;
    mode2EmptyAreaConfirmation = selected.emptyAreaConfirmation;
    mode2EmptyAreaNoMatchFound = selected.emptyAreaNoMatchFound;
    mode2UnblurredPerson = selected.unblurredPerson;
    mode2SkippedTask = selected.skippedTask;

    // submittedTasks only exists in mode2_stats.json. Preserve it when that file
    // is valid for the same shift even if stats.json has the slightly newer totals.
    coverageSubmittedTasks = mode2Candidate?.submittedTasks || {};
    syncMode2Stats();

    const shouldRepairMode2File = selected.source === 'stats.json'
        || !mode2Candidate
        || mode2IntegrityFailed;
    if (shouldRepairMode2File) {
        saveMode2Stats();

        // A repaired mode2_stats.json should not leave the controller permanently
        // blocked from report generation. Clear the global alarm only after both
        // protected state files verify successfully with the current integrity key.
        if (mode2IntegrityFailed && selected.source === 'stats.json') {
            const statsVerified = verifyFileIntegrity(statsFile, 'stats', true);
            const mode2Verified = verifyFileIntegrity(mode2StatsFile, 'mode2_stats', true);
            if (statsVerified && mode2Verified) integrityCompromised = false;
        }

        logWithTimestamp(
            'COVERAGE STATE RECOVERED FROM ' + selected.source.toUpperCase()
            + ' | Tasks: ' + mode2TaskCompleted + ' | Jobs: ' + mode2JobsCompleted,
            mode2IntegrityFailed ? 'WARN' : 'INFO',
            'TRACKER',
            { eventCode:'EVT-COVERAGE-STATE-RECOVERED', source:selected.source }
        );
    } else {
        debugLog('✅ Mode 2 statistics loaded:', mode2Stats);
    }

}

// =========================================
// FUNCTION SAVE MODE2 STATS
// Search: saveMode2Stats
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function saveMode2Stats() {

    try {
        syncMode2Stats();
        writeProtectedJson(mode2StatsFile, {
            ...mode2Stats,
            date: mode2Date,
            submittedTasks: coverageSubmittedTasks
        }, 'mode2_stats');
        debugLog("💾 Mode 2 statistics saved.");
    } catch (error) {
        console.error("❌ Failed to save Mode 2 statistics:", error);
    }

}

// =========================================
// FUNCTION RESET COVERAGE COUNTERS
// Search: resetCoverageCounters
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function resetCoverageCounters(fullReset = false) {

    mode2Date = trackingDate();
    mode2TaskCompleted = 0;
    if (fullReset) {
        coverageSubmittedTasks = {};
        mode2JobsCompleted = 0;
        mode2DeletedBoxes = 0;
        mode2EmptyAreaConfirmation = 0;
        mode2EmptyAreaNoMatchFound = 0;
        mode2UnblurredPerson = 0;
        mode2SkippedTask = 0;
    }
    saveMode2Stats();

}

// =========================================
// FUNCTION VALIDATE COVERAGE SUBMISSION
// Search: validateCoverageSubmission
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function validateCoverageSubmission(payload) {

    const values = payload.coverageMetrics;
    return /^JOB_[a-z0-9_]+$/i.test(payload.jobId || '') && Number.isInteger(payload.submittedTaskPosition) && payload.submittedTaskPosition >= 1 && Number.isInteger(payload.totalTasks) && payload.totalTasks >= payload.submittedTaskPosition && values && ['emptyAreaConfirmation', 'emptyAreaNoMatchFound', 'unblurredPerson', 'deletedBoxes'].every(key => Number.isSafeInteger(values[key]) && values[key] >= 0);

}

// =========================================
// FUNCTION APPLY COVERAGE SUBMISSION
// Search: applyCoverageSubmission
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function applyCoverageSubmission(payload) {

    const values = payload.coverageMetrics;
    mode2EmptyAreaConfirmation += values.emptyAreaConfirmation;
    mode2EmptyAreaNoMatchFound += values.emptyAreaNoMatchFound;
    mode2UnblurredPerson += values.unblurredPerson;
    mode2DeletedBoxes += values.deletedBoxes;
    coverageSubmittedTasks[JSON.stringify([payload.jobId, payload.submittedTaskPosition])] = true;

}

// =========================================
// FUNCTION RESET ALL COUNTERS
// Search: resetAllCounters
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function resetAllCounters() {

    allTimeTasks = 0;
    totalTaskCompleted = 0;
    totalJobsCompleted = 0;
    completedJobs = [];
    intervalHistory = [];
    intervalStats = Object.fromEntries([1, 2, 3].map(number => ['interval' + number, {
        jobs: [],
        tasks: 0,
        idle: 0,
        active: 0
    }]));
    startNewInterval(1);
    if (breakTimer !== null) clearTimeout(breakTimer);
    breakTimer = null;
    onBreak = false;
    breakStart = null;
    breakSessions = [];
    resetSpecialSessions(coverageDate());
    idleStartTime = null;
    idleStartDisplay = '';
    idleReason = 'Unknown';
    shiftStarted = false;
        shiftStartedAt = null;
        shiftEndedAt = null;
        shiftReportDate = null;
        overtimeStats = { tasks: 0, jobs: 0, activeMs: 0, idleMs: 0, breakMs: 0, bioMs: 0, hbioMs: 0 };
        earlyManualIntervalAdvance = null;
        lastStatusPH = 'WAITING';
    currentJobId = 'No Active Job Detected';
    currentJobUrl = '';
    currentJobDescription = '';
    pendingJobId = '';
    pendingJobUrl = '';
    pendingJobDescription = '';
    previousJobId = 'None';
    lastJobFinished = null;
    jobConfirmed = false;
    lastTotalTasksDone = 0;
    jobTaskCount = 0;
    jobIdleSeconds = 0;
    jobBreakSeconds = 0;
    jobBioSeconds = 0;
    jobHbioSeconds = 0;
    jobTrackingMode = trackingMode;
    jobStartedAt = Date.now();
    jobStartTime = jobStartedAt;
    coverageLastPosition = 0;
    coverageTaskCount = 0;
    coverageLastEventKey = '';
    for (const jobId of Object.keys(jobTasks)) delete jobTasks[jobId];
    processedSubmitRequests.clear();
    resetModeTiming();
    resetCoverageCounters(true);
    saveStats();
    lastLogTimePH = 'ALL WIPED CLEAN';
    logWithTimestamp('RESET ALL: Counters and interval history cleared; tracking mode preserved.');
    broadcastToBrowser('reset_all_counters');
    scheduleDashboard();

}

// =========================================
// FUNCTION SAVE STATS
// Search: saveStats
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function saveStats() {

    settleModeTiming();
    const today = coverageDate();
    const persistedDate = shiftReportDate || (shiftStartedAt ? coverageDate(shiftStartedAt) : today);
    writeProtectedJson(statsFile, {
        date: persistedDate,
        allTimeTasks,
        totalTaskCompleted,
        totalJobsCompleted,
        trackingMode,
        shiftStarted,
        shiftStartedAt,
        shiftEndedAt,
        shiftReportDate,
        shiftDepartment,
        shiftSchedule: getShiftSchedule(),
        earlyManualIntervalAdvance,
        overtimeStats,
        agentStatus: lastStatusPH,
        reportSettings: getPublicReportSettings(),
        mode2: {
            taskCompleted: mode2TaskCompleted,
            jobsCompleted: mode2JobsCompleted,
            deletedBoxes: mode2DeletedBoxes,
            emptyAreaConfirmation: mode2EmptyAreaConfirmation,
            emptyAreaNoMatchFound: mode2EmptyAreaNoMatchFound,
            unblurredPerson: mode2UnblurredPerson,
            skippedTask: mode2SkippedTask
        },
        modeTiming,
        modeTimingSeconds: getModeTimingSnapshot(),
        legacyUnassignedTiming,
        totalIdleSeconds,
        totalActiveSeconds,
        lastJobFinished,
        completedJobs,
        breakSessions,
        intervalHistory,
        currentIntervalNumber,
        currentInterval,
        specialSessions,
        processedSubmitRequests: (() => {
            cleanupProcessedSubmitRequests();
            return Array.from(processedSubmitRequests.entries());
        })()
    }, 'stats');

}

// =========================================
// FUNCTION GET TODAY LOG FILE
// Search: getTodayLogFile
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function getTodayLogFile() {

    return path.join(logsFolder, trackingDate() + '.txt');

}

// =========================================
// FUNCTION LOG WITH TIMESTAMP
// Search: logWithTimestamp
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function logWithTimestamp(message, severity = null, component = null, context = {}) {

    const optionsPH = {
        timeZone: 'Asia/Manila',
        hour12: true,
        year: 'numeric',
        month: 'numeric',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    };
    const text = redactSensitiveLogText(message, 4000);
    const upper = text.toUpperCase();
    const resolvedSeverity = String(severity || (
        /FAILED|FAILURE|ERROR|REFUSING|INVALID/.test(upper) ? 'ERROR'
            : /WARNING|WARN|RETRY|RECONNECT/.test(upper) ? 'WARN'
                : 'INFO'
    )).toUpperCase();
    const resolvedComponent = String(component || (
        /SHIFT|OVERTIME/.test(upper) ? 'SHIFT'
            : /BREAK|BIO|HBIO/.test(upper) ? 'PAUSE'
                : /UPLOAD|DRIVE|APPS SCRIPT/.test(upper) ? 'UPLOAD'
                    : /REPORT/.test(upper) ? 'REPORT'
                        : /INTERVAL|RESET/.test(upper) ? 'INTERVAL'
                            : /JOB/.test(upper) ? 'JOB'
                                : /IDLE|ACTIVE/.test(upper) ? 'ACTIVITY'
                                    : 'TRACKER'
    )).toUpperCase().replace(/[^A-Z0-9_-]/g, '').slice(0, 24);
    const safeContext = sanitizeStructuredLogValue(context || {}, 2000);
    const eventCode = String(safeContext.eventCode || ('EVT-' + resolvedComponent + '-ACTIVITY'))
        .toUpperCase().replace(/[^A-Z0-9_-]/g, '').slice(0, 96);
    const traceId = redactSensitiveLogText(safeContext.traceId || '', 120);
    const pht = new Date().toLocaleString('en-US', optionsPH);
    const job = currentJobId && currentJobId !== 'No Active Job Detected' ? ' [Job:' + currentJobId + ']' : '';
    const trace = traceId ? ' [Trace:' + traceId + ']' : '';
    fs.appendFileSync(
        getTodayLogFile(),
        '[' + pht + '] [' + resolvedSeverity + '] [' + resolvedComponent + '] [' + eventCode + ']' + trace + job + ' ' + text + '\n'
    );
    writeStructuredActivityLog('tracker.activity', {
        message: text,
        currentJobId: currentJobId && currentJobId !== 'No Active Job Detected' ? currentJobId : null,
        trackingMode,
        shiftStarted,
        shiftReportDate,
        context: safeContext
    }, {
        severity: resolvedSeverity,
        component: resolvedComponent,
        eventCode,
        traceId
    });
    return pht;

}

// =========================================
// FUNCTION APPEND END SHIFT LOG SUMMARY
// Search: appendEndShiftLogSummary
// Ver 0.1.18 Alpha || 2026-09-29 || JBallados
// =========================================
function appendEndShiftLogSummary(report, overtime) {

    const timing = getModeTimingSnapshot();
    const combinedTasks = Math.max(0, Number(totalTaskCompleted || 0)) + Math.max(0, Number(mode2TaskCompleted || 0));
    const combinedJobs = Math.max(0, Number(totalJobsCompleted || 0)) + Math.max(0, Number(mode2JobsCompleted || 0));
    const efficiency = calculateEfficiency(timing.combined.activeSeconds, timing.combined.idleSeconds);
    const schedule = getShiftSchedule(shiftStartedAt, shiftDepartment);
    const pauseSummary = summarizePauseSessions(breakSessions, shiftStartedAt, shiftDepartment);
    const overtimePauseSummary = summarizePauseSessions(
        breakSessions,
        shiftStartedAt,
        shiftDepartment,
        null,
        schedule?.overtimeStartsAt || null,
        shiftEndedAt || Date.now()
    );
    const driveStatus = report?.drive?.ok === true ? 'VERIFIED'
        : report?.drive?.ok === false ? 'PENDING / FAILED'
            : 'NOT CONFIGURED';
    const summaryLines = [
        '',
        '==================================================',
        'END OF SHIFT SUMMARY',
        '==================================================',
        'Shift Date     : ' + (shiftReportDate || 'N/A'),
        'Shift Started  : ' + (shiftStartedAt ? getPHTime(shiftStartedAt) : 'N/A'),
        'Shift Ended    : ' + (shiftEndedAt ? getPHTime(shiftEndedAt) : 'N/A'),
        'Tasks          : ' + combinedTasks,
        'Jobs           : ' + combinedJobs,
        'Active         : ' + formatDuration(timing.combined.activeSeconds),
        'Idle           : ' + formatDuration(timing.combined.idleSeconds),
        'Break          : ' + formatDuration(pauseSummary.breakSeconds || 0),
        'Lunch          : ' + formatDuration(pauseSummary.lunchSeconds || 0),
        'BIO            : ' + formatDuration(timing.combined.bioSeconds || 0),
        'HBIO           : ' + formatDuration(timing.combined.hbioSeconds || 0),
        'Efficiency     : ' + (efficiency === null ? 'N/A' : efficiency + '%'),
        'OT Tasks       : ' + Math.max(0, Number(overtime?.tasks || 0)),
        'OT Jobs        : ' + Math.max(0, Number(overtime?.jobs || 0)),
        'OT Active      : ' + formatDuration(overtime?.activeSeconds || 0),
        'OT Idle        : ' + formatDuration(overtime?.idleSeconds || 0),
        'OT Break       : ' + formatDuration(overtimePauseSummary.breakSeconds || 0),
        'OT Lunch       : ' + formatDuration(overtimePauseSummary.lunchSeconds || 0),
        'OT BIO         : ' + formatDuration(overtime?.bioSeconds || 0),
        'OT HBIO        : ' + formatDuration(overtime?.hbioSeconds || 0)
    ];
    if (report) {
        summaryLines.push('Report         : ' + (report.reportFileName || 'Not generated'));
        summaryLines.push('Drive          : ' + driveStatus);
    }
    summaryLines.push('==================================================', '');
    const summary = summaryLines.join('\n');
    fs.appendFileSync(getTodayLogFile(), summary + '\n');

}

function broadcastToBrowser(messageType, extra = {}) {

    const dataPayload = JSON.stringify({
        action: messageType,
        ...extra,
        controllerVersion: CONTROLLER_VERSION,
        controllerRevision: CONTROLLER_RELEASE_REVISION,
        trackingMode,
        shiftStarted,
        shiftStartedAt,
        shiftEndedAt,
        shiftReportDate,
        shiftSchedule: getShiftSchedule(),
        overtime: overtimeTimingSnapshot(),
        reportSettings: getPublicReportSettings(),
        breakState: getBreakState(),
        specialSessionState: getSpecialSessionState(),
        modeTiming: getModeTimingSnapshot(),
        intervalCounters: getIntervalCounters(),
        mode2: {
            taskCompleted: mode2TaskCompleted,
            jobsCompleted: mode2JobsCompleted,
            deletedBoxes: mode2DeletedBoxes,
            emptyAreaConfirmation: mode2EmptyAreaConfirmation,
            emptyAreaNoMatchFound: mode2EmptyAreaNoMatchFound,
            unblurredPerson: mode2UnblurredPerson,
            skippedTask: mode2SkippedTask
        },
        allTimeTasks,
        totalTaskCompleted,
        totalJobsCompleted,
        currentJobId: currentJobId === 'No Active Job Detected' ? 'None' : currentJobId,
        agentStatus: lastStatusPH,
        currentInterval: currentInterval ? {
            number: currentInterval.number,
            tasks: currentInterval.tasks,
            jobs: currentInterval.jobs,
            started: currentInterval.started,
            ended: currentInterval.ended
        } : null
    });
    clients.forEach(client => {
        try {
            client.write(`data: ${dataPayload}\n\n`);
        } catch (err) {
            console.error('❌ SSE broadcast error:', err);
        }
    });

}
function controllerRestartSafetyState() {

    if (!shiftStarted) return { safe:true, status:lastStatusPH };

    if (jobConfirmed && Number(jobTaskCount || 0) > 0) {
        return {
            safe:false,
            error:'RESTART_DEFERRED_ACTIVE_JOB',
            message:'Finish the current tracked job before restarting Auto Tracker so its job-level tasks and timing are not lost.',
            status:lastStatusPH,
            currentJobId:currentJobId || null,
            jobTaskCount:Number(jobTaskCount || 0)
        };
    }

    if (onBreak || specialSessions.active || ['BREAK', 'BIO', 'HBIO'].includes(String(lastStatusPH || '').toUpperCase())) {
        return {
            safe:false,
            error:'RESTART_DEFERRED_PAUSE',
            message:'Resume from Break/Lunch/BIO/HBIO before restarting Auto Tracker so pause timing remains accurate.',
            status:lastStatusPH
        };
    }

    if (String(lastStatusPH || '').toUpperCase() === 'IDLE') {
        return {
            safe:false,
            error:'RESTART_DEFERRED_IDLE',
            message:'Return the tracker to ACTIVE before restarting so the current idle session is closed accurately.',
            status:lastStatusPH
        };
    }

    return { safe:true, status:lastStatusPH };

}

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

// =========================================
// FUNCTION RESET SHIFT MEASUREMENT WINDOW
// Search: resetShiftMeasurementWindow
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function resetShiftMeasurementWindow(now = Date.now()) {

    allTimeTasks = 0;
    totalTaskCompleted = 0;
    totalJobsCompleted = 0;
    completedJobs = [];
    intervalHistory = [];
    intervalStats = Object.fromEntries([1, 2, 3].map(number => ['interval' + number, {
        jobs: [],
        tasks: 0,
        idle: 0,
        active: 0
    }]));
    startNewInterval(1, now);

    if (breakTimer !== null) clearTimeout(breakTimer);
    breakTimer = null;
    onBreak = false;
    breakStart = null;
    breakSessions = [];
    resetSpecialSessions(coverageDate(now));

    idleStartTime = null;
    idleStartDisplay = '';
    idleReason = 'Unknown';
    lastJobFinished = null;
    previousJobId = 'None';
    pendingJobId = '';
    pendingJobUrl = '';
    pendingJobDescription = '';
    jobConfirmed = false;
    lastTotalTasksDone = 0;
    jobTaskCount = 0;
    jobIdleSeconds = 0;
    jobBreakSeconds = 0;
    jobBioSeconds = 0;
    jobHbioSeconds = 0;
    jobTrackingMode = trackingMode;
    jobStartedAt = now;
    jobStartTime = now;
    coverageLastPosition = 0;
    coverageTaskCount = 0;
    coverageLastEventKey = '';
    for (const jobId of Object.keys(jobTasks)) delete jobTasks[jobId];
    processedSubmitRequests.clear();

    resetCoverageCounters(true);
    resetModeTiming();
    overtimeStats = { tasks: 0, jobs: 0, activeMs: 0, idleMs: 0, breakMs: 0, bioMs: 0, hbioMs: 0 };
    earlyManualIntervalAdvance = null;
    shiftEndedAt = null;
    shiftReportDate = coverageDate(now);

}

// =========================================
// FUNCTION START SHIFT TRACKING
// Search: startShiftTracking
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function startShiftTracking() {

    if (shiftStarted) {
        return {
            success: true,
            alreadyStarted: true,
            shiftStarted,
            shiftStartedAt,
            shiftReportDate,
            shiftSchedule: getShiftSchedule(),
            manualIntervalReset: currentManualIntervalResetState(),
            overtime: overtimeTimingSnapshot(),
            controllerVersion: CONTROLLER_VERSION,
            controllerRevision: CONTROLLER_RELEASE_REVISION,
            status: lastStatusPH,
            agentStatus: lastStatusPH,
            trackingMode,
            modeTiming: getModeTimingSnapshot(),
            reportSettings: getPublicReportSettings()
        };
    }
    if (!modeKeyFor(trackingMode)) {
        return {
            success: false,
            error: 'TRACKING_MODE_REQUIRED',
            message: 'Select Confirmation or Coverage before starting the shift.'
        };
    }

    const now = Date.now();
    shiftDepartment = normalizeDepartment(loadReportUploadConfig()?.department || shiftDepartment || 'OOS', 'OOS') || 'OOS';
    const clearedPreStartCounters = totalTaskCompleted > 0
        || totalJobsCompleted > 0
        || mode2TaskCompleted > 0
        || mode2JobsCompleted > 0
        || completedJobs.length > 0
        || getModeTimingSnapshot(now).combined.activeSeconds > 0
        || getModeTimingSnapshot(now).combined.idleSeconds > 0;

    lastStatusPH = 'ACTIVE';
    resetShiftMeasurementWindow(now);
    shiftStarted = true;
    shiftStartedAt = now;
    shiftEndedAt = null;
    shiftReportDate = coverageDate(now);
    lastStatusPH = 'ACTIVE';
    idleStartTime = null;
    idleStartDisplay = '';
    idleReason = 'Unknown';
    timingSegmentMode = trackingMode;
    timingSegmentStatus = 'ACTIVE';
    timingSegmentStartedAt = now;
    jobStartedAt = now;
    jobStartTime = now;

    saveStats();
    if (clearedPreStartCounters) {
        logWithTimestamp('SHIFT START BASELINE RESET: Pre-start counters/timing were cleared so report metrics use the same measurement window.');
    }
    lastLogTimePH = logWithTimestamp('SHIFT TRACKING STARTED');
    broadcastToBrowser('shift_started', {
        message: 'Shift tracking started.',
        measurementWindowReset: true,
        shiftSchedule: getShiftSchedule(),
        overtime: overtimeTimingSnapshot()
    });
    scheduleDashboard();
    return {
        success: true,
        shiftStarted,
        shiftStartedAt,
        shiftReportDate,
        shiftSchedule: getShiftSchedule(),
        overtime: overtimeTimingSnapshot(),
        controllerVersion: CONTROLLER_VERSION,
        measurementWindowReset: true,
        clearedPreStartCounters,
        status: lastStatusPH,
        agentStatus: lastStatusPH,
        trackingMode,
        allTimeTasks,
        totalTaskCompleted,
        totalJobsCompleted,
        mode2: {
            taskCompleted: mode2TaskCompleted,
            jobsCompleted: mode2JobsCompleted,
            deletedBoxes: mode2DeletedBoxes,
            emptyAreaConfirmation: mode2EmptyAreaConfirmation,
            emptyAreaNoMatchFound: mode2EmptyAreaNoMatchFound,
            unblurredPerson: mode2UnblurredPerson,
            skippedTask: mode2SkippedTask
        },
        modeTiming: getModeTimingSnapshot(),
        breakState: getBreakState(),
        specialSessionState: getSpecialSessionState(),
        intervalCounters: getIntervalCounters(),
        reportSettings: getPublicReportSettings()
    };

}

// =========================================
// FUNCTION SET TRACKER MODE
// Search: setTrackerMode
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function setTrackerMode(mode) {

    const selected = Number(mode);
    if (selected !== 1 && selected !== 2) return false;
    if (trackingMode === selected) return true;
    if (jobConfirmed && jobTaskCount > 0) {
        console.warn('⚠️ Tracking mode change blocked while the current job has tracked tasks.');
        return false;
    }
    const now = Date.now();
    settleModeTiming(now);
    trackingMode = selected;
    timingSegmentMode = selected;
    timingSegmentStatus = lastStatusPH;
    timingSegmentStartedAt = now;
    if (!jobConfirmed || jobTaskCount === 0) {
        jobTrackingMode = selected;
    }
    syncLegacyTiming(now);
    return true;

}

// =========================================
// FUNCTION SELECT TRACKER MODE
// Search: selectTrackerMode
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
async function selectTrackerMode() {

    if (trackingMode === 1 || trackingMode === 2) return true;
    console.clear();
    console.log("TASK TRACKER | Select mode");
    console.log("[1] Confirmation  [2] Coverage  [3] Exit");
    while (true) {
        const answer = await new Promise(resolve => rl.question("Mode: ", resolve));
        if (answer.trim() === "3") {
            rl.close();
            process.exit(0);
        }
        if (setTrackerMode(answer.trim())) return true;
        console.log("Please enter 1, 2, or 3.");
    }

}

// =========================================
// FUNCTION SANITIZE TAMPERMONKEY IDENTITY
// Search: sanitizeTampermonkeyIdentity
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function sanitizeTampermonkeyIdentity(value) {

    const name = String(value?.name || '').trim().slice(0, 200);
    const namespace = String(value?.namespace || '').trim().slice(0, 500);
    const version = String(value?.version || '').trim().slice(0, 80);
    const revision = Math.max(0, Math.floor(Number(value?.revision ?? value?.releaseRevision ?? 0) || 0));
    if (!name || !namespace) return null;
    return { name, namespace, version: version || null, revision };

}

// =========================================
// FUNCTION RESOLVE TAMPERMONKEY INSTALLED IDENTITY
// Search: resolveTampermonkeyInstalledIdentity
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function resolveTampermonkeyInstalledIdentity(value, controllerInfo = null) {

    const direct = sanitizeTampermonkeyIdentity(value);
    if (direct) return direct;

    const version = String(
        typeof value === 'string' || typeof value === 'number'
            ? value
            : value?.version || ''
    ).trim();
    if (!version) return null;

    // v0.0.10 was historically shipped with the older v0.0.8 userscript name.
    // Old v0.0.10 clients send only installedVersion, not name/namespace.
    if (compareTampermonkeyVersions(version, '0.0.10') === 0) {
        return {
            name: 'Prototype Job & Task Handler Version 0.0.8 Alpha',
            namespace: 'http://tampermonkey.net/',
            version,
            revision: 0
        };
    }

    if (controllerInfo?.name && controllerInfo?.namespace) {
        return {
            name: controllerInfo.name,
            namespace: controllerInfo.namespace,
            version,
            revision: Math.max(0, Math.floor(Number(value?.revision ?? value?.releaseRevision ?? 0) || 0))
        };
    }
    return null;

}

// =========================================
// FUNCTION LOAD TAMPERMONKEY IDENTITY
// Search: loadTampermonkeyIdentity
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function loadTampermonkeyIdentity() {

    try {
        if (!fs.existsSync(tampermonkeyIdentityFile)) return null;
        const parsed = JSON.parse(fs.readFileSync(tampermonkeyIdentityFile, 'utf8'));
        const { hmac, ...core } = parsed || {};
        const expected = crypto.createHmac('sha256', integrityKey).update(JSON.stringify(core)).digest('hex');
        if (!hmac || hmac !== expected) return null;
        return sanitizeTampermonkeyIdentity(core);
    } catch {
        return null;
    }

}

// =========================================
// FUNCTION SAVE TAMPERMONKEY IDENTITY
// Search: saveTampermonkeyIdentity
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function saveTampermonkeyIdentity(value) {

    const identity = sanitizeTampermonkeyIdentity(value);
    if (!identity) return null;
    const core = {
        name: identity.name,
        namespace: identity.namespace,
        version: identity.version,
        revision: identity.revision || 0,
        updatedAt: Date.now()
    };
    const hmac = crypto.createHmac('sha256', integrityKey).update(JSON.stringify(core)).digest('hex');
    const temp = tampermonkeyIdentityFile + '.tmp';
    fs.writeFileSync(temp, JSON.stringify({ ...core, hmac }, null, 2), 'utf8');
    fs.renameSync(temp, tampermonkeyIdentityFile);
    try { fs.chmodSync(tampermonkeyIdentityFile, 0o600); } catch {}
    return identity;

}

// =========================================
// FUNCTION GET TAMPERMONKEY SCRIPT INFO
// Search: getTampermonkeyScriptInfo
// Ver 0.0.6 Alpha || 2026-09-07 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================

function readUserscriptMeta(source, key) {

    const prefix = '// @' + key + ' ';
    const line = String(source || '').split(/\r?\n/).find(item => item.trimStart().startsWith(prefix));
    return line ? line.trimStart().slice(prefix.length).trim() : null;

}

// =========================================
// FUNCTION PARSE TAMPERMONKEY SOURCE
// Search: parseTampermonkeySource
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function parseTampermonkeySource(source) {

    const text = String(source || '');
    return {
        valid: text.includes('// ==UserScript==') && text.includes('// ==/UserScript=='),
        name: readUserscriptMeta(text, 'name'),
        namespace: readUserscriptMeta(text, 'namespace'),
        version: readUserscriptMeta(text, 'version'),
        releaseRevision: readUserscriptMeta(text, 'releaseRevision'),
        updateURL: readUserscriptMeta(text, 'updateURL'),
        downloadURL: readUserscriptMeta(text, 'downloadURL')
    };

}

// =========================================
// FUNCTION GET TAMPERMONKEY SCRIPT INFO
// Search: getTampermonkeyScriptInfo
// Ver 0.0.6 Alpha || 2026-09-07 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function getTampermonkeyScriptInfo() {

    if (!fs.existsSync(tampermonkeyScriptFile)) {
        return {
            exists: false,
            valid: false,
            name: null,
            namespace: null,
            version: null,
            revision: 0,
            updateURL: null,
            downloadURL: null,
            sha256: null,
            sourcePath: tampermonkeyScriptFile
        };
    }
    const source = fs.readFileSync(tampermonkeyScriptFile, 'utf8');
    const parsed = parseTampermonkeySource(source);
    const revision = Math.max(0, Math.floor(Number(parsed.releaseRevision || 0) || 0));
    return {
        exists: true,
        valid: Boolean(parsed.valid && parsed.name && parsed.namespace && parsed.version),
        ...parsed,
        revision,
        sha256: sha256Text(source),
        sourcePath: tampermonkeyScriptFile
    };

}

// =========================================
// FUNCTION COMPARE TAMPERMONKEY VERSIONS
// Search: compareTampermonkeyVersions
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function compareTampermonkeyVersions(left, right) {

    const tokenize = value => String(value || '').trim().split(/[._+-]/).map(part => /^\d+$/.test(part) ? Number(part) : part.toLowerCase());
    const a = tokenize(left);
    const b = tokenize(right);
    const length = Math.max(a.length, b.length);
    for (let i = 0; i < length; i++) {
        const av = a[i] ?? 0;
        const bv = b[i] ?? 0;
        if (av === bv) continue;
        if (typeof av === 'number' && typeof bv === 'number') return av > bv ? 1 : -1;
        return String(av).localeCompare(String(bv), undefined, { numeric: true, sensitivity: 'base' }) > 0 ? 1 : -1;
    }
    return 0;

}

// =========================================
// FUNCTION NORMALIZE TAMPERMONKEY IDENTITY
// Search: normalizeTampermonkeyIdentity
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function normalizeTampermonkeyIdentity(source, currentInfo) {

    let output = String(source || '');
    const replaceMeta = (key, value) => {
        if (!value) return;
        const lines = output.split(/\r?\n/);
        const prefix = '// @' + key + ' ';
        const index = lines.findIndex(line => line.trimStart().startsWith(prefix));
        if (index >= 0) lines[index] = prefix + value;
        output = lines.join('\n');
    };
    replaceMeta('name', currentInfo?.name);
    replaceMeta('namespace', currentInfo?.namespace);
    replaceMeta('updateURL', currentInfo?.updateURL || 'http://127.0.0.1:9000/tampermonkey.meta.js');
    replaceMeta('downloadURL', currentInfo?.downloadURL || 'http://127.0.0.1:9000/tampermonkey.user.js');
    return output;

}

// =========================================
// FUNCTION RENDER TAMPERMONKEY SOURCE FOR INSTALLED IDENTITY
// Search: renderTampermonkeySourceForInstalledIdentity
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
// =========================================
// FUNCTION RENDER TAMPERMONKEY SOURCE FOR IDENTITY
// Search: renderTampermonkeySourceForIdentity
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function renderTampermonkeySourceForIdentity(source, identity, urls = {}) {

    const target = sanitizeTampermonkeyIdentity(identity);
    if (!target) return String(source || '');
    return normalizeTampermonkeyIdentity(source, {
        name: target.name,
        namespace: target.namespace,
        updateURL: urls.updateURL || 'http://127.0.0.1:9000/tampermonkey.meta.js',
        downloadURL: urls.downloadURL || 'http://127.0.0.1:9000/tampermonkey.user.js'
    });

}

// =========================================
// FUNCTION RENDER TAMPERMONKEY SOURCE FOR INSTALLED IDENTITY
// Search: renderTampermonkeySourceForInstalledIdentity
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function renderTampermonkeySourceForInstalledIdentity(source) {

    const persistedIdentity = loadTampermonkeyIdentity();
    if (!persistedIdentity) return String(source || '');
    return renderTampermonkeySourceForIdentity(source, persistedIdentity);

}

// =========================================
// FUNCTION RENDER LEGACY V008 TAMPERMONKEY SOURCE
// Search: renderLegacyV008TampermonkeySource
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// =========================================
function renderLegacyV008TampermonkeySource(source) {

    return renderTampermonkeySourceForIdentity(source, {
        name: 'Prototype Job & Task Handler Version 0.0.8 Alpha',
        namespace: 'http://tampermonkey.net/',
        version: '0.0.8'
    }, {
        updateURL: 'http://127.0.0.1:9000/tampermonkey-legacy-v008.meta.js',
        downloadURL: 'http://127.0.0.1:9000/tampermonkey-legacy-v008.user.js'
    });

}

// =========================================
// FUNCTION CHECK TAMPERMONKEY UPDATE
// Search: checkTampermonkeyUpdate
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function checkTampermonkeyUpdate(installedIdentity) {

    const controller = getTampermonkeyScriptInfo();
    const installedInfo = resolveTampermonkeyInstalledIdentity(installedIdentity, controller);
    if (installedInfo) saveTampermonkeyIdentity(installedInfo);
    const persistedIdentity = loadTampermonkeyIdentity();
    const installed = String(installedInfo?.version || '').trim() || null;
    const installedRevision = Math.max(0, Math.floor(Number(installedInfo?.revision || 0) || 0));
    const versionCompare = controller.version && installed
        ? compareTampermonkeyVersions(controller.version, installed)
        : 0;
    const updateAvailable = Boolean(
        controller.exists &&
        controller.valid &&
        installed &&
        (versionCompare > 0 || (versionCompare === 0 && Number(controller.revision || 0) > installedRevision))
    );
    return {
        success: controller.exists && controller.valid,
        controller,
        installedIdentity: persistedIdentity,
        installedVersion: installed,
        installedRevision,
        updateAvailable,
        sameVersion: Boolean(controller.version && installed && versionCompare === 0),
        sameRevision: Boolean(controller.version && installed && versionCompare === 0 && Number(controller.revision || 0) === installedRevision),
        applyUrl: 'http://127.0.0.1:9000/tampermonkey.user.js',
        sameBrowserRequired: true,
        overwriteExisting: Boolean(persistedIdentity),
        message: persistedIdentity
            ? 'Update will preserve the installed userscript identity and overwrite the existing Auto Tracker userscript.'
            : 'Installed userscript identity was not available; update compatibility cannot be guaranteed.'
    };

}

// =========================================
// FUNCTION STAGE TAMPERMONKEY UPDATE
// Search: stageTampermonkeyUpdate
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function stageTampermonkeyUpdate(source, installedIdentity) {

    let selectedSource = String(source || '');
    if (!selectedSource || selectedSource.length > 2 * 1024 * 1024) {
        return { success: false, error: 'INVALID_USERSCRIPT_SIZE', message: 'Select a valid TamperMonkey Mods file under 2 MB.' };
    }

    let selected = parseTampermonkeySource(selectedSource);
    if (!selected.valid || !selected.version) {
        return { success: false, error: 'INVALID_USERSCRIPT', message: 'The selected file is not a valid Tampermonkey userscript.' };
    }

    const current = getTampermonkeyScriptInfo();
    const browserIdentity = resolveTampermonkeyInstalledIdentity(installedIdentity, current);
    if (browserIdentity) saveTampermonkeyIdentity(browserIdentity);
    const targetIdentity = loadTampermonkeyIdentity() || (current.exists && current.valid ? current : null);

    if (targetIdentity) {
        selectedSource = normalizeTampermonkeyIdentity(selectedSource, {
            name: targetIdentity.name,
            namespace: targetIdentity.namespace,
            updateURL: 'http://127.0.0.1:9000/tampermonkey.meta.js',
            downloadURL: 'http://127.0.0.1:9000/tampermonkey.user.js'
        });
        selected = parseTampermonkeySource(selectedSource);

        if (selected.namespace !== targetIdentity.namespace || selected.name !== targetIdentity.name) {
            return { success: false, error: 'USERSCRIPT_IDENTITY_MISMATCH', message: 'The selected file could not be normalized to the userscript identity already installed in this browser.' };
        }
        if (current.exists && current.valid && compareTampermonkeyVersions(selected.version, current.version) < 0) {
            return { success: false, error: 'VERSION_OLDER_THAN_CONTROLLER', message: 'The selected userscript is older than the controller copy.' };
        }
    }

    const installed = String(browserIdentity?.version || '').trim();
    const installedRevision = Math.max(0, Math.floor(Number(browserIdentity?.revision || 0) || 0));
    if (current.exists && current.valid) {
        const currentSourceForBrowser = renderTampermonkeySourceForInstalledIdentity(
            fs.readFileSync(tampermonkeyScriptFile, 'utf8')
        );
        if (sha256Text(selectedSource) === sha256Text(currentSourceForBrowser)) {
            return {
                success: true,
                status: 'CURRENT',
                controller: current,
                installedIdentity: loadTampermonkeyIdentity(),
                installedVersion: installed || null,
                installedRevision,
                updateAvailable: Boolean(installed && (
                    compareTampermonkeyVersions(current.version, installed) > 0
                    || (compareTampermonkeyVersions(current.version, installed) === 0 && Number(current.revision || 0) > installedRevision)
                )),
                applyUrl: 'http://127.0.0.1:9000/tampermonkey.user.js',
                sameBrowserRequired: true,
                overwriteExisting: Boolean(loadTampermonkeyIdentity()),
                message: 'The selected userscript is already the controller version for this browser identity.'
            };
        }
    }
    if (installed) {
        const selectedRevision = Math.max(0, Math.floor(Number(selected.releaseRevision || 0) || 0));
        const versionCompare = compareTampermonkeyVersions(selected.version, installed);
        if (versionCompare < 0 || (versionCompare === 0 && selectedRevision <= installedRevision)) {
            return {
                success: false,
                error: 'RELEASE_NOT_NEWER_THAN_INSTALLED',
                message: 'The selected userscript release must have a newer version or a higher same-version revision.'
            };
        }
    }

    fs.mkdirSync(path.dirname(tampermonkeyScriptFile), { recursive: true });
    const backupFolder = path.join(path.dirname(tampermonkeyScriptFile), 'Backups');
    fs.mkdirSync(backupFolder, { recursive: true });
    if (fs.existsSync(tampermonkeyScriptFile)) {
        const stamp = new Date().toISOString().replace(/[:.]/g, '-');
        fs.copyFileSync(tampermonkeyScriptFile, path.join(backupFolder, 'TamperMonkey Mods_' + stamp));
    }

    const temp = tampermonkeyScriptFile + '.tmp';
    fs.writeFileSync(temp, selectedSource, 'utf8');
    fs.renameSync(temp, tampermonkeyScriptFile);

    const controller = getTampermonkeyScriptInfo();
    logWithTimestamp('TAMPERMONKEY SOURCE UPDATED: v' + (controller.version || 'Unknown') + ' | ' + controller.sourcePath);
    return {
        success: true,
        status: 'UPDATE_STAGED',
        controller,
        installedIdentity: loadTampermonkeyIdentity(),
        installedVersion: installed || null,
        installedRevision,
        updateAvailable: Boolean(installed && (
            compareTampermonkeyVersions(controller.version, installed) > 0
            || (compareTampermonkeyVersions(controller.version, installed) === 0 && Number(controller.revision || 0) > installedRevision)
        )),
        applyUrl: 'http://127.0.0.1:9000/tampermonkey.user.js',
        sameBrowserRequired: true,
        overwriteExisting: Boolean(loadTampermonkeyIdentity()),
        message: 'TamperMonkey Mods was staged using the identity already installed in this browser. Opening the update URL will overwrite that userscript instead of creating another Auto Tracker script.'
    };

}

function normalizeTrackerBrowserName(value) {
    const text = String(value || '').toLowerCase();
    if (text.includes('brave')) return 'Brave';
    if (text.includes('zen')) return 'Zen Browser';
    if (text.includes('opera') || text.includes('opr')) return 'Opera';
    if (text.includes('edge') || text.includes('edg')) return 'Microsoft Edge';
    if (text.includes('firefox')) return 'Mozilla Firefox';
    if (text.includes('chrome') || text.includes('chromium')) return 'Google Chrome';
    return '';
}

function saveTrackerBrowserInfo(raw) {
    const name = normalizeTrackerBrowserName(raw?.name || raw?.browser || '');
    if (!name) return null;
    const record = {
        name,
        platform: String(raw?.platform || '').slice(0, 120),
        userAgent: String(raw?.userAgent || '').slice(0, 500),
        updatedAt: Date.now()
    };
    try {
        writeJsonStateFile(browserIdentityFile, record);
        return record;
    } catch (error) {
        writeControllerErrorLog('BROWSER', error, { component: 'BROWSER', errorCode: 'ERR-BROWSER-SAVE', severity: 'WARN' });
        return null;
    }
}

function loadTrackerBrowserInfo() {
    const saved = readJsonStateFile(browserIdentityFile, null);
    if (!saved || !normalizeTrackerBrowserName(saved.name)) return null;
    return { ...saved, name: normalizeTrackerBrowserName(saved.name) };
}

function windowsBrowserCandidates(name) {
    const env = process.env;
    const pf = env.ProgramFiles || 'C:\\Program Files';
    const pfx86 = env['ProgramFiles(x86)'] || 'C:\\Program Files (x86)';
    const local = env.LOCALAPPDATA || '';
    const map = {
        'Google Chrome': [
            path.join(pf, 'Google', 'Chrome', 'Application', 'chrome.exe'),
            path.join(pfx86, 'Google', 'Chrome', 'Application', 'chrome.exe'),
            local ? path.join(local, 'Google', 'Chrome', 'Application', 'chrome.exe') : ''
        ],
        'Microsoft Edge': [
            path.join(pfx86, 'Microsoft', 'Edge', 'Application', 'msedge.exe'),
            path.join(pf, 'Microsoft', 'Edge', 'Application', 'msedge.exe')
        ],
        'Brave': [
            path.join(pf, 'BraveSoftware', 'Brave-Browser', 'Application', 'brave.exe'),
            path.join(pfx86, 'BraveSoftware', 'Brave-Browser', 'Application', 'brave.exe'),
            local ? path.join(local, 'BraveSoftware', 'Brave-Browser', 'Application', 'brave.exe') : ''
        ],
        'Mozilla Firefox': [
            path.join(pf, 'Mozilla Firefox', 'firefox.exe'),
            path.join(pfx86, 'Mozilla Firefox', 'firefox.exe')
        ],
        'Zen Browser': [
            local ? path.join(local, 'Programs', 'Zen Browser', 'zen.exe') : '',
            local ? path.join(local, 'zen', 'zen.exe') : '',
            path.join(pf, 'Zen Browser', 'zen.exe')
        ],
        'Opera': [
            local ? path.join(local, 'Programs', 'Opera', 'launcher.exe') : '',
            path.join(pf, 'Opera', 'launcher.exe'),
            path.join(pfx86, 'Opera', 'launcher.exe')
        ]
    };
    return (map[name] || []).filter(Boolean);
}

function openUrlInKnownTrackerBrowser(url) {
    const saved = loadTrackerBrowserInfo();
    const forced = normalizeTrackerBrowserName(process.env.TRACKER_BROWSER_HINT || '');
    const browserName = forced || saved?.name || '';
    if (!browserName) return false;

    if (process.platform === 'win32') {
        const candidate = windowsBrowserCandidates(browserName).find(filePath => fs.existsSync(filePath));
        if (!candidate) return false;
        execFile(candidate, [url], error => {
            if (error) writeControllerErrorLog('BROWSER', error, { component: 'BROWSER', errorCode: 'ERR-BROWSER-OPEN', severity: 'WARN', browser: browserName });
        });
        console.log('[BROWSER] Opening updater in ' + browserName + '.');
        return true;
    }

    if (process.platform === 'darwin') {
        const appMap = {
            'Google Chrome':'Google Chrome', 'Microsoft Edge':'Microsoft Edge',
            'Brave':'Brave Browser', 'Mozilla Firefox':'Firefox',
            'Zen Browser':'Zen', 'Opera':'Opera'
        };
        const app = appMap[browserName];
        if (!app) return false;
        execFile('open', ['-a', app, url], error => {
            if (error) writeControllerErrorLog('BROWSER', error, { component:'BROWSER', errorCode:'ERR-BROWSER-OPEN', severity:'WARN', browser:browserName });
        });
        console.log('[BROWSER] Opening updater in ' + browserName + '.');
        return true;
    }

    const commandMap = {
        'Google Chrome':['google-chrome','chromium','chromium-browser'],
        'Microsoft Edge':['microsoft-edge','microsoft-edge-stable'],
        'Brave':['brave-browser','brave'],
        'Mozilla Firefox':['firefox'],
        'Zen Browser':['zen-browser','zen'],
        'Opera':['opera']
    };
    const commands = commandMap[browserName] || [];
    for (const command of commands) {
        try {
            const resolved = String(execFileSync('sh', ['-lc', 'command -v "$1"', 'sh', command], { encoding: 'utf8', stdio: ['ignore','pipe','ignore'] }) || '').trim();
            if (!resolved) continue;
            execFile(resolved, [url], error => {
                if (error) writeControllerErrorLog('BROWSER', error, { component:'BROWSER', errorCode:'ERR-BROWSER-OPEN', severity:'WARN', browser:browserName });
            });
            console.log('[BROWSER] Opening updater in ' + browserName + '.');
            return true;
        } catch {}
    }
    return false;
}

// =========================================
// FUNCTION OPEN TAMPERMONKEY UPDATER
// Search: openTampermonkeyUpdater
// Ver 0.0.6 Alpha || 2026-09-07 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function openTampermonkeyUpdater(mode = 'current') {

    const info = getTampermonkeyScriptInfo();
    if (!info.exists || !info.valid) {
        console.log("Tampermonkey userscript source is missing or invalid.");
        console.log("Expected: " + tampermonkeyScriptFile);
        return false;
    }
    const updaterUrl = mode === 'legacy-v008'
        ? "http://127.0.0.1:9000/tampermonkey-legacy-v008.user.js"
        : "http://127.0.0.1:9000/tampermonkey.user.js";
    console.log(mode === 'legacy-v008'
        ? "Opening legacy v0.0.8 in-place upgrader..."
        : "Opening Tampermonkey userscript installer/updater...");
    console.log("Script : " + (info.name || "Unknown"));
    console.log("Version: " + (info.version || "Unknown"));
    console.log("SHA256 : " + (info.sha256 || "Unknown"));

    if (openUrlInKnownTrackerBrowser(updaterUrl)) return true;

    console.warn('[BROWSER] The tracker browser could not be determined or its executable was not found.');
    console.warn('[BROWSER] Falling back to the operating-system default browser. Open the labeling tool and use the in-page Update button for guaranteed same-browser updates.');
    let command;
    if (process.platform === "win32") command = 'start "" "' + updaterUrl + '"';
    else if (process.platform === "darwin") command = 'open "' + updaterUrl + '"';
    else command = 'xdg-open "' + updaterUrl + '"';
    exec(command, error => {
        if (error) {
            writeControllerErrorLog('BROWSER', error, { component:'BROWSER', errorCode:'ERR-BROWSER-DEFAULT-OPEN', severity:'WARN' });
            console.error("Could not open browser automatically:", error.message);
            console.log("Open manually: " + updaterUrl);
        }
    });
    return true;

}

// =========================================
// FUNCTION SERVE TAMPERMONKEY SCRIPT
// Search: serveTampermonkeyScript
// Ver 0.0.6 Alpha || 2026-09-07 || JBallados
// =========================================
function serveTampermonkeyScript(res, mode = 'current') {

    const info = getTampermonkeyScriptInfo();
    if (!info.exists) {
        res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
        res.end("Tampermonkey source file not found.");
        return;
    }
    if (!info.valid) {
        res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
        res.end("Tampermonkey source file is not a valid userscript.");
        return;
    }
    res.writeHead(200, {
        "Content-Type": "application/javascript; charset=utf-8",
        "Cache-Control": "no-store, no-cache, must-revalidate",
        "Content-Disposition": 'inline; filename="TamperMonkey-Mods.user.js"'
    });
    const source = fs.readFileSync(tampermonkeyScriptFile, "utf8");
    res.end(mode === 'legacy-v008'
        ? renderLegacyV008TampermonkeySource(source)
        : renderTampermonkeySourceForInstalledIdentity(source));

}

// =========================================
// FUNCTION SERVE TAMPERMONKEY METADATA
// Search: serveTampermonkeyMetadata
// Ver 0.0.6 Alpha || 2026-09-07 || JBallados
// =========================================
function serveTampermonkeyMetadata(res, mode = 'current') {

    const info = getTampermonkeyScriptInfo();
    if (!info.exists) {
        res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
        res.end("Tampermonkey source file not found.");
        return;
    }
    if (!info.valid) {
        res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
        res.end("Tampermonkey source file is not a valid userscript.");
        return;
    }
    const rawSource = fs.readFileSync(tampermonkeyScriptFile, "utf8");
    const source = mode === 'legacy-v008'
        ? renderLegacyV008TampermonkeySource(rawSource)
        : renderTampermonkeySourceForInstalledIdentity(rawSource);
    const metadataMatch = source.match(/\/\/ ==UserScript==[\s\S]*?\/\/ ==\/UserScript==/);
    if (!metadataMatch) {
        res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
        res.end("Tampermonkey metadata block could not be extracted.");
        return;
    }
    res.writeHead(200, {
        "Content-Type": "application/javascript; charset=utf-8",
        "Cache-Control": "no-store, no-cache, must-revalidate"
    });
    res.end(metadataMatch[0] + "\n");

}

let dashboardRenderPending = false;
let lastDashboardSnapshot = null;

// =========================================
// FUNCTION SCHEDULE DASHBOARD
// Search: scheduleDashboard
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function scheduleDashboard() {

    if (!trackerStartupComplete || dashboardRenderPending) return;
    dashboardRenderPending = true;
    setTimeout(() => {
        dashboardRenderPending = false;
        drawDashboard();
    }, 100);

}

// =========================================
// FUNCTION DASHBOARD TEXT
// Search: dashboardText
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.6 Alpha || 2026-09-07 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function dashboardText() {

    if (trackingMode !== 1 && trackingMode !== 2) return "";
    const coverageMode = trackingMode === 2;
    const specialState = getSpecialSessionState();
    const bio = specialState.BIO;
    const hbio = specialState.HBIO;
    const schedule = getShiftSchedule();
    const timing = getModeTimingSnapshot();
    const combined = timing.combined || {};
    const pauseStates = getPauseStates();
    const breakState = pauseStates.break;
    const lunchState = pauseStates.lunch;
    const shiftLabel = !shiftStarted
        ? 'NOT STARTED'
        : schedule?.department === 'ENCORD'
            ? 'ENCORD SHIFT'
            : schedule?.dayShift
                ? 'OOS DAY SHIFT'
                : 'OOS MID / NIGHT SHIFT';
    const breakUsedSeconds = Math.max(0, Number(breakState?.usedSeconds || 0));
    const lunchUsedSeconds = Math.max(0, Number(lunchState?.usedSeconds || 0));
    const line = '='.repeat(76);
    const thin = '-'.repeat(76);
    const lines = [
        line,
        ' TRINOVATION AUTO COUNT TRACKER | v' + CONTROLLER_VERSION + '-r' + CONTROLLER_RELEASE_REVISION,
        thin,
        ' Mode   : ' + (coverageMode ? 'COVERAGE' : 'CONFIRMATION') + ' | Status: ' + lastStatusPH + ' | Shift: ' + shiftLabel,
        ' Job    : ' + (currentJobId || 'No active job'),
        ' Totals : ' + (coverageMode ? mode2TaskCompleted : totalTaskCompleted) + ' tasks | ' + (coverageMode ? mode2JobsCompleted : totalJobsCompleted) + ' jobs',
        ' Time   : Active ' + formatDuration(combined.activeSeconds || 0)
            + ' | Idle ' + formatDuration(combined.idleSeconds || 0)
            + ' | Break ' + formatDuration(breakUsedSeconds)
            + ' | Lunch ' + formatDuration(lunchUsedSeconds)
    ];

    if (schedule?.department === 'ENCORD') {
        lines.push(
            ' Pause  : Break ' + Number(breakState.allowanceMinutes || 0) + 'm | Remaining ' + formatDuration(breakState.remainingSeconds || 0)
            + ' || Lunch ' + Number(lunchState.allowanceMinutes || 0) + 'm | Remaining ' + formatDuration(lunchState.remainingSeconds || 0)
        );
    } else {
        const state = schedule?.dayShift ? lunchState : breakState;
        lines.push(
            ' Pause  : ' + (schedule?.dayShift ? 'Lunch' : 'Break') + ' ' + Number(state.allowanceMinutes || 0)
            + 'm | Remaining ' + formatDuration(state.remainingSeconds || 0)
        );
    }

    lines.push(
        ' BIO    : S' + bio.currentSession + '/' + bio.maxSessions + ' ' + formatDuration(bio.currentRemainingSeconds) + ' left | HBIO: S' + hbio.currentSession + '/' + hbio.maxSessions + ' ' + formatDuration(hbio.currentRemainingSeconds) + ' left',
        ' Last   : ' + lastLogTimePH + ' | Last job: ' + (lastJobFinished || 'None'),
        thin,
        ' INTERVALS'
    );

    const intervals = [...intervalHistory];
    if (currentInterval) intervals.push(currentInterval);
    for (const interval of intervals) {
        const isCurrent = interval === currentInterval;
        const totals = coverageMode ? isCurrent ? currentCoverageTotals() : interval.coverage || {} : isCurrent ? currentConfirmationTotals() : confirmationTotalsFor(interval);
        lines.push(' ' + getIntervalName(interval.number) + ' | ' + getPHTime(interval.started) + ' - ' + (isCurrent ? 'CURRENT' : getPHTime(interval.ended)) + ' | Tasks: ' + (totals.taskCompleted ?? 'N/A') + ' | Jobs: ' + (totals.jobsCompleted ?? 'N/A'));
        if (coverageMode) {
            lines.push('   Empty Confirmed: ' + (totals.emptyAreaConfirmation ?? 'N/A') + ' | No Match: ' + (totals.emptyAreaNoMatchFound ?? 'N/A') + ' | Unblurred: ' + (totals.unblurredPerson ?? 'N/A'));
            lines.push('   Deleted: ' + (totals.deletedBoxes ?? 'N/A') + ' | Skipped: ' + (totals.skippedTask ?? 'N/A'));
        }
    }
    const pauseCommand = schedule?.department === 'ENCORD' ? 'break | lunch' : schedule?.dayShift ? 'lunch' : 'break';
    lines.push(
        thin,
        ' QUICK KEYS: [1] Reset interval  [2] Reset all  [3] Restart  [' + (coverageMode ? '4] Confirmation' : '5] Coverage'),
        ' COMMANDS : bio | hbio | ' + pauseCommand + ' | resume | report <LastName> | upload latest | verify report',
        line
    );
    return lines.join("\n");

}

function drawDashboard() {

    const output = dashboardText();
    if (!output || output === lastDashboardSnapshot) return;
    lastDashboardSnapshot = output;
    console.clear();
    console.log(output);

}

// =========================================
// FUNCTION FORMAT DURATION
// Search: formatDuration
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function formatDuration(seconds) {

    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor(seconds % 3600 / 60);
    const secs = seconds % 60;
    if (hrs > 0) {
        return `${hrs}h ${mins}m ${secs}s`;
    }
    return `${mins}m ${secs}s`;

}
rl.on('line', input => {
    if (!trackerStartupComplete) return;
    const rawCommand = input.trim();
    const command = rawCommand.toLowerCase();
    if (command === "4") {
        setTrackerMode(1);
        console.log("");
        debugLog("✅ TRACKING MODE CHANGED TO MODE 1 — CONFIRMATION");
        console.log("");
        saveStats();
        broadcastToBrowser("tracking_mode_changed");
        scheduleDashboard();
        return;
    } else if (command === "5") {
        setTrackerMode(2);
        console.log("");
        debugLog("✅ TRACKING MODE CHANGED TO MODE 2 — COVERAGE");
        console.log("");
        saveStats();
        broadcastToBrowser("tracking_mode_changed");
        scheduleDashboard();
        return;
    } else if (command === "break") {
        const result = startBreak('BREAK');
        if (result?.success === false) console.log('! ' + (result.message || result.error));
        return;
    } else if (command === "lunch") {
        const result = startBreak('LUNCH');
        if (result?.success === false) console.log('! ' + (result.message || result.error));
        return;
    } else if (command === "bio") {
        startSpecialSession('BIO');
        return;
    } else if (command === "hbio") {
        startSpecialSession('HBIO');
        return;
    } else if (command === "resume") {
        resumePauseSession();
        return;
    } else if (command === "update tampermonkey") {
        const info = getTampermonkeyScriptInfo();
        console.log("");
        console.log("Tampermonkey source: " + info.sourcePath);
        console.log("Version: " + (info.version || "Unknown"));
        console.log("If the installed userscript is already v0.0.10+, use the tracker Web UI Update Tampermonkey button.");
        console.log("If the installed userscript is still v0.0.8, it does not have that button yet.");
        console.log("Keep this controller running, then use Tampermonkey's own update check in the SAME browser.");
        console.log("The v0.0.8 script already points to the local @updateURL/@downloadURL, so it can migrate to v0.0.10 without opening the OS default browser.");
        console.log("");
        return;
    } else if (command === "verify report") {
        const latest = findLatestGeneratedReport();
        if (!latest) console.log("No generated report found.");
        else {
            const verification = verifyGeneratedReport(latest);
            console.log(verification.ok ? "REPORT VERIFIED: " + path.basename(latest) : "REPORT INTEGRITY FAILED: " + path.basename(latest), verification);
        }
        return;
    } else if (command === "report") {
        console.log("Use: report <LastName>");
        console.log("Apps Script upload runs automatically when this device is registered.");
        return;
    } else if (command.startsWith("report ")) {
        const parts = rawCommand.split(/\s+/);
        const lastName = parts[1] || '';
        generateReport(null, { lastName }).then(result => {
            console.log(result && result.success ? "Report saved: " + result.reportFileName : "No activity to report yet.");
            if (result?.drive?.ok === false) console.log("Drive upload warning:", result.drive.error || result.drive.results);
        }).catch(error => {
            console.error("Failed to generate report:", error.message);
        });
        return;
    } else if (command === "upload latest") {
        uploadLatestReport().catch(error => {
            console.error("[UPLOAD] Failed to upload latest report:", error.message);
        });
        return;
    } else if (command === "1" || command === "reset") {
        const result = resetInterval({ confirmEarly: false, source: 'terminal' });
        if (result?.requiresConfirmation) {
            console.log('⚠ ' + result.message);
            console.log('Type "reset confirm" to continue with the early interval reset.');
        } else if (result?.success === false) {
            console.log('⚠ ' + (result.message || result.error));
        }
    } else if (command === "reset confirm") {
        const result = resetInterval({ confirmEarly: true, source: 'terminal' });
        if (result?.success === false) console.log('⚠ ' + (result.message || result.error));
    } else if (command === "2" || command === "reset all") {
        resetAllCounters();
    } else if (command === "3" || command === "restart") {
        const restartSafety = controllerRestartSafetyState();
        if (!restartSafety.safe) {
            console.log('⚠ Restart postponed: ' + restartSafety.message);
            logWithTimestamp(
                'CONTROLLER RESTART POSTPONED: ' + restartSafety.message,
                'WARN',
                'UPDATE',
                { eventCode:'EVT-UPDATE-RESTART-DEFERRED', reason:restartSafety.error }
            );
            return;
        }
        saveStats();
        console.log("Restarting server...");
        logWithTimestamp("COMMAND: Restart Initiated Restarting Tracker");
        process.exit(0);
    } else if (command === "") {
        return;
    } else {
        lastLogTimePH = "INVALID CMD";
        logWithTimestamp(`ERROR: Unknown command received: "${input}"`);
        scheduleDashboard();
        console.log("");
        console.log("❌ UNKNOWN COMMAND: \"" + input + "\"");
        console.log("Available commands: 'bio', 'hbio', 'break' or 'lunch' (shift-dependent), 'resume', 'reset', 'reset confirm', 'reset all', 'report <LastName>', 'upload latest', 'verify report', 'restart', 'update tampermonkey'");
        console.log("");
    }
});
function isAllowedTrackerOrigin(origin) {
    const value = String(origin || '').trim();
    if (!value) return true;
    try {
        const parsed = new URL(value);
        const host = String(parsed.hostname || '').toLowerCase();
        const protocol = String(parsed.protocol || '').toLowerCase();
        if ((host === 'localhost' || host === '127.0.0.1' || host === '::1') && (protocol === 'http:' || protocol === 'https:')) {
            return true;
        }
        return protocol === 'https:' && (host === 'labeling-tools.augmoto.com' || host.endsWith('.labeling-tools.augmoto.com'));
    } catch {
        return false;
    }
}

const server = http.createServer((req, res) => {
    const requestStartedAt = Date.now();
    const suppliedTraceId = String(req.headers['x-tracker-trace-id'] || '').trim();
    const requestTraceId = /^[A-Za-z0-9._:-]{8,120}$/.test(suppliedTraceId)
        ? suppliedTraceId
        : createTraceId('REQ');
    res.setHeader('X-Tracker-Trace-Id', requestTraceId);
    res.on('finish', () => {
        const statusCode = Number(res.statusCode || 0);
        writeStructuredActivityLog('api.request.completed', {
            method: req.method,
            url: String(req.url || '').slice(0, 500),
            statusCode,
            durationMs: Math.max(0, Date.now() - requestStartedAt)
        }, {
            severity: statusCode >= 500 ? 'ERROR' : statusCode >= 400 ? 'WARN' : 'INFO',
            component: 'API',
            eventCode: 'EVT-API-REQUEST-COMPLETE',
            traceId: requestTraceId
        });
    });
    if (trackerStartupComplete) {
        ensureCoverageDate();
        ensureCurrentShiftInterval();
    }
    const requestOrigin = String(req.headers.origin || '').trim();
    if (!isAllowedTrackerOrigin(requestOrigin)) {
        writeStructuredActivityLog('api.request.blocked_origin', {
            method: req.method,
            url: String(req.url || '').slice(0, 500),
            origin: requestOrigin.slice(0, 500)
        }, {
            severity: 'WARN',
            component: 'API',
            eventCode: 'EVT-API-ORIGIN-BLOCKED',
            traceId: requestTraceId
        });
        res.writeHead(403, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
        res.end(JSON.stringify({ success: false, error: 'ORIGIN_NOT_ALLOWED', message: 'This local tracker API only accepts the labeling site and localhost.' }));
        return;
    }
    if (requestOrigin) {
        res.setHeader('Access-Control-Allow-Origin', requestOrigin);
        res.setHeader('Vary', 'Origin');
    }
    res.setHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Tracker-Trace-Id');
    res.setHeader('Cache-Control', 'no-store');
    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }
    if (req.method === 'GET' && req.url === '/stats') {
        res.writeHead(200, {
            'Content-Type': 'application/json'
        });
        res.end(JSON.stringify({
            allTimeTasks,
            totalTaskCompleted,
            totalJobsCompleted,
            controllerVersion: CONTROLLER_VERSION,
            controllerRevision: CONTROLLER_RELEASE_REVISION,
            latestRelease: latestReleaseState,
            updateInstall: lastUpdateInstallState,
            lastReportStatus,
            systemHealth: getSystemHealth(),
            browser: loadTrackerBrowserInfo(),
            trackingMode,
            shiftStarted,
            shiftStartedAt,
            shiftEndedAt,
            shiftReportDate,
            shiftDepartment,
            shiftSchedule: getShiftSchedule(),
            manualIntervalReset: currentManualIntervalResetState(),
            overtime: overtimeTimingSnapshot(),
            reportSettings: getPublicReportSettings(),
            breakState: getBreakState(),
            pauseStates: getPauseStates(),
            specialSessionState: getSpecialSessionState(),
            modeTiming: getModeTimingSnapshot(),
            intervalCounters: getIntervalCounters(),
            mode2: {
                taskCompleted: mode2TaskCompleted,
                jobsCompleted: mode2JobsCompleted,
                deletedBoxes: mode2DeletedBoxes,
                emptyAreaConfirmation: mode2EmptyAreaConfirmation,
                emptyAreaNoMatchFound: mode2EmptyAreaNoMatchFound,
                unblurredPerson: mode2UnblurredPerson,
                skippedTask: mode2SkippedTask
            },
            currentJobId: currentJobId === "No Active Job Detected" ? "None" : currentJobId,
            agentStatus: lastStatusPH,
            currentInterval: currentInterval ? {
                number: currentInterval.number,
                tasks: currentInterval.tasks,
                jobs: currentInterval.jobs,
                started: currentInterval.started,
                ended: currentInterval.ended
            } : null
        }));
        return;
    }
    if (req.method === 'GET' && req.url === '/diagnostics.txt') {
        res.writeHead(200, {
            'Content-Type': 'text/plain; charset=utf-8',
            'Content-Disposition': 'attachment; filename="Trinovation_Auto_Tracker_Diagnostics.txt"',
            'Cache-Control': 'no-store'
        });
        res.end(buildDiagnosticExportText());
        return;
    }
    if (req.method === 'GET' && req.url === '/tampermonkey-info') {
        const info = getTampermonkeyScriptInfo();
        res.writeHead(info.exists && info.valid ? 200 : 404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(info));
        return;
    }
    if (req.method === 'GET' && req.url === '/tampermonkey.meta.js') {
        serveTampermonkeyMetadata(res);
        return;
    }
    if (req.method === 'GET' && req.url === '/tampermonkey.user.js') {
        serveTampermonkeyScript(res);
        return;
    }
    if (req.method === 'GET' && req.url === '/tampermonkey-legacy-v008.meta.js') {
        serveTampermonkeyMetadata(res, 'legacy-v008');
        return;
    }
    if (req.method === 'GET' && req.url === '/tampermonkey-legacy-v008.user.js') {
        serveTampermonkeyScript(res, 'legacy-v008');
        return;
    }
    if (req.method === 'GET' && req.url === '/events') {
        res.writeHead(200, {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive'
        });
        clients.push(res);
        req.on('close', () => {
            clients = clients.filter(client => client !== res);
        });
        return;
    }
    if (req.method === 'GET' && (req.url === '/dashboard' || req.url.startsWith('/dashboard/'))) {
        const dashboardRoot = path.resolve(__dirname, 'dashboard');
        let relativePath = req.url === '/dashboard' ? 'index.html' : String(req.url || '').slice('/dashboard/'.length).split('?')[0];
        try {
            relativePath = decodeURIComponent(relativePath);
        } catch {
            res.writeHead(400, { 'Content-Type': 'text/plain; charset=utf-8' });
            res.end('Invalid dashboard path');
            return;
        }
        const filePath = path.resolve(dashboardRoot, relativePath);
        if (filePath !== dashboardRoot && !filePath.startsWith(dashboardRoot + path.sep)) {
            res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
            res.end('Dashboard path is not allowed');
            return;
        }
        if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
            const ext = path.extname(filePath).toLowerCase();
            const contentType = ext === '.css'
                ? 'text/css; charset=utf-8'
                : ext === '.js'
                    ? 'application/javascript; charset=utf-8'
                    : 'text/html; charset=utf-8';
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(fs.readFileSync(filePath, 'utf8'));
            return;
        }
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('Not found');
        return;
    }
    if (req.method === 'POST') {
        let body = '';
        let bodyBytes = 0;
        let bodyTooLarge = false;
        req.on('data', chunk => {
            if (bodyTooLarge) return;
            bodyBytes += Buffer.byteLength(chunk);
            if (bodyBytes > MAX_API_BODY_BYTES) {
                bodyTooLarge = true;
                return;
            }
            body += chunk.toString();
        });
        req.on('end', async () => {
            if (bodyTooLarge) {
                writeStructuredActivityLog('api.request.body_too_large', {
                    method: req.method,
                    url: String(req.url || '').slice(0, 500),
                    bodyBytes,
                    maxBodyBytes: MAX_API_BODY_BYTES
                }, {
                    severity: 'WARN',
                    component: 'API',
                    eventCode: 'EVT-API-BODY-TOO-LARGE',
                    traceId: requestTraceId
                });
                res.writeHead(413, { 'Content-Type': 'application/json' });
                return res.end(JSON.stringify({
                    success: false,
                    error: 'REQUEST_BODY_TOO_LARGE',
                    message: 'The local tracker request exceeded the allowed size.',
                    maxBodyBytes: MAX_API_BODY_BYTES
                }));
            }
            try {
                const payload = JSON.parse(body);
                writeStructuredActivityLog('api.action.received', {
                    action: String(payload.action || 'unknown').slice(0, 120),
                    bodyBytes: Buffer.byteLength(body || '', 'utf8'),
                    trackingMode,
                    shiftStarted,
                    currentJobId: currentJobId === 'No Active Job Detected' ? null : currentJobId
                }, {
                    severity: 'INFO',
                    component: 'API',
                    eventCode: 'EVT-API-ACTION-RECEIVED',
                    traceId: requestTraceId
                });
                if ((payload.action === 'click_submit' || payload.action === 'coverage_skip') && !shiftStarted) {
                    res.writeHead(409, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify({
                        success: false,
                        error: 'SHIFT_NOT_STARTED',
                        message: 'Click Start Shift before tracker timing or task counting begins.'
                    }));
                }
                if ((payload.action === 'click_submit' || payload.action === 'coverage_skip') && (Number(payload.pageMode) === 1 || Number(payload.pageMode) === 2) && Number(payload.pageMode) !== trackingMode) {
                    res.writeHead(409, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify({
                        success: false,
                        error: 'TRACKING_MODE_MISMATCH',
                        trackingMode,
                        pageMode: Number(payload.pageMode)
                    }));
                }
                if (payload.action === 'set_tracking_mode') {
                    const requestedMode = Number(payload.mode);
                    if (requestedMode !== 1 && requestedMode !== 2) {
                        res.writeHead(400, { 'Content-Type': 'application/json' });
                        return res.end(JSON.stringify({ success: false, error: 'Tracking mode must be 1 or 2.' }));
                    }
                    if (requestedMode !== trackingMode && jobConfirmed && jobTaskCount > 0) {
                        res.writeHead(409, { 'Content-Type': 'application/json' });
                        return res.end(JSON.stringify({
                            success: false,
                            error: 'ACTIVE_JOB_MODE_LOCKED',
                            message: 'Finish or leave the current tracked job before changing modes.',
                            trackingMode
                        }));
                    }
                    if (requestedMode !== trackingMode && (onBreak || specialSessions.active)) {
                        res.writeHead(409, { 'Content-Type': 'application/json' });
                        return res.end(JSON.stringify({
                            success: false,
                            error: 'ACTIVE_PAUSE_MODE_LOCKED',
                            message: 'Resume the active Break/Lunch/BIO/HBIO session before changing Confirmation/Coverage mode.',
                            trackingMode,
                            breakState: getBreakState(),
                            specialSessionState: getSpecialSessionState()
                        }));
                    }
                    if (!setTrackerMode(requestedMode)) {
                        res.writeHead(409, { 'Content-Type': 'application/json' });
                        return res.end(JSON.stringify({ success: false, error: 'TRACKING_MODE_CHANGE_BLOCKED', trackingMode }));
                    }
                    saveStats();
                    broadcastToBrowser('tracking_mode_changed');
                    scheduleDashboard();
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify({
                        success: true,
                        status: 'TRACKING_MODE_CHANGED',
                        trackingMode,
                        shiftStarted,
                        shiftStartedAt,
                        reportSettings: getPublicReportSettings(),
                        modeTiming: getModeTimingSnapshot(),
                        intervalCounters: getIntervalCounters(),
                        mode2: {
                            taskCompleted: mode2TaskCompleted,
                            jobsCompleted: mode2JobsCompleted,
                            deletedBoxes: mode2DeletedBoxes,
                            emptyAreaConfirmation: mode2EmptyAreaConfirmation,
                            emptyAreaNoMatchFound: mode2EmptyAreaNoMatchFound,
                            unblurredPerson: mode2UnblurredPerson,
                            skippedTask: mode2SkippedTask
                        },
                        currentJobId: currentJobId === 'No Active Job Detected' ? 'None' : currentJobId,
                        agentStatus: lastStatusPH,
                        currentInterval
                    }));
                }
                if (payload.action === 'diagnostics_recent') {
                    const errors = getRecentDiagnosticErrors(payload.limit || 20);
                    const queue = readJsonStateFile(uploadQueueFile, { version: 1, items: [] });
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify({
                        success: true,
                        controllerVersion: CONTROLLER_VERSION,
                        systemHealth: getSystemHealth(),
                        browser: loadTrackerBrowserInfo(),
                        pendingUploads: Array.isArray(queue.items) ? queue.items.length : 0,
                        errors
                    }));
                }
                if (payload.action === 'client_error') {
                    const message = String(payload.message || 'Client-side tracker error').slice(0, 3000);
                    const clientError = new Error(message);
                    clientError.name = String(payload.errorName || 'FrontendError').slice(0, 120);
                    if (payload.stack) clientError.stack = String(payload.stack).slice(0, 10000);
                    const record = writeControllerErrorLog('TAMPERMONKEY', clientError, {
                        component: 'FRONTEND',
                        errorCode: String(payload.errorCode || 'ERR-FRONTEND-CLIENT').slice(0, 96),
                        severity: String(payload.severity || 'ERROR').slice(0, 16),
                        traceId: String(payload.traceId || requestTraceId).slice(0, 120),
                        eventType: String(payload.eventType || '').slice(0, 80),
                        page: String(payload.page || '').slice(0, 1000),
                        trackerVersion: String(payload.trackerVersion || '').slice(0, 40),
                        controllerVersionReported: String(payload.controllerVersion || '').slice(0, 40),
                        browser: String(payload.browser || '').slice(0, 120),
                        method: String(payload.method || '').slice(0, 20),
                        endpoint: String(payload.endpoint || '').slice(0, 500),
                        httpStatus: Number(payload.httpStatus || 0) || null,
                        trackerStatus: String(payload.trackerStatus || '').slice(0, 40),
                        trackingMode: Number(payload.trackingMode || 0) || null,
                        shiftStarted: payload.shiftStarted === true,
                        currentJobId: String(payload.currentJobId || '').slice(0, 160) || null,
                        responsePreview: String(payload.responsePreview || '').slice(0, 1200)
                    });
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify({
                        success: true,
                        logged: true,
                        traceId: record?.traceId || requestTraceId,
                        errorCode: record?.errorCode || 'ERR-FRONTEND-CLIENT'
                    }));
                }
                if (payload.action === 'start_shift') {
                    const result = startShiftTracking();
                    const code = result.success === false ? 409 : 200;
                    res.writeHead(code, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify(result));
                }
                if (payload.action === 'end_shift') {
                    const result = await endShiftTracking({ generateReport: payload.generateReport !== false });
                    const code = result.success === false ? 409 : 200;
                    res.writeHead(code, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify(result));
                }
                if (payload.action === 'get_report_upload_settings') {
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify({
                        success: true,
                        uploadSettings: getPublicReportUploadSettings(),
                        reportSettings: getPublicReportSettings()
                    }));
                }
                if (payload.action === 'configure_report_upload' || payload.action === 'register_report_upload_device') {
                    const result = await registerReportUploadDeviceFromWebUi(payload);
                    const code = result.success === false ? 400 : 200;
                    res.writeHead(code, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify(result));
                }
                if (payload.action === 'check_for_updates') {
                    const result = await checkLatestReleaseFromAppsScript();
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify({ success:true, controllerVersion:CONTROLLER_VERSION, controllerRevision:CONTROLLER_RELEASE_REVISION, updateInstall:lastUpdateInstallState, ...result }));
                }
                if (payload.action === 'install_release') {
                    const result = await installLatestReleaseFromAppsScript();
                    res.writeHead(result.success === false ? 409 : 200, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify({ ...result, controllerVersion:CONTROLLER_VERSION, controllerRevision:CONTROLLER_RELEASE_REVISION, updateInstall:lastUpdateInstallState }));
                }
                if (payload.action === 'restart_controller') {
                    const restartSafety = controllerRestartSafetyState();
                    if (!restartSafety.safe) {
                        logWithTimestamp(
                            'CONTROLLER RESTART POSTPONED: ' + restartSafety.message,
                            'WARN',
                            'UPDATE',
                            { eventCode:'EVT-UPDATE-RESTART-DEFERRED', reason:restartSafety.error }
                        );
                        res.writeHead(409, { 'Content-Type': 'application/json' });
                        return res.end(JSON.stringify({
                            success:false,
                            ...restartSafety
                        }));
                    }
                    saveStats();
                    logWithTimestamp('CONTROLLER RESTART REQUESTED FROM TRACKER UI', 'INFO', 'UPDATE', { eventCode:'EVT-UPDATE-RESTART' });
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ success:true, status:'RESTARTING', message:'Controller restart initiated.' }));
                    setTimeout(() => process.exit(0), 750);
                    return;
                }
                if (payload.action === 'configure_report_settings') {
                    const result = configureReportSettings(payload);
                    const code = result.success === false ? 400 : 200;
                    res.writeHead(code, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify(result));
                }
                if ((payload.action === 'break' || payload.action === 'bio' || payload.action === 'hbio') && !shiftStarted) {
                    res.writeHead(409, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify({
                        success: false,
                        error: 'SHIFT_NOT_STARTED',
                        message: 'Click Start Shift before using Break, BIO, or HBIO.'
                    }));
                }
                if (payload.action === 'browser_hello') {
                    const browser = saveTrackerBrowserInfo(payload.browserInfo || payload);
                    res.writeHead(browser ? 200 : 400, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify({ success: Boolean(browser), browser, controllerVersion: CONTROLLER_VERSION, controllerRevision: CONTROLLER_RELEASE_REVISION }));
                }
                if (payload.action === 'tampermonkey_check_update') {
                    saveTrackerBrowserInfo(payload.browserInfo || null);
                    const installedDescriptor = payload.installedIdentity
                        || (payload.installedName && payload.installedNamespace
                            ? {
                                name: payload.installedName,
                                namespace: payload.installedNamespace,
                                version: payload.installedVersion,
                                revision: payload.installedRevision
                            }
                            : payload.installedVersion);
                    const result = checkTampermonkeyUpdate(installedDescriptor);
                    res.writeHead(result.success ? 200 : 404, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify(result));
                }
                if (payload.action === 'tampermonkey_stage_update') {
                    const installedDescriptor = payload.installedIdentity
                        || (payload.installedName && payload.installedNamespace
                            ? {
                                name: payload.installedName,
                                namespace: payload.installedNamespace,
                                version: payload.installedVersion,
                                revision: payload.installedRevision
                            }
                            : payload.installedVersion);
                    const result = stageTampermonkeyUpdate(payload.source, installedDescriptor);
                    res.writeHead(result.success ? 200 : 409, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify(result));
                }
                if (payload.action === 'break' || payload.action === 'lunch') {
                    const result = startBreak(payload.action === 'lunch' ? 'LUNCH' : 'BREAK');
                    const code = result.success === false ? 409 : 200;
                    res.writeHead(code, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify(result));
                }
                if (payload.action === 'bio' || payload.action === 'hbio') {
                    const result = startSpecialSession(payload.action.toUpperCase());
                    const code = result.success === false ? 409 : 200;
                    res.writeHead(code, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify(result));
                }
                if (payload.action === 'resume') {
                    const result = resumePauseSession();
                    const code = result.success === false ? 409 : 200;
                    res.writeHead(code, { 'Content-Type': 'application/json' });
                    return res.end(JSON.stringify(result));
                }
                if (payload.action === 'reset' || payload.action === 'reset_all') {
                    if (payload.action === 'reset_all' && payload.confirmResetAll !== true) {
                        res.writeHead(409, { 'Content-Type': 'application/json' });
                        return res.end(JSON.stringify({
                            success: false,
                            error: 'RESET_ALL_CONFIRMATION_REQUIRED',
                            message: 'Reset All requires an explicit confirmation from the tracker UI.'
                        }));
                    }
                    const resetResult = payload.action === 'reset'
                        ? resetInterval({ confirmEarly: payload.confirmEarly === true, source: 'browser' })
                        : (resetAllCounters(), { success: true, status: 'RESET_ALL', message: 'All tracker data reset.' });
                    res.writeHead(200, {
                        'Content-Type': 'application/json'
                    });
                    return res.end(JSON.stringify({
                        ...resetResult,
                        totalTaskCompleted,
                        totalJobsCompleted,
                        allTimeTasks,
                        currentInterval,
                        trackingMode,
                        shiftStarted,
                        shiftStartedAt,
                        intervalCounters: getIntervalCounters(),
                        manualIntervalReset: currentManualIntervalResetState()
                    }));
                }
                if (payload.action === 'report') {
                    const lastName = sanitizeLastName(payload.lastName || reportSettings.lastName);
                    if (!lastName) {
                        res.writeHead(400, { 'Content-Type': 'application/json' });
                        return res.end(JSON.stringify({ success: false, error: 'LAST_NAME_REQUIRED' }));
                    }
                    generateReport(null, { lastName }).then(result => {
                        res.writeHead(200, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify(result || { success: false, error: 'NO_ACTIVITY_TO_REPORT' }));
                    }).catch(err => {
                        lastReportStatus = { state: 'FAILED', generatedAt: Date.now(), reportFileName: null, drive: null, error: String(err.message || err) };
                        console.error(err);
                        res.writeHead(500, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify({ success: false, error: String(err.message || err) }));
                    });
                    return;
                }
                if (payload.action === 'coverage_empty_area') {
                    res.writeHead(409, {
                        'Content-Type': 'application/json'
                    });
                    return res.end(JSON.stringify({
                        success: false,
                        error: 'Update userscript: metrics are counted on Submit.'
                    }));
                }
                if (payload.action === 'click_submit' && trackingMode === 2) {
                    if (!validateCoverageSubmission(payload)) {
                        res.writeHead(400, {
                            'Content-Type': 'application/json'
                        });
                        return res.end(JSON.stringify({
                            success: false,
                            error: 'Missing or invalid coverage snapshot.'
                        }));
                    }
                    const key = JSON.stringify([payload.jobId, payload.submittedTaskPosition]);
                    if (coverageSubmittedTasks[key]) {
                        res.writeHead(200, {
                            'Content-Type': 'application/json'
                        });
                        return res.end(JSON.stringify({
                            success: true,
                            duplicate: true
                        }));
                    }
                    payload.isJobFinished = payload.submittedTaskPosition === payload.totalTasks;
                }
                if (payload.jobId && payload.jobId !== currentJobId) {
                    if (currentJobId !== "No Jobs Detected" && currentJobId !== "No Active Job Detected") {
                        previousJobId = currentJobId;
                        finalizeImplicitTrackedJob('PAYLOAD_JOB_ID_CHANGED', Date.now());
                    }
                    currentJobId = payload.jobId;
                    jobTaskCount = 0;
                    jobIdleSeconds = 0;
                    jobBreakSeconds = 0;
    jobBioSeconds = 0;
    jobHbioSeconds = 0;
                    jobTrackingMode = trackingMode;
                    jobStartTime = Date.now();
                    coverageLastPosition = 0;
                    coverageTaskCount = 0;
                    coverageLastEventKey = "";
                }
                if (payload.action === "coverage_skip") {
                    if (trackingMode !== 2) {
                        res.writeHead(409, { "Content-Type": "application/json" });
                        return res.end(JSON.stringify({
                            success: false,
                            error: "WRONG_TRACKING_MODE",
                            trackingMode
                        }));
                    }
                    const requestId = payload.requestId;
                    if (requestId) {
                        cleanupProcessedSubmitRequests();
                        if (processedSubmitRequests.has(requestId)) {
                            res.writeHead(200, { "Content-Type": "application/json" });
                            return res.end(JSON.stringify({
                                success: true,
                                duplicate: true,
                                status: "DUPLICATE_SKIP",
                                requestId
                            }));
                        }
                        processedSubmitRequests.set(requestId, Date.now());
                    }
                    if (!currentInterval) {
                        startNewInterval(currentIntervalNumber || 1);
                    }
                    if (!jobConfirmed) {
                        currentJobId = payload.jobId && payload.jobId !== "None" ? payload.jobId : currentJobId || "No Active Job Detected";
                        jobTrackingMode = 2;
                        jobConfirmed = true;
                        jobStartTime = Date.now();
                        logWithTimestamp("Started Job: " + currentJobId);
                    }
                    mode2TaskCompleted += 1;
                    mode2SkippedTask += 1;
                    jobTaskCount += 1;
                    if (isOvertimeAt(Date.now())) overtimeStats.tasks += 1;
                    if (payload.isJobFinished) {
                        mode2JobsCompleted += 1;
                        if (isOvertimeAt(Date.now())) overtimeStats.jobs += 1;
                    }
                    syncMode2Stats();
                    currentInterval.tasks = currentCoverageTotals().taskCompleted;
                    currentInterval.jobs = currentCoverageTotals().jobsCompleted;
                    allTimeTasks = currentInterval.tasks;
                    saveMode2Stats();
                    lastLogTimePH = logWithTimestamp(
                        `COVERAGE SKIP | Tasks: ${mode2TaskCompleted} | Skipped: ${mode2SkippedTask} | Job: ${currentJobId} | Finished: ${Boolean(payload.isJobFinished)}`
                    );
                    saveStats();
                    broadcastToBrowser('coverage_skip');
                    scheduleDashboard();
                    if (payload.isJobFinished) {
                        writeJobSummary();
                        jobConfirmed = false;
                        currentJobId = "No Active Job Detected";
                        jobTaskCount = 0;
                        jobIdleSeconds = 0;
                        jobBreakSeconds = 0;
    jobBioSeconds = 0;
    jobHbioSeconds = 0;
                        jobTrackingMode = trackingMode;
                        jobStartTime = Date.now();
                    }
                    res.writeHead(200, { "Content-Type": "application/json" });
                    return res.end(JSON.stringify({
                        success: true,
                        status: "SKIP_RECORDED",
                        allTimeTasks,
                        totalTaskCompleted,
                        totalJobsCompleted,
                        trackingMode,
                        modeTiming: getModeTimingSnapshot(),
                        intervalCounters: getIntervalCounters(),
                        mode2: {
                            taskCompleted: mode2TaskCompleted,
                            jobsCompleted: mode2JobsCompleted,
                            deletedBoxes: mode2DeletedBoxes,
                            emptyAreaConfirmation: mode2EmptyAreaConfirmation,
                            emptyAreaNoMatchFound: mode2EmptyAreaNoMatchFound,
                            unblurredPerson: mode2UnblurredPerson,
                            skippedTask: mode2SkippedTask
                        },
                        currentJobId: currentJobId === "No Active Job Detected" ? "None" : currentJobId,
                        agentStatus: lastStatusPH,
                        currentInterval: currentInterval ? {
                            number: currentInterval.number,
                            tasks: currentInterval.tasks,
                            jobs: currentInterval.jobs,
                            started: currentInterval.started,
                            ended: currentInterval.ended
                        } : null
                    }));
                }
                if (payload.action === "click_submit") {
                    const requestId = payload.requestId;
                    if (!requestId) {
                        console.warn("⚠️ CLICK_SUBMIT received without requestId");
                    } else {
                        cleanupProcessedSubmitRequests();
                        if (processedSubmitRequests.has(requestId)) {
                            console.warn("⏳ Duplicate submit request ignored:", requestId);
                            res.writeHead(200, {
                                'Content-Type': 'application/json'
                            });
                            return res.end(JSON.stringify({
                                success: true,
                                duplicate: true,
                                requestId: requestId,
                                message: "Duplicate submit ignored"
                            }));
                        }
                        processedSubmitRequests.set(requestId, Date.now());
                    }
                    console.log(`📥 CLICK_SUBMIT RECEIVED | Job: ${payload.jobId || "NONE"}`);
                    if (!jobConfirmed) {
                        currentJobId = pendingJobId || payload.jobId || currentJobId || "No Active Job Detected";
                        currentJobUrl = pendingJobUrl || payload.jobUrl || "";
                        currentJobDescription = pendingJobDescription || payload.jobDescription || "";
                        jobTrackingMode = trackingMode;
                        jobConfirmed = true;
                        logWithTimestamp("Started Job: " + currentJobId);
                    }
                    let acceptedTaskCount = 0;
                    if (trackingMode === 1) {
                        acceptedTaskCount = 1;
                        jobTaskCount += 1;
                    } else if (trackingMode === 2) {
                        acceptedTaskCount = 1;
                        applyCoverageSubmission(payload);
                        mode2TaskCompleted++;
                        syncMode2Stats();
                        saveMode2Stats();
                        jobTaskCount++;
                        console.log("📦 MODE 2 TASK ACCEPTED | Personal +1");
                        console.log("📊 Mode 2 Task Total:", mode2TaskCompleted);
                    }
                    if (!currentInterval) {
                        startNewInterval(currentIntervalNumber || 1);
                    }
                    if (acceptedTaskCount > 0) {
                        if (isOvertimeAt(Date.now())) overtimeStats.tasks += acceptedTaskCount;
                        if (trackingMode === 1) {
                            currentConfirmationTotals().taskCompleted += acceptedTaskCount;
                            currentInterval.tasks += acceptedTaskCount;
                            allTimeTasks = currentInterval.tasks;
                            totalTaskCompleted = intervalHistory.reduce((sum, interval) => sum + confirmationTotalsFor(interval).taskCompleted, 0) + currentConfirmationTotals().taskCompleted;
                        }
                        if (trackingMode === 2) {
                            currentInterval.tasks = currentCoverageTotals().taskCompleted;
                            allTimeTasks = currentInterval.tasks;
                        }
                    }
                    if (payload.isJobFinished) {
                        if (isOvertimeAt(Date.now())) overtimeStats.jobs += 1;
                        if (trackingMode === 1) {
                            totalJobsCompleted++;
                        } else if (trackingMode === 2) {
                            mode2JobsCompleted++;
                            currentInterval.jobs = currentCoverageTotals().jobsCompleted;
                            syncMode2Stats();
                            saveMode2Stats();
                        }
                    }
                    lastTotalTasksDone++;
                    lastLogTimePH = logWithTimestamp(`TASK ACCEPTED | ` + `Mode: ${trackingMode === 1 ? "CONFIRMATION" : "COVERAGE"} | ` + `Accepted: ${acceptedTaskCount} | ` + `Mode Total: ${trackingMode === 1 ? totalTaskCompleted : mode2TaskCompleted} | ` + (trackingMode === 1 ? `Interval ${currentInterval.number}: ${currentInterval.tasks} | ` : `Coverage Total: ${mode2TaskCompleted} | `) + `Job: ${currentJobId} | ` + `Finished: ${payload.isJobFinished}`);
                    saveStats();
                    scheduleDashboard();
                    if (payload.isJobFinished) {
                        writeJobSummary();
                        jobConfirmed = false;
                        currentJobId = "No Active Job Detected";
                        jobTaskCount = 0;
                        jobIdleSeconds = 0;
                        jobBreakSeconds = 0;
    jobBioSeconds = 0;
    jobHbioSeconds = 0;
                        jobTrackingMode = trackingMode;
                        jobStartTime = Date.now();
                        coverageLastPosition = 0;
                        coverageTaskCount = 0;
                        coverageLastEventKey = "";
                    }
                    res.writeHead(200, {
                        "Content-Type": "application/json"
                    });
                    return res.end(JSON.stringify({
                        status: "TASK_ACCEPTED",
                        allTimeTasks,
                        totalTaskCompleted,
                        totalJobsCompleted,
                        trackingMode,
                        modeTiming: getModeTimingSnapshot(),
                        intervalCounters: getIntervalCounters(),
                        mode2: {
                            taskCompleted: mode2TaskCompleted,
                            jobsCompleted: mode2JobsCompleted,
                            deletedBoxes: mode2DeletedBoxes,
                            emptyAreaConfirmation: mode2EmptyAreaConfirmation,
                            emptyAreaNoMatchFound: mode2EmptyAreaNoMatchFound,
                            unblurredPerson: mode2UnblurredPerson,
                            skippedTask: mode2SkippedTask
                        },
                        currentJobId: currentJobId === "No Active Job Detected" ? "None" : currentJobId,
                        agentStatus: lastStatusPH,
                        currentInterval: currentInterval ? {
                            number: currentInterval.number,
                            tasks: currentInterval.tasks,
                            jobs: currentInterval.jobs,
                            started: currentInterval.started,
                            ended: currentInterval.ended
                        } : null
                    }));
                }
                if (payload.action === "job_changed") {
                    finalizeImplicitTrackedJob('JOB_CHANGED_EVENT', Date.now());
                    pendingJobId = payload.newJobId;
                    pendingJobUrl = payload.newUrl;
                    pendingJobDescription = payload.newDescription;
                    jobConfirmed = false;
                    jobTaskCount = 0;
                    jobIdleSeconds = 0;
                    jobBreakSeconds = 0;
    jobBioSeconds = 0;
    jobHbioSeconds = 0;
                    jobTrackingMode = trackingMode;
                    jobStartTime = Date.now();
                    return res.end(JSON.stringify({
                        status: "WAITING_CONFIRMATION"
                    }));
                }
                if (payload.action === "idle_alert") {
                    if (!shiftStarted) {
                        res.writeHead(200, { "Content-Type": "application/json" });
                        return res.end(JSON.stringify({ status: "WAITING", shiftStarted: false }));
                    }
                    if (onBreak) {
                        return res.end(JSON.stringify({ status: "BREAK" }));
                    }
                    if (specialSessions.active) {
                        return res.end(JSON.stringify({ status: specialSessions.active.type, specialSessionState: getSpecialSessionState() }));
                    }
                    if (lastStatusPH !== "IDLE") {
                        const requestTime = Date.now();
                        const startedAt = normalizeClientTimingTimestamp(payload.idleStartedAt, requestTime);
                        switchTimingState(trackingMode, 'IDLE', startedAt);
                        lastStatusPH = "IDLE";
                        idleStartTime = startedAt;
                        idleStartDisplay = new Date(startedAt).toLocaleTimeString("en-US", {
                            timeZone: "Asia/Manila",
                            hour12: true
                        });
                        logWithTimestamp('IDLE STARTED: ' + idleStartDisplay);
                        lastLogTimePH = idleStartDisplay;
                        saveStats();
                        broadcastToBrowser('idle_started');
                        scheduleDashboard();
                    }
                    res.writeHead(200, { "Content-Type": "application/json" });
                    return res.end(JSON.stringify({ status: "IDLE" }));
                } else if (payload.action === "active_alert") {
                    if (!shiftStarted) {
                        res.writeHead(200, { "Content-Type": "application/json" });
                        return res.end(JSON.stringify({ status: "WAITING", shiftStarted: false }));
                    }
                    logWithTimestamp("ACTIVE ALERT RECEIVED");
                    if (onBreak) {
                        return res.end(JSON.stringify({ status: "BREAK" }));
                    }
                    if (specialSessions.active) {
                        return res.end(JSON.stringify({ status: specialSessions.active.type, specialSessionState: getSpecialSessionState() }));
                    }
                    if (lastStatusPH === "IDLE") {
                        const requestTime = Date.now();
                        const endedAt = normalizeClientTimingTimestamp(payload.activityAt, requestTime);
                        finishIdleSession(endedAt);
                        switchTimingState(trackingMode, 'ACTIVE', endedAt);
                        lastStatusPH = "ACTIVE";
                        lastLogTimePH = new Date(endedAt).toLocaleTimeString("en-US", {
                            timeZone: "Asia/Manila",
                            hour12: true
                        });
                        saveStats();
                        broadcastToBrowser('active_started');
                        scheduleDashboard();
                    }
                    res.writeHead(200, { "Content-Type": "application/json" });
                    return res.end(JSON.stringify({ status: "ACTIVE" }));
                }
                if (payload.action === "window_blur") {
                    res.writeHead(200, {
                        "Content-Type": "application/json"
                    });
                    return res.end(JSON.stringify({
                        status: "WINDOW_BLUR"
                    }));
                }
                if (payload.action === "window_focus") {
                    res.writeHead(200, {
                        "Content-Type": "application/json"
                    });
                    return res.end(JSON.stringify({
                        status: "WINDOW_FOCUS"
                    }));
                }
                if (payload.action === "tab_hidden") {
                    res.writeHead(200, {
                        "Content-Type": "application/json"
                    });
                    return res.end(JSON.stringify({
                        status: "TAB_HIDDEN"
                    }));
                }
                if (payload.action === "tab_visible") {
                    res.writeHead(200, {
                        "Content-Type": "application/json"
                    });
                    return res.end(JSON.stringify({
                        status: "TAB_VISIBLE"
                    }));
                }
                res.writeHead(400, {
                    "Content-Type": "application/json"
                });
                res.end(JSON.stringify({
                    error: "Unknown action"
                }));
            } catch (err) {
                console.error(err);
                const record = writeControllerErrorLog('API', err, {
                    component: 'API',
                    errorCode: err instanceof SyntaxError ? 'ERR-API-INVALID-JSON' : 'ERR-API-REQUEST-HANDLER',
                    severity: 'ERROR',
                    traceId: requestTraceId,
                    method: req.method,
                    endpoint: String(req.url || '').slice(0, 500),
                    bodyBytes: Buffer.byteLength(body || '', 'utf8')
                });
                logWithTimestamp(
                    'Request processing failed: ' + redactSensitiveLogText(err?.message || 'Unknown request error', 1000),
                    'ERROR',
                    'API',
                    { eventCode: 'EVT-API-REQUEST-FAILED', traceId: record?.traceId || requestTraceId }
                );
                res.writeHead(400, {
                    "Content-Type": "application/json"
                });
                res.end(JSON.stringify({
                    success: false,
                    error: err instanceof SyntaxError ? 'INVALID_JSON' : 'REQUEST_PROCESSING_FAILED',
                    message: 'The controller could not process this request. Use the trace ID when reporting the issue.',
                    traceId: record?.traceId || requestTraceId
                }));
            }
        });
    }
});

server.on('error', error => {
    const code = String(error?.code || '');
    const message = code === 'EADDRINUSE'
        ? 'Local port 9000 is already in use. Close the older Auto Tracker controller and start again.'
        : code === 'EACCES'
            ? 'Auto Tracker cannot bind to local port 9000 because Windows/macOS/Linux denied access.'
            : String(error?.message || error || 'Unknown local server error.');
    console.error('[STARTUP] ' + message);
    try {
        writeControllerErrorLog('STARTUP', error, {
            component: 'CTRL',
            errorCode: code === 'EADDRINUSE' ? 'ERR-CTRL-PORT-IN-USE' : 'ERR-CTRL-SERVER-LISTEN',
            severity: 'ERROR',
            port: 9000,
            bindAddress: '127.0.0.1'
        });
    } catch {}
    process.exitCode = 1;
    setTimeout(() => process.exit(1), 100);
});

// =========================================
// FUNCTION START TRACKER
// Search: startTracker
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.6 Alpha || 2026-09-07 || JBallados
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function parseTrackerDateFromName(name) {
    const match = String(name || '').match(/(\d{4}-\d{2}-\d{2})/);
    if (!match) return null;
    const value = Date.parse(match[1] + 'T00:00:00+08:00');
    return Number.isFinite(value) ? value : null;
}

function cleanupLocalTrackerFiles(now = Date.now()) {
    const cutoff = now - LOCAL_RETENTION_DAYS * 24 * 60 * 60 * 1000;
    const scan = (folder, kind) => {
        if (!fs.existsSync(folder)) return;
        for (const name of fs.readdirSync(folder)) {
            const fullPath = path.join(folder, name);
            let stat;
            try { stat = fs.statSync(fullPath); } catch { continue; }
            if (!stat.isFile()) continue;
            const dated = parseTrackerDateFromName(name);
            if (!dated || dated >= cutoff) continue;
            if (kind === 'reports' && !/(\.xlsx|\.txt|\.snapshot\.json|\.integrity\.json)$/i.test(name)) continue;
            if (kind === 'logs' && !/^(errors_)?\d{4}-\d{2}-\d{2}\.txt$/i.test(name)) continue;
            if (kind === 'reports' && !reportBundleVerifiedForRetention(name)) {
                continue;
            }
            try {
                fs.chmodSync(fullPath, 0o644);
                fs.unlinkSync(fullPath);
            } catch (error) {
                writeControllerErrorLog('RETENTION', error, { component: 'CTRL', errorCode: 'ERR-CTRL-RETENTION', severity: 'WARN', file: name });
            }
        }
    };
    scan(reportsFolder, 'reports');
    scan(logsFolder, 'logs');
}

function startTracker() {

    server.listen(9000, '127.0.0.1', async () => {
        cleanupLocalTrackerFiles();
        if (fs.existsSync(installTampermonkeyMarker)) {
            let markerMode = 'install';
            try {
                markerMode = String(fs.readFileSync(installTampermonkeyMarker, 'utf8') || '').trim().toLowerCase() || 'install';
            } catch {}
            try {
                fs.unlinkSync(installTampermonkeyMarker);
            } catch {}
            if (markerMode === 'install' || markerMode === 'pending' || markerMode === 'update') {
                setTimeout(() => openTampermonkeyUpdater('current'), 1000);
            } else if (markerMode === 'legacy-v008') {
                setTimeout(() => openTampermonkeyUpdater('legacy-v008'), 1000);
            }
        }
        const modeSelected = await selectTrackerMode();
        if (!modeSelected) return;
        loadStats();
        loadMode2Stats();
        restoreSpecialSessionAfterLoad();
        ensureCurrentShiftInterval();
        retryPendingUploads().catch(error => writeControllerErrorLog('UPLOAD', error, { component: 'UPLOAD', errorCode: 'ERR-UPLOAD-STARTUP-RETRY', severity: 'WARN' }));
        checkLatestReleaseFromAppsScript().catch(() => {});
        timingSegmentStartedAt = Date.now();
        timingSegmentMode = trackingMode;
        timingSegmentStatus = lastStatusPH;
        syncLegacyTiming();
        setInterval(() => {
            ensureCoverageDate();
            ensureCurrentShiftInterval();
        }, 1000);
        setInterval(() => retryPendingUploads().catch(() => {}), 15 * 60 * 1000);
        setInterval(() => checkLatestReleaseFromAppsScript().catch(() => {}), 6 * 60 * 60 * 1000);
        trackerStartupComplete = true;
        drawDashboard();
    });

}
startTracker();

// =========================================
// FUNCTION END SHIFT TRACKING
// Search: endShiftTracking
// Ver 0.1.18 Alpha || 2026-09-29 || JBallados || End_Shift
// =========================================
async function endShiftTracking(options = {}) {

    if (!shiftStarted || !shiftStartedAt) {
        return { success: false, error: 'SHIFT_NOT_STARTED', message: 'There is no active shift to end.' };
    }
    const now = Date.now();
    if (specialSessions.active) endSpecialSession({ expired: false });
    if (onBreak) endBreak({ expired: false });
    if (lastStatusPH === 'IDLE' && idleStartTime) finishIdleSession(now);

    // Do not leave the agent's final job outside Jobs/Job Details merely because
    // the site did not emit a separate job_changed event before End Shift.
    finalizeImplicitTrackedJob('END_SHIFT', now);
    previousJobId = currentJobId || previousJobId;
    currentJobId = 'No Active Job Detected';
    currentJobUrl = '';
    currentJobDescription = '';
    pendingJobId = '';
    pendingJobUrl = '';
    pendingJobDescription = '';
    jobConfirmed = false;
    jobTaskCount = 0;
    jobIdleSeconds = 0;
    jobBreakSeconds = 0;
    jobBioSeconds = 0;
    jobHbioSeconds = 0;
    jobTrackingMode = trackingMode;
    jobStartTime = now;

    settleModeTiming(now);
    shiftEndedAt = now;
    earlyManualIntervalAdvance = null;
    const schedule = getShiftSchedule();
    const overtime = overtimeTimingSnapshot(now);
    shiftStarted = false;
    lastStatusPH = 'WAITING';
    timingSegmentStartedAt = now;
    saveStats();
    logWithTimestamp('SHIFT ENDED | Started: ' + getPHTime(shiftStartedAt) + ' | Ended: ' + getPHTime(now)
        + ' | OT: ' + formatDuration(overtime.activeSeconds + overtime.idleSeconds + overtime.breakSeconds + overtime.bioSeconds + overtime.hbioSeconds));

    appendEndShiftLogSummary(null, overtime);

    let report = null;
    if (options.generateReport !== false && reportSettings.lastName) {
        try {
            report = await generateReport(null, { lastName: reportSettings.lastName, reportDate: shiftReportDate });
        } catch (error) {
            writeControllerErrorLog('REPORT', error, { component: 'REPORT', errorCode: 'ERR-REPORT-ENDSHIFT', severity: 'ERROR' });
        }
    }
    broadcastToBrowser('shift_ended', {
        message: 'Shift ended.',
        shiftEndedAt,
        shiftSchedule: schedule,
        overtime,
        report
    });
    scheduleDashboard();
    return { success: true, shiftStarted: false, shiftStartedAt, shiftEndedAt, shiftReportDate, shiftSchedule: schedule, overtime, report };

}

// =========================================
// FUNCTION START BREAK
// Search: startBreak
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function startBreak(requestedKind = 'AUTO') {

    const requested = String(requestedKind || 'AUTO').trim().toUpperCase();
    const before = getBreakState(Date.now(), requested);
    if (requested === 'LUNCH' && before.supported === false) {
        return {
            success: false,
            error: 'LUNCH_NOT_AVAILABLE',
            message: 'Lunch Break is not available for this department/shift policy.',
            status: lastStatusPH,
            breakState: before
        };
    }
    if (requested === 'BREAK' && before.supported === false) {
        return {
            success: false,
            error: 'BREAK_NOT_AVAILABLE',
            message: 'The 30-minute Break is not available for this department/shift policy.',
            status: lastStatusPH,
            breakState: before
        };
    }

    if (specialSessions.active) {
        return {
            success: false,
            error: 'SPECIAL_SESSION_ACTIVE',
            message: 'Resume the active BIO/HBIO session before starting Break or Lunch.',
            status: lastStatusPH,
            specialSessionState: getSpecialSessionState(),
            breakState: before
        };
    }
    if (onBreak) {
        return {
            success: true,
            status: 'BREAK',
            agentStatus: lastStatusPH,
            trackingMode,
            breakState: getBreakState(Date.now(), currentBreakKind() || before.kind),
            pauseStates: getPauseStates(),
            modeTiming: getModeTimingSnapshot(),
            intervalCounters: getIntervalCounters()
        };
    }

    if (before.remainingSeconds <= 0) {
        return {
            success: false,
            error: 'BREAK_ALLOWANCE_FINISHED',
            message: 'The ' + before.allowanceMinutes + '-minute ' + before.label.toLowerCase() + ' allowance has already been used.',
            status: lastStatusPH,
            agentStatus: lastStatusPH,
            trackingMode,
            breakState: before,
            pauseStates: getPauseStates(),
            modeTiming: getModeTimingSnapshot(),
            intervalCounters: getIntervalCounters()
        };
    }

    const startedAt = Date.now();
    if (lastStatusPH === 'IDLE' && idleStartTime) {
        finishIdleSession(startedAt);
    }
    switchTimingState(trackingMode, 'BREAK', startedAt);
    onBreak = true;
    breakStart = startedAt;
    idleStartTime = null;
    idleStartDisplay = new Date(startedAt).toLocaleTimeString('en-US', {
        timeZone: 'Asia/Manila',
        hour12: true
    });
    lastStatusPH = 'BREAK';
    logWithTimestamp(before.label.toUpperCase() + ' STARTED');
    breakSessions.push({
        mode: trackingMode,
        kind: before.kind,
        label: before.label,
        allowanceMinutes: before.allowanceMinutes,
        started: startedAt,
        startedDisplay: idleStartDisplay,
        ended: null,
        duration: null
    });
    saveStats();
    broadcastToBrowser('break_started', { kind: before.kind, label: before.label });
    scheduleDashboard();

    if (breakTimer !== null) clearTimeout(breakTimer);
    breakTimer = setTimeout(() => {
        endBreak({ expired: true });
    }, before.remainingSeconds * 1000);

    return {
        success: true,
        status: 'BREAK',
        agentStatus: lastStatusPH,
        trackingMode,
        breakState: getBreakState(Date.now(), before.kind),
        pauseStates: getPauseStates(),
        modeTiming: getModeTimingSnapshot(),
        intervalCounters: getIntervalCounters(),
        currentInterval
    };

}

function endBreak(options = {}) {

    if (!onBreak || !breakStart) {
        return {
            success: false,
            error: 'NOT_ON_BREAK',
            message: 'There is no active Break/Lunch session to resume from.',
            status: lastStatusPH,
            agentStatus: lastStatusPH,
            trackingMode,
            breakState: getBreakState(),
            pauseStates: getPauseStates(),
            modeTiming: getModeTimingSnapshot(),
            intervalCounters: getIntervalCounters()
        };
    }

    if (breakTimer !== null) clearTimeout(breakTimer);
    breakTimer = null;

    const observedEndedAt = Date.now();
    const activeKind = currentBreakKind() || 'BREAK';
    const pauseLabel = getShiftBreakLabel(shiftStartedAt, activeKind);
    const pauseMinutes = getShiftBreakMinutes(shiftStartedAt, activeKind);
    const totalAllowanceSeconds = Math.max(0, Number(pauseMinutes || 0) * 60);
    let previouslyUsedSeconds = 0;
    for (const session of breakSessions) {
        if (session && session.ended && pauseSessionKind(session) === activeKind) previouslyUsedSeconds += Math.max(0, Number(session.duration || 0));
    }
    previouslyUsedSeconds = Math.min(totalAllowanceSeconds, previouslyUsedSeconds);
    const allowedThisSession = Math.max(0, totalAllowanceSeconds - previouslyUsedSeconds);
    const rawSeconds = Math.max(0, Math.floor((observedEndedAt - breakStart) / 1000));
    const hitBreakLimit = Boolean(options.expired) || allowedThisSession <= 0 || rawSeconds >= allowedThisSession;
    const seconds = hitBreakLimit ? allowedThisSession : Math.min(rawSeconds, allowedThisSession);
    const effectiveEndedAt = hitBreakLimit
        ? Math.min(observedEndedAt, breakStart + allowedThisSession * 1000)
        : observedEndedAt;

    if (jobConfirmed) {
        jobBreakSeconds += seconds;
    }
    for (let i = breakSessions.length - 1; i >= 0; i--) {
        if (!breakSessions[i].ended) {
            breakSessions[i].ended = effectiveEndedAt;
            breakSessions[i].endedDisplay = new Date(effectiveEndedAt).toLocaleTimeString('en-US', {
                timeZone: 'Asia/Manila',
                hour12: true
            });
            breakSessions[i].duration = seconds;
            break;
        }
    }

    onBreak = false;
    breakStart = null;
    const stateAfter = getBreakState(observedEndedAt, activeKind);
    const expired = hitBreakLimit || stateAfter.remainingSeconds <= 0;

    if (expired) {
        switchTimingState(trackingMode, 'IDLE', effectiveEndedAt);
        lastStatusPH = 'IDLE';
        idleStartTime = effectiveEndedAt;
        idleStartDisplay = new Date(effectiveEndedAt).toLocaleTimeString('en-US', {
            timeZone: 'Asia/Manila',
            hour12: true
        });
        idleReason = pauseLabel + ' finished';
        logWithTimestamp(pauseLabel.toUpperCase() + ' FINISHED: ' + pauseMinutes + '-minute allowance used. Any time after the allowance is tracked as IDLE until agent activity resumes.');
    } else {
        switchTimingState(trackingMode, 'ACTIVE', observedEndedAt);
        lastStatusPH = 'ACTIVE';
        idleStartTime = null;
        idleStartDisplay = '';
        idleReason = 'Unknown';
        logWithTimestamp(pauseLabel.toUpperCase() + ' ENDED (' + formatDuration(seconds) + ')');
    }

    saveStats();
    const message = expired
        ? pauseMinutes + '-minute ' + pauseLabel.toLowerCase() + ' is finished. Extra time is now IDLE and will switch to ACTIVE when agent activity is detected.'
        : pauseLabel + ' ended. Status is now ACTIVE.';
    broadcastToBrowser(expired ? 'break_expired' : 'break_ended', { message, kind: activeKind, label: pauseLabel });
    scheduleDashboard();

    return {
        success: true,
        status: lastStatusPH,
        agentStatus: lastStatusPH,
        message,
        trackingMode,
        breakState: getBreakState(Date.now(), activeKind),
        pauseStates: getPauseStates(),
        modeTiming: getModeTimingSnapshot(),
        intervalCounters: getIntervalCounters(),
        currentInterval
    };

}

function finalizeImplicitTrackedJob(reason = 'JOB_CHANGE', finishedAt = Date.now()) {

    if (!jobConfirmed || Number(jobTaskCount || 0) <= 0) return false;

    const implicitMode = Number(jobTrackingMode) === 2 ? 2 : Number(jobTrackingMode) === 1 ? 1 : trackingMode;
    if (isOvertimeAt(finishedAt)) overtimeStats.jobs += 1;

    if (implicitMode === 1) {
        totalJobsCompleted += 1;
    } else if (implicitMode === 2) {
        mode2JobsCompleted += 1;
        if (currentInterval) currentInterval.jobs = currentCoverageTotals().jobsCompleted;
        syncMode2Stats();
        saveMode2Stats();
    }

    logWithTimestamp(
        'IMPLICIT JOB COMPLETION COUNTED | Reason: ' + String(reason || 'JOB_CHANGE')
        + ' | Mode: ' + (implicitMode === 2 ? 'COVERAGE' : 'CONFIRMATION')
        + ' | Job: ' + currentJobId,
        'INFO',
        'JOB',
        { eventCode:'EVT-JOB-IMPLICIT-COMPLETION', reason:String(reason || 'JOB_CHANGE'), mode:implicitMode }
    );
    writeJobSummary(finishedAt);
    return true;

}

// =========================================
// FUNCTION WRITE JOB SUMMARY
// Search: writeJobSummary
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function writeJobSummary(jobEndTime = Date.now()) {

    if (!currentJobId || currentJobId === 'No Active Job Detected') return;
    jobEndTime = Number(jobEndTime || Date.now());
    const durationSeconds = Math.max(0, Math.floor((jobEndTime - jobStartTime) / 1000));
    const activeSeconds = Math.max(0, durationSeconds - jobIdleSeconds - jobBreakSeconds - jobBioSeconds - jobHbioSeconds);
    if (jobTaskCount === 0 && durationSeconds < 10) return;
    const jobMode = Number(jobTrackingMode) === 2 ? 2 : Number(jobTrackingMode) === 1 ? 1 : null;
    lastJobFinished = new Date(jobEndTime).toLocaleTimeString('en-US', {
        timeZone: 'Asia/Manila',
        hour12: true
    });
    const jobRecord = {
        jobId: currentJobId,
        mode: jobMode,
        tasks: jobTaskCount,
        duration: durationSeconds,
        idle: jobIdleSeconds,
        break: jobBreakSeconds,
        bio: jobBioSeconds,
        hbio: jobHbioSeconds,
        active: activeSeconds,
        started: jobStartTime,
        finished: jobEndTime
    };
    completedJobs.push(jobRecord);
    addJobToCurrentInterval(jobRecord);
    const intervalKey = getIntervalKey(currentIntervalNumber);
    if (intervalStats[intervalKey]) {
        intervalStats[intervalKey].jobs.push(jobRecord);
        intervalStats[intervalKey].tasks += jobTaskCount;
        intervalStats[intervalKey].idle += jobIdleSeconds;
        intervalStats[intervalKey].active += activeSeconds;
    }
    console.log('Completed Jobs:', completedJobs.length);
    logWithTimestamp('Completed Jobs: ' + completedJobs.length);
    saveStats();
    const efficiency = calculateEfficiency(activeSeconds, jobIdleSeconds);
    const summary = `
	==================================================
	JOB SUMMARY
	==================================================

	Job ID        : ${currentJobId}
	Mode          : ${jobMode === 2 ? 'COVERAGE' : jobMode === 1 ? 'CONFIRMATION' : 'UNKNOWN'}
	Started       : ${new Date(jobStartTime).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true })}
	Finished      : ${new Date(jobEndTime).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true })}
	Duration      : ${formatDuration(durationSeconds)}
	Tasks         : ${jobTaskCount}
	Idle Time     : ${formatDuration(jobIdleSeconds)}
	Break Time    : ${formatDuration(jobBreakSeconds)}
	Active Time   : ${formatDuration(activeSeconds)}
	Efficiency    : ${efficiency === null ? 'N/A' : efficiency + '%'}

	==================================================

	`;
    fs.appendFileSync(getTodayLogFile(), summary);

}

// =========================================
// FUNCTION FORMAT HOUR
// Search: formatHour
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function formatHour(hour, minute = 0) {

    const h = hour % 12 === 0 ? 12 : hour % 12;
    const mm = String(minute).padStart(2, '0');
    const suffix = hour >= 12 ? 'PM' : 'AM';
    return `${h}:${mm} ${suffix}`;

}

function reportIntervalSnapshotTotals(snapshot, liveCurrent = false) {

    if (!snapshot) return null;
    const confirmation = snapshot.confirmation || confirmationTotalsFor(snapshot) || {};
    const coverage = snapshot.coverage || (liveCurrent ? currentCoverageTotals() : {}) || {};
    const confirmationTasks = Math.max(0, Number(confirmation.taskCompleted || 0));
    const confirmationJobs = Math.max(0, Number(confirmation.jobsCompleted || 0));
    const coverageTasks = Math.max(0, Number(coverage.taskCompleted || 0));
    const coverageJobs = Math.max(0, Number(coverage.jobsCompleted || 0));
    const splitTasks = confirmationTasks + coverageTasks;
    const splitJobs = confirmationJobs + coverageJobs;
    return {
        tasks: splitTasks || Math.max(0, Number(snapshot.tasks || 0)),
        jobs: splitJobs || Math.max(0, Number(snapshot.jobs || 0)),
        confirmationTasks,
        confirmationJobs,
        coverageTasks,
        coverageJobs
    };

}

function buildReportIntervalGroups(jobs, overrideStats = null, shiftAnchor = shiftStartedAt) {

    const groups = {
        interval1: { jobs: [], taskTotal: null, jobTotal: null, confirmationTasks: 0, confirmationJobs: 0, coverageTasks: 0, coverageJobs: 0 },
        interval2: { jobs: [], taskTotal: null, jobTotal: null, confirmationTasks: 0, confirmationJobs: 0, coverageTasks: 0, coverageJobs: 0 },
        interval3: { jobs: [], taskTotal: null, jobTotal: null, confirmationTasks: 0, confirmationJobs: 0, coverageTasks: 0, coverageJobs: 0 },
        overtime: { jobs: [], tasks: 0, idle: 0, active: 0 }
    };

    for (const job of Array.isArray(jobs) ? jobs : []) {
        const startedKey = getIntervalForTimestamp(job.started, shiftAnchor);
        const finishedKey = getIntervalForTimestamp(job.finished || job.started, shiftAnchor);
        const key = finishedKey === 'overtime' ? 'overtime' : (startedKey || finishedKey);
        if (!key || !groups[key]) continue;
        groups[key].jobs.push(job);
        if (key === 'overtime') {
            groups[key].tasks += Math.max(0, Number(job.tasks || 0));
            groups[key].idle += Math.max(0, Number(job.idle || 0));
            groups[key].active += Math.max(0, Number(job.active || 0));
        }
    }

    const snapshots = [];
    const history = overrideStats
        ? (Array.isArray(overrideStats.intervalHistory) ? overrideStats.intervalHistory : [])
        : (Array.isArray(intervalHistory) ? intervalHistory : []);
    snapshots.push(...history);
    const currentSnapshot = overrideStats ? overrideStats.currentInterval : currentInterval;
    if (currentSnapshot) snapshots.push(currentSnapshot);

    for (const snapshot of snapshots) {
        const number = Number(snapshot?.number || 0);
        if (number < 1 || number > 3) continue;
        const key = 'interval' + number;
        const totals = reportIntervalSnapshotTotals(
            snapshot,
            !overrideStats && snapshot === currentInterval
        );
        if (!totals) continue;
        groups[key].taskTotal = Math.max(0, Number(groups[key].taskTotal || 0)) + totals.tasks;
        groups[key].jobTotal = Math.max(0, Number(groups[key].jobTotal || 0)) + totals.jobs;
        groups[key].confirmationTasks += totals.confirmationTasks;
        groups[key].confirmationJobs += totals.confirmationJobs;
        groups[key].coverageTasks += totals.coverageTasks;
        groups[key].coverageJobs += totals.coverageJobs;
    }

    return groups;

}

// =========================================
// FUNCTION POPULATE INTERVAL SHEET
// Search: populateIntervalSheet
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function populateIntervalSheet(sheet, interval, intervalConfig, reportDate, intervalName, schedule = null) {

    sheet.addRow(['Report Date', reportDate]);
    const intervalNumber = Number((String(intervalName).match(/\d+/) || [0])[0]);
    const scheduleInterval = schedule && intervalNumber ? schedule['interval' + intervalNumber] : null;
    const startLabel = scheduleInterval?.startedAt
        ? new Date(scheduleInterval.startedAt).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true })
        : '+' + Number(intervalConfig.startOffsetMinutes || 0) + 'm';
    const endLabel = scheduleInterval?.endedAt
        ? new Date(scheduleInterval.endedAt).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true })
        : '+' + Number(intervalConfig.endOffsetMinutes || 0) + 'm';
    sheet.addRow(['Interval', `${intervalName} (${startLabel} - ${endLabel})`]);
    const pauseLabel = schedule?.breakLabel || getShiftBreakLabel();
    const pauseMinutes = Number(schedule?.breakMinutes ?? getShiftBreakMinutes());
    sheet.addRow([pauseLabel + ' Allowance', pauseMinutes + ' mins']);
    const jobDerivedTasks = interval.jobs.reduce((sum, job) => sum + Math.max(0, Number(job.tasks || 0)), 0);
    const intervalTaskTotal = Number.isFinite(Number(interval.taskTotal)) ? Math.max(0, Number(interval.taskTotal)) : jobDerivedTasks;
    const intervalJobTotal = Number.isFinite(Number(interval.jobTotal)) ? Math.max(0, Number(interval.jobTotal)) : interval.jobs.length;
    sheet.addRow(['Interval Tasks', intervalTaskTotal]);
    sheet.addRow(['Interval Jobs', intervalJobTotal]);
    sheet.addRow(['Confirmation', (interval.confirmationTasks || 0) + ' tasks / ' + (interval.confirmationJobs || 0) + ' jobs']);
    sheet.addRow(['Coverage', (interval.coverageTasks || 0) + ' tasks / ' + (interval.coverageJobs || 0) + ' jobs']);
    sheet.addRow(['Note', 'Task/job totals use the saved interval counters. Time below summarizes completed job records assigned to this interval.']);
    sheet.addRow([]);
    sheet.addRow(['Mode', 'Job ID', 'Tasks', 'Started', 'Finished', 'Idle', 'Break', 'BIO', 'HBIO', 'Active', 'Duration', 'Efficiency']);
    sheet.getRow(sheet.lastRow.number).font = { bold: true };
    interval.jobs.forEach(job => {
        const started = job.started ? new Date(job.started).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : '';
        const finished = job.finished ? new Date(job.finished).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : '';
        const eff = calculateEfficiency(job.active, job.idle);
        const modeLabel = Number(job.mode) === 1 ? 'Confirmation' : Number(job.mode) === 2 ? 'Coverage' : 'Unknown';
        const row = sheet.addRow([modeLabel, job.jobId, job.tasks, started, finished, excelDuration(job.idle || 0), excelDuration(job.break || 0), excelDuration(job.bio || 0), excelDuration(job.hbio || 0), excelDuration(job.active || 0), excelDuration(job.duration || 0), eff === null ? 'N/A' : eff / 100]);
        for (const col of [6,7,8,9,10,11]) row.getCell(col).numFmt = '[h]:mm:ss';
        if (eff !== null) row.getCell(12).numFmt = '0.00%';
        applyIdleCellFill(row.getCell(6), job.idle || 0);
    });
    const totals = interval.jobs.reduce((acc, job) => {
        acc.tasks += job.tasks || 0;
        acc.idle += job.idle || 0;
        acc.break += job.break || 0;
        acc.bio += job.bio || 0;
        acc.hbio += job.hbio || 0;
        acc.active += job.active || 0;
        acc.duration += job.duration || 0;
        return acc;
    }, { tasks: 0, idle: 0, break: 0, bio: 0, hbio: 0, active: 0, duration: 0 });
    sheet.addRow([]);
    const totalEff = calculateEfficiency(totals.active, totals.idle);
    const reportedTaskTotal = Number.isFinite(Number(interval.taskTotal)) ? Math.max(0, Number(interval.taskTotal)) : totals.tasks;
    const totalRow = sheet.addRow(['Totals', '', reportedTaskTotal, '', '', excelDuration(totals.idle), excelDuration(totals.break), excelDuration(totals.bio), excelDuration(totals.hbio), excelDuration(totals.active), excelDuration(totals.duration), totalEff === null ? 'N/A' : totalEff / 100]);
    totalRow.font = { bold: true };
    for (const col of [6,7,8,9,10,11]) totalRow.getCell(col).numFmt = '[h]:mm:ss';
    if (totalEff !== null) totalRow.getCell(12).numFmt = '0.00%';
    applyIdleCellFill(totalRow.getCell(6), totals.idle);

}

// =========================================
// FUNCTION POPULATE MODE SHEET
// Search: populateModeSheet
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// =========================================
function populateModeSheet(sheet, title, jobs, metrics, reportDate, coverageMetrics = null) {

    sheet.addRow([title]);
    sheet.getRow(1).font = { bold: true, size: 16 };
    sheet.addRow(['Report Date', reportDate]);
    sheet.addRow(['Tasks Completed', metrics.tasks]);
    sheet.addRow(['Jobs Completed', metrics.jobs]);
    const activeRow = sheet.addRow(['Active Time', excelDuration(metrics.active)]);
    const idleRow = sheet.addRow(['Idle Time', excelDuration(metrics.idle)]);
    const breakRow = sheet.addRow(['Break Time', excelDuration(metrics.break)]);
    const bioRow = sheet.addRow(['BIO Time', excelDuration(metrics.bio || 0)]);
    const hbioRow = sheet.addRow(['HBIO Time', excelDuration(metrics.hbio || 0)]);
    for (const row of [activeRow,idleRow,breakRow,bioRow,hbioRow]) row.getCell(2).numFmt = '[h]:mm:ss';
    applyIdleCellFill(idleRow.getCell(2), metrics.idle);
    const efficiency = calculateEfficiency(metrics.active, metrics.idle);
    const productivity = calculateProductivity(metrics.tasks, metrics.active);
    const effRow = sheet.addRow(['Efficiency', efficiency === null ? 'N/A' : efficiency / 100]);
    if (efficiency !== null) effRow.getCell(2).numFmt = '0.00%';
    sheet.addRow(['Tasks / Active Hour', productivity === null ? 'N/A' : productivity]);
    sheet.addRow(['Productivity Note', 'Rate requires at least ' + Math.ceil(PRODUCTIVITY_MIN_ACTIVE_SECONDS / 60) + ' minutes of Active time.']);
    if (coverageMetrics) {
        sheet.addRow([]);
        sheet.addRow(['Coverage Actions']);
        sheet.getRow(sheet.lastRow.number).font = { bold: true };
        sheet.addRow(['Deleted Boxes', coverageMetrics.deletedBoxes || 0]);
        sheet.addRow(['Empty Area - Confirmation', coverageMetrics.emptyAreaConfirmation || 0]);
        sheet.addRow(['Empty Area - No Match Found', coverageMetrics.emptyAreaNoMatchFound || 0]);
        sheet.addRow(['Unblurred Person', coverageMetrics.unblurredPerson || 0]);
        sheet.addRow(['Skipped Task', coverageMetrics.skippedTask || 0]);
    }
    sheet.addRow([]);
    sheet.addRow(['Job ID', 'Tasks', 'Started', 'Finished', 'Idle', 'Break', 'BIO', 'HBIO', 'Active', 'Duration', 'Efficiency']);
    sheet.getRow(sheet.lastRow.number).font = { bold: true };
    jobs.forEach(job => {
        const efficiencyValue = calculateEfficiency(job.active, job.idle);
        const row = sheet.addRow([
            job.jobId,
            job.tasks || 0,
            job.started ? new Date(job.started).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : '',
            job.finished ? new Date(job.finished).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : '',
            excelDuration(job.idle || 0),
            excelDuration(job.break || 0),
            excelDuration(job.bio || 0),
            excelDuration(job.hbio || 0),
            excelDuration(job.active || 0),
            excelDuration(job.duration || 0),
            efficiencyValue === null ? 'N/A' : efficiencyValue / 100
        ]);
        for (const col of [5,6,7,8,9,10]) row.getCell(col).numFmt = '[h]:mm:ss';
        if (efficiencyValue !== null) row.getCell(11).numFmt = '0.00%';
        applyIdleCellFill(row.getCell(5), job.idle || 0);
    });

}

// Ver 0.1.18 Alpha || 2026-09-29 || JBallados || Stability_Reporting
// =========================================
// FUNCTION LOAD REPORT UPLOAD CONFIG
// Search: loadReportUploadConfig
// Ver 0.1.13 Alpha || 2026-09-27 || JBallados
// Ver 0.1.14 Alpha || 2026-09-27 || JBallados || Per_Device_Credentials
// Ver 0.1.15 Alpha || 2026-09-28 || JBallados || AppsScript_Only_Cleanup
// Ver 0.1.16 Alpha || 2026-09-28 || JBallados || First_Time_Setup
// =========================================
function loadReportUploadConfig() {

    if (!fs.existsSync(reportUploadConfigFile)) return null;
    try {
        const raw = fs.readFileSync(reportUploadConfigFile, 'utf8').replace(/^\uFEFF/, '');
        const parsed = JSON.parse(raw);
        if (!parsed || parsed.enabled === false) return null;

        const endpoint = String(parsed.endpoint || '').trim();
        const agentId = String(parsed.agentId || '').trim();
        const agentName = String(parsed.agentName || '').trim();
        const lastName = sanitizeLastName(parsed.lastName || '');
        const department = normalizeDepartment(parsed.department, 'OOS');
        let pod = String(parsed.pod || '').trim();
        if (/^\d+$/.test(pod)) pod = 'Pod ' + pod;

        const deviceId = String(parsed.deviceId || '').trim();
        const deviceToken = String(parsed.deviceToken || '').trim();
        if (deviceId && deviceId !== localDeviceId) {
            throw new Error('Saved upload credential belongs to a different Auto Tracker device installation.');
        }

        if (!/^https:\/\/script\.google\.com\/.+\/exec(?:\?.*)?$/i.test(endpoint)) {
            throw new Error('Apps Script endpoint must be a deployed /exec URL.');
        }
        if (!agentId || !agentName || !lastName || !department || !pod) {
            throw new Error('Agent ID, agent name, last name, Department, and Pod are required.');
        }
        if (!deviceId || !deviceToken) {
            throw new Error('A registered per-device credential is required.');
        }

        return {
            version: '0.1.21',
            endpoint,
            agentId,
            agentName,
            lastName,
            department,
            pod,
            deviceId,
            deviceToken,
            credentialMode: 'per-device',
            maxRetries: Math.max(1, Math.min(5, Number(parsed.maxRetries) || 3))
        };
    } catch (error) {
        console.error('[UPLOAD] Invalid report-upload-config.json:', error.message);
        return null;
    }

}

// =========================================
// FUNCTION SAVE REPORT UPLOAD CONFIG
// Search: saveReportUploadConfig
// Ver 0.1.14 Alpha || 2026-09-27 || JBallados
// Ver 0.1.16 Alpha || 2026-09-28 || JBallados || First_Time_Setup
// =========================================
function saveReportUploadConfig(config) {

    const temp = reportUploadConfigFile + '.tmp';
    try {
        fs.writeFileSync(temp, JSON.stringify(config, null, 2), { encoding: 'utf8', mode: 0o600 });
        fs.renameSync(temp, reportUploadConfigFile);
        try { fs.chmodSync(reportUploadConfigFile, 0o600); } catch {}
        return true;
    } catch (error) {
        try { if (fs.existsSync(temp)) fs.unlinkSync(temp); } catch {}
        console.error('[UPLOAD] Could not save report upload config:', error.message);
        return false;
    }

}

// =========================================
// FUNCTION GET PUBLIC REPORT UPLOAD SETTINGS
// Search: getPublicReportUploadSettings
// Ver 0.1.13 Alpha || 2026-09-27 || JBallados || WebUI_Upload_Settings
// Ver 0.1.14 Alpha || 2026-09-27 || JBallados || Per_Device_Credentials
// Ver 0.1.16 Alpha || 2026-09-28 || JBallados || First_Time_Setup
// =========================================
function getPublicReportUploadSettings() {

    const config = loadReportUploadConfig();
    return {
        configured: Boolean(config),
        endpoint: config?.endpoint || '',
        agentId: config?.agentId || '',
        agentName: config?.agentName || '',
        lastName: config?.lastName || reportSettings.lastName || '',
        department: config?.department || 'OOS',
        pod: config?.pod || '',
        deviceId: config?.deviceId || localDeviceId,
        credentialMode: config?.credentialMode || 'unconfigured',
        tokenConfigured: Boolean(config?.deviceToken),
        deviceRegistered: Boolean(config?.deviceId && config?.deviceToken),
        setupComplete: Boolean(config?.deviceId && config?.deviceToken && config?.lastName && reportSettings.lastName === config?.lastName),
        reportFileExample: (config?.lastName || reportSettings.lastName)
            ? (config?.lastName || reportSettings.lastName) + '_YYYY-MM-DD_' + (normalizeDepartment(config?.department || shiftDepartment || 'OOS', 'OOS') || 'OOS') + '.xlsx'
            : '',
        maxRetries: config?.maxRetries || 3
    };

}

// =========================================
// FUNCTION REGISTER REPORT UPLOAD DEVICE FROM WEB UI
// Search: registerReportUploadDeviceFromWebUi
// Ver 0.1.14 Alpha || 2026-09-27 || JBallados
// Ver 0.1.15 Alpha || 2026-09-28 || JBallados || AppsScript_Only_Cleanup
// Ver 0.1.16 Alpha || 2026-09-28 || JBallados || First_Time_Setup
// =========================================
async function registerReportUploadDeviceFromWebUi(payload) {

    const existing = loadReportUploadConfig();
    const endpoint = String(payload?.endpoint || existing?.endpoint || '').trim();
    const registrationToken = String(payload?.registrationToken || '').trim();
    const agentId = String(payload?.agentId || existing?.agentId || '').trim();
    const agentName = String(payload?.agentName || existing?.agentName || '').trim();
    const lastName = sanitizeLastName(payload?.lastName || existing?.lastName || reportSettings.lastName);
    const department = normalizeDepartment(payload?.department || existing?.department || 'OOS');
    let pod = String(payload?.pod || existing?.pod || '').trim();
    if (/^\d+$/.test(pod)) pod = 'Pod ' + pod;

    if (!/^https:\/\/script\.google\.com\/.+\/exec(?:\?.*)?$/i.test(endpoint)) {
        return { success: false, error: 'INVALID_APPS_SCRIPT_ENDPOINT', message: 'Enter the deployed Apps Script /exec URL.' };
    }
    if (!/^[A-Za-z0-9][A-Za-z0-9._-]{1,63}$/.test(agentId)) {
        return { success: false, error: 'INVALID_AGENT_ID', message: 'Agent ID may use letters, numbers, dot, underscore, and hyphen.' };
    }
    if (!agentName) {
        return { success: false, error: 'AGENT_NAME_REQUIRED', message: 'Agent name is required.' };
    }
    if (!lastName) {
        return { success: false, error: 'LAST_NAME_REQUIRED', message: 'Agent last name is required for the daily report filename.' };
    }
    if (!department) {
        return { success: false, error: 'INVALID_DEPARTMENT', message: 'Department must be OOS or ENCORD. Legacy CWH values are migrated to OOS.' };
    }
    if (!/^POD[\s_-]*[A-Za-z0-9_-]{1,20}$/i.test(pod)) {
        return { success: false, error: 'INVALID_POD', message: 'Pod must look like Pod 10, POD-10, or POD_A.' };
    }

    const identityChangeRequested = Boolean(existing && (
        existing.agentId !== agentId
        || String(existing.agentName || '').trim() !== agentName
        || sanitizeLastName(existing.lastName) !== lastName
        || normalizeDepartment(existing.department || 'OOS', 'OOS') !== department
        || String(existing.pod || '').toLowerCase() !== String(pod || '').toLowerCase()
    ));
    if (shiftStarted && identityChangeRequested) {
        return {
            success: false,
            error: 'SHIFT_ACTIVE_IDENTITY_LOCKED',
            message: 'End the active shift before changing Agent ID, Agent Name, Last Name, Department, or Pod. This prevents reports from being split between identities or assignments.'
        };
    }

    const existingDeviceIsReusable = Boolean(
        existing?.credentialMode === 'per-device'
        && existing?.deviceId
        && existing?.deviceToken
        && existing.endpoint === endpoint
        && existing.agentId === agentId
        && String(existing.agentName || '').trim() === agentName
        && existing.lastName === lastName
        && normalizeDepartment(existing.department, 'OOS') === department
        && existing.pod.toLowerCase() === pod.toLowerCase()
    );

    if (!registrationToken && existingDeviceIsReusable) {
        const config = {
            version: '0.1.21',
            enabled: true,
            endpoint,
            agentId,
            agentName,
            lastName,
            department,
            pod,
            deviceId: existing.deviceId,
            deviceToken: existing.deviceToken,
            credentialMode: 'per-device',
            maxRetries: Math.max(1, Math.min(5, Number(payload?.maxRetries || existing.maxRetries || 3)))
        };
        if (!saveReportUploadConfig(config)) {
            return { success: false, error: 'UPLOAD_SETTINGS_SAVE_FAILED', message: 'Controller could not save the upload settings.' };
        }
        saveReportSettings({ lastName });
        return {
            success: true,
            status: 'DEVICE_CREDENTIAL_REUSED',
            setupComplete: true,
            uploadSettings: getPublicReportUploadSettings(),
            reportSettings: getPublicReportSettings()
        };
    }

    if (!registrationToken) {
        return {
            success: false,
            error: 'REGISTRATION_TOKEN_REQUIRED',
            message: 'Registration token is required for first setup, device rotation, or Agent/Department/Pod reassignment.'
        };
    }

    const deviceId = localDeviceId;
    const deviceToken = crypto.randomBytes(32).toString('hex');
    const deviceTokenHash = sha256Text(deviceToken);

    const registrationPayload = JSON.stringify({
        action: 'registerDevice',
        registrationToken,
        deviceId,
        deviceTokenHash,
        agentId,
        agentName,
        lastName,
        department,
        pod
    });

    try {
        const response = await requestReportUpload(endpoint, 'POST', registrationPayload);
        let result;
        try {
            result = JSON.parse(response.body);
        } catch (error) {
            throw new Error('Device registration service returned a non-JSON response.');
        }
        if (!(response.statusCode >= 200 && response.statusCode < 300 && result.ok === true)) {
            const registrationError = new Error(result.message || 'Device registration failed.');
            registrationError.code = String(result.error || 'DEVICE_REGISTRATION_FAILED');
            throw registrationError;
        }

        const config = {
            version: '0.1.21',
            enabled: true,
            endpoint,
            agentId,
            agentName,
            lastName,
            department,
            pod,
            deviceId,
            deviceToken,
            credentialMode: 'per-device',
            maxRetries: Math.max(1, Math.min(5, Number(payload?.maxRetries || existing?.maxRetries || 3)))
        };
        if (!saveReportUploadConfig(config)) {
            return { success: false, error: 'UPLOAD_SETTINGS_SAVE_FAILED', message: 'Device registered, but the controller could not save the local credential.' };
        }
        saveReportSettings({ lastName });

        logWithTimestamp('DEVICE UPLOAD CREDENTIAL REGISTERED: ' + deviceId + ' | ' + agentId + ' | ' + lastName + ' | ' + department + ' | ' + pod);
        return {
            success: true,
            status: result.status || 'registered',
            setupComplete: true,
            uploadSettings: getPublicReportUploadSettings(),
            reportSettings: getPublicReportSettings()
        };
    } catch (error) {
        console.error('[UPLOAD] Device registration failed:', error.message);
        return {
            success: false,
            error: error.code || 'DEVICE_REGISTRATION_FAILED',
            message: error.message || 'Device registration failed.'
        };
    }

}

function getCurrentReleaseIdentity() {
    const tampermonkey = getTampermonkeyScriptInfo();
    let controllerSha256 = null;
    try {
        controllerSha256 = fs.existsSync(__filename) ? sha256File(__filename) : null;
    } catch {}
    return {
        version: CONTROLLER_VERSION,
        revision: CONTROLLER_RELEASE_REVISION,
        controllerSha256,
        tampermonkeySha256: tampermonkey.sha256 || null,
        tampermonkeyVersion: tampermonkey.version || null,
        tampermonkeyRevision: Number(tampermonkey.revision || 0)
    };
}

async function checkLatestReleaseFromAppsScript() {
    const config = loadReportUploadConfig();
    if (!config?.endpoint) {
        latestReleaseState = { configured:false, updateAvailable:false, latestVersion:null, release:null, checkedAt:Date.now() };
        return latestReleaseState;
    }
    try {
        const identity = getCurrentReleaseIdentity();
        const payload = JSON.stringify({
            action:'checkLatestRelease',
            department: config?.department || 'OOS',
            currentVersion:identity.version,
            currentRevision:identity.revision,
            controllerSha256:identity.controllerSha256,
            tampermonkeySha256:identity.tampermonkeySha256,
            channel:'stable'
        });
        const response = await requestReportUpload(config.endpoint, 'POST', payload);
        const parsed = JSON.parse(response.body || '{}');
        latestReleaseState = { ...parsed, checkedAt:Date.now() };
        if (parsed.integrityWarning) {
            console.warn('[UPDATE] RELEASE CONTENT CHANGED: Drive files no longer match the approved release.json checksum. Update is blocked until the release manifest/revision is corrected.');
        } else if (parsed.updateAvailable && parsed.latestVersion) {
            console.log('[UPDATE] Auto Tracker update available: v' + parsed.latestVersion + '-r' + Number(parsed.latestRevision || 0) + ' (' + String(parsed.reason || 'UPDATE') + ')');
            if (parsed.release?.details) console.log('[UPDATE] ' + parsed.release.details);
        }
        return latestReleaseState;
    } catch (error) {
        latestReleaseState = { configured:true, updateAvailable:false, latestVersion:null, release:null, checkedAt:Date.now(), error:'UPDATE_CHECK_FAILED' };
        writeControllerErrorLog('UPDATE', error, { component:'UPDATE', errorCode:'ERR-UPDATE-CHECK', severity:'WARN' });
        return latestReleaseState;
    }
}

function uniqueUpdateTargets(paths) {
    const seen = new Set();
    return (paths || []).filter(filePath => {
        if (!filePath) return false;
        const resolved = path.resolve(filePath);
        const key = process.platform === 'win32' ? resolved.toLowerCase() : resolved;
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
    }).map(filePath => path.resolve(filePath));
}

function releaseDownloadAuthPayload(config, release) {
    return {
        action: 'downloadApprovedRelease',
        deviceId: config.deviceId,
        deviceToken: config.deviceToken,
        agentId: config.agentId,
        agentName: config.agentName,
        lastName: config.lastName,
        department: config.department || 'OOS',
        pod: config.pod,
        version: release.latestVersion,
        revision: Number(release.latestRevision || 0),
        channel: 'stable'
    };
}

function decodeApprovedReleasePart(part, expectedSha, label) {
    if (!part || typeof part.fileBase64 !== 'string' || !part.fileBase64) {
        throw new Error(label + ' release payload is missing.');
    }
    const bytes = Buffer.from(part.fileBase64, 'base64');
    if (!bytes.length || bytes.length > 2 * 1024 * 1024) {
        throw new Error(label + ' release payload has an invalid size.');
    }
    const actualSha = crypto.createHash('sha256').update(bytes).digest('hex');
    const approvedSha = String(expectedSha || part.sha256 || '').trim().toLowerCase();
    if (!/^[a-f0-9]{64}$/.test(approvedSha) || actualSha !== approvedSha) {
        const error = new Error(label + ' SHA-256 verification failed.');
        error.code = 'RELEASE_DOWNLOAD_CHECKSUM_MISMATCH';
        throw error;
    }
    return { bytes, sha256: actualSha };
}

function validateDownloadedController(bytes, version, revision) {
    const source = bytes.toString('utf8').replace(/^\uFEFF/, '');
    const versionMatch = source.match(/const\s+CONTROLLER_VERSION\s*=\s*['"]([^'"]+)['"]/);
    if (!versionMatch || String(versionMatch[1]) !== String(version)) {
        const error = new Error('Downloaded controller version does not match the approved release.');
        error.code = 'RELEASE_CONTROLLER_VERSION_MISMATCH';
        throw error;
    }
    const revisionMatch = source.match(/const\s+CONTROLLER_SOURCE_RELEASE_REVISION\s*=\s*(\d+)/);
    const parsedRevision = revisionMatch ? Math.max(0, Math.floor(Number(revisionMatch[1]) || 0)) : 0;
    if (Number(revision || 0) > 0 && parsedRevision !== Number(revision || 0)) {
        const error = new Error('Downloaded controller release revision does not match release.json.');
        error.code = 'RELEASE_CONTROLLER_REVISION_MISMATCH';
        throw error;
    }

    const temp = path.join(__dirname, '.tracker-controller-update-' + process.pid + '-' + Date.now() + '.js');
    try {
        fs.writeFileSync(temp, bytes, { mode: 0o600 });
        execFileSync(process.execPath, ['--check', temp], { stdio: 'pipe', timeout: 15000 });
    } catch (error) {
        const wrapped = new Error('Downloaded controller failed Node.js syntax validation.');
        wrapped.code = 'RELEASE_CONTROLLER_SYNTAX_INVALID';
        wrapped.cause = error;
        throw wrapped;
    } finally {
        try { if (fs.existsSync(temp)) fs.unlinkSync(temp); } catch {}
    }
}

function validateDownloadedTampermonkey(bytes, version, revision) {
    const source = bytes.toString('utf8').replace(/^\uFEFF/, '');
    const parsed = parseTampermonkeySource(source);
    if (!parsed.valid || !parsed.version || String(parsed.version) !== String(version)) {
        const error = new Error('Downloaded Tampermonkey source does not match the approved release version.');
        error.code = 'RELEASE_USERSCRIPT_VERSION_MISMATCH';
        throw error;
    }
    const parsedRevision = Math.max(0, Math.floor(Number(parsed.releaseRevision || 0)));
    if (Number(revision || 0) > 0 && parsedRevision !== Number(revision || 0)) {
        const error = new Error('Downloaded Tampermonkey release revision does not match release.json.');
        error.code = 'RELEASE_USERSCRIPT_REVISION_MISMATCH';
        throw error;
    }
}

function createReleaseUpdateBackup(version, revision, targets) {
    const stamp = new Date().toISOString().replace(/[:.]/g, '-');
    const safeVersion = String(version || 'unknown').replace(/[^A-Za-z0-9._-]/g, '_');
    const backupFolder = path.join(__dirname, 'Backups', 'Update_' + stamp + '_v' + safeVersion + '_r' + Number(revision || 0));
    fs.mkdirSync(backupFolder, { recursive: true });
    const records = [];

    for (let index = 0; index < targets.length; index++) {
        const target = targets[index];
        const record = { target, existed: fs.existsSync(target), backupPath: null };
        if (record.existed) {
            const backupName = String(index + 1).padStart(2, '0') + '_' + path.basename(target);
            record.backupPath = path.join(backupFolder, backupName);
            fs.copyFileSync(target, record.backupPath);
        }
        records.push(record);
    }
    fs.writeFileSync(
        path.join(backupFolder, 'update-backup.json'),
        JSON.stringify({ version, revision, createdAt: Date.now(), records }, null, 2),
        'utf8'
    );
    return { backupFolder, records };
}

function writeVerifiedUpdateTarget(target, bytes, expectedSha) {
    fs.mkdirSync(path.dirname(target), { recursive: true });
    const temp = target + '.tracker-update-' + process.pid + '.tmp';
    fs.writeFileSync(temp, bytes, { mode: 0o600 });
    const tempSha = sha256File(temp);
    if (tempSha !== expectedSha) {
        try { fs.unlinkSync(temp); } catch {}
        throw new Error('Staged update file failed local checksum verification: ' + path.basename(target));
    }
    fs.copyFileSync(temp, target);
    try { fs.unlinkSync(temp); } catch {}
    const installedSha = sha256File(target);
    if (installedSha !== expectedSha) {
        throw new Error('Installed update file failed checksum verification: ' + path.basename(target));
    }
}

function rollbackReleaseUpdate(records) {
    for (const record of [...(records || [])].reverse()) {
        try {
            if (record.existed && record.backupPath && fs.existsSync(record.backupPath)) {
                fs.copyFileSync(record.backupPath, record.target);
            } else if (!record.existed && fs.existsSync(record.target)) {
                fs.unlinkSync(record.target);
            }
        } catch (error) {
            writeControllerErrorLog('UPDATE', error, {
                component: 'UPDATE',
                errorCode: 'ERR-UPDATE-ROLLBACK',
                severity: 'ERROR',
                target: path.basename(record.target || '')
            });
        }
    }
}

async function installLatestReleaseFromAppsScript() {
    const config = loadReportUploadConfig();
    if (!config?.endpoint) {
        return { success:false, error:'UPDATE_NOT_CONFIGURED', message:'Complete First-Time / Device Setup before installing updates.' };
    }

    const releaseState = await checkLatestReleaseFromAppsScript();
    if (releaseState.integrityWarning) {
        return { success:false, error:'RELEASE_CONTENT_CHANGED', message:'The approved Drive release failed checksum validation. Installation is blocked.' };
    }
    if (!releaseState.updateAvailable || !releaseState.latestVersion || !releaseState.release) {
        return {
            success:true,
            status:'CURRENT',
            updateAvailable:false,
            message:'Auto Tracker is already up to date.',
            controllerVersion:CONTROLLER_VERSION,
            controllerRevision:CONTROLLER_RELEASE_REVISION
        };
    }

    lastUpdateInstallState = {
        state:'DOWNLOADING',
        version:releaseState.latestVersion,
        revision:Number(releaseState.latestRevision || 0),
        stagedAt:null,
        backupFolder:null,
        restartRequired:false
    };

    try {
        const response = await requestReportUpload(
            config.endpoint,
            'POST',
            JSON.stringify(releaseDownloadAuthPayload(config, releaseState))
        );
        const download = JSON.parse(response.body || '{}');
        if (!download.ok) {
            const error = new Error(download.message || download.error || 'Approved release download failed.');
            error.code = download.error || 'RELEASE_DOWNLOAD_FAILED';
            throw error;
        }
        if (String(download.version || '') !== String(releaseState.latestVersion)
            || Number(download.revision || 0) !== Number(releaseState.latestRevision || 0)) {
            const error = new Error('Downloaded release identity changed after the update check.');
            error.code = 'RELEASE_IDENTITY_CHANGED';
            throw error;
        }

        const approvedControllerSha = String(releaseState.release.controllerSha256 || releaseState.release.actualControllerSha256 || '').toLowerCase();
        const approvedTampermonkeySha = String(releaseState.release.tampermonkeySha256 || releaseState.release.actualTampermonkeySha256 || '').toLowerCase();
        const controller = decodeApprovedReleasePart(download.controller, approvedControllerSha, 'Controller');
        const tampermonkey = decodeApprovedReleasePart(download.tampermonkey, approvedTampermonkeySha, 'Tampermonkey');

        validateDownloadedController(controller.bytes, download.version, download.revision);
        validateDownloadedTampermonkey(tampermonkey.bytes, download.version, download.revision);

        const runtimeTampermonkeyFallback = path.join(__dirname, 'Tampermonkey_Modifications', 'TamperMonkey Mods');
        const controllerTargets = uniqueUpdateTargets([__filename, controllerSourceFile]);
        const tampermonkeyTargets = uniqueUpdateTargets([tampermonkeyScriptFile, runtimeTampermonkeyFallback]);
        const allTargets = [...controllerTargets, ...tampermonkeyTargets];
        const backup = createReleaseUpdateBackup(download.version, download.revision, allTargets);

        try {
            for (const target of controllerTargets) writeVerifiedUpdateTarget(target, controller.bytes, controller.sha256);
            for (const target of tampermonkeyTargets) writeVerifiedUpdateTarget(target, tampermonkey.bytes, tampermonkey.sha256);
        } catch (installError) {
            rollbackReleaseUpdate(backup.records);
            throw installError;
        }

        lastUpdateInstallState = {
            state:'STAGED',
            version:download.version,
            revision:Number(download.revision || 0),
            stagedAt:Date.now(),
            backupFolder:backup.backupFolder,
            restartRequired:true
        };
        logWithTimestamp(
            'AUTO TRACKER UPDATE STAGED: v' + download.version + '-r' + Number(download.revision || 0)
            + ' | Controller and Tampermonkey files verified and replaced | Backup: ' + backup.backupFolder,
            'INFO',
            'UPDATE',
            { eventCode:'EVT-UPDATE-STAGED', version:download.version, revision:Number(download.revision || 0) }
        );

        return {
            success:true,
            status:'UPDATE_STAGED',
            version:download.version,
            revision:Number(download.revision || 0),
            message:'Controller and Tampermonkey update files were installed and verified. Approve the userscript update, then restart the controller to finish.',
            backupFolder:backup.backupFolder,
            restartRequired:true,
            tampermonkeyUpdateRequired:true,
            applyUrl:'http://127.0.0.1:9000/tampermonkey.user.js'
        };
    } catch (error) {
        lastUpdateInstallState = {
            state:'FAILED',
            version:releaseState.latestVersion,
            revision:Number(releaseState.latestRevision || 0),
            stagedAt:null,
            backupFolder:null,
            restartRequired:false,
            error:error.code || 'UPDATE_INSTALL_FAILED'
        };
        writeControllerErrorLog('UPDATE', error, {
            component:'UPDATE',
            errorCode:error.code || 'ERR-UPDATE-INSTALL',
            severity:'ERROR',
            version:releaseState.latestVersion,
            revision:Number(releaseState.latestRevision || 0)
        });
        return {
            success:false,
            error:error.code || 'UPDATE_INSTALL_FAILED',
            message:error.message || 'Auto Tracker update installation failed.'
        };
    }
}

function getSystemHealth() {
    const checks = {
        reportsFolder: fs.existsSync(reportsFolder),
        logsFolder: fs.existsSync(logsFolder),
        tampermonkeySource: getTampermonkeyScriptInfo().valid,
        uploadConfigured: Boolean(loadReportUploadConfig()),
        deviceId: Boolean(localDeviceId)
    };
    const warnings = Object.keys(checks).filter(key => checks[key] === false);
    return { status: warnings.length ? 'WARNING' : 'HEALTHY', checks, warnings };
}

// =========================================
// FUNCTION REQUEST REPORT UPLOAD
// Search: requestReportUpload
// Ver 0.1.13 Alpha || 2026-09-27 || JBallados
// =========================================
function requestReportUpload(url, method, body, redirectsLeft = 5) {

    return new Promise((resolve, reject) => {
        const headers = { Accept: 'application/json' };
        if (body !== null && body !== undefined) {
            headers['Content-Type'] = 'application/json; charset=utf-8';
            headers['Content-Length'] = Buffer.byteLength(body);
        }
        const request = https.request(url, { method, headers }, response => {
            const chunks = [];
            response.on('data', chunk => chunks.push(chunk));
            response.on('end', () => {
                const responseBody = Buffer.concat(chunks).toString('utf8');
                const statusCode = Number(response.statusCode || 0);
                const location = response.headers.location;
                if ([301, 302, 303, 307, 308].includes(statusCode) && location) {
                    if (redirectsLeft <= 0) {
                        reject(new Error('Too many redirects from the upload service.'));
                        return;
                    }
                    const nextUrl = new URL(location, url).toString();
                    const preserveMethod = statusCode === 307 || statusCode === 308;
                    requestReportUpload(nextUrl, preserveMethod ? method : 'GET', preserveMethod ? body : null, redirectsLeft - 1).then(resolve).catch(reject);
                    return;
                }
                resolve({ statusCode, body: responseBody });
            });
        });
        request.setTimeout(30000, () => request.destroy(new Error('Upload request timed out.')));
        request.on('error', reject);
        if (body !== null && body !== undefined) request.write(body);
        request.end();
    });

}

// End Modification Ver 0.1.13 Alpha

function readJsonStateFile(filePath, fallback) {
    try {
        if (!fs.existsSync(filePath)) return fallback;
        return JSON.parse(fs.readFileSync(filePath, 'utf8')) || fallback;
    } catch {
        return fallback;
    }
}

function writeJsonStateFile(filePath, value) {
    const temp = filePath + '.tmp';
    fs.writeFileSync(temp, JSON.stringify(value, null, 2), { encoding: 'utf8', mode: 0o600 });
    fs.renameSync(temp, filePath);
    try { fs.chmodSync(filePath, 0o600); } catch {}
}

function markUploadVerified(fileName, reportDate, info = {}) {
    const state = readJsonStateFile(uploadVerificationFile, { version: 1, files: {} });
    state.files = state.files || {};
    state.files[String(fileName)] = {
        reportDate: String(reportDate || ''),
        verified: true,
        verifiedAt: Date.now(),
        fileId: info.fileId || null,
        checksumSha256: info.checksumSha256 || null,
        action: info.action || 'uploaded'
    };
    writeJsonStateFile(uploadVerificationFile, state);
}

function reportBundleVerifiedForRetention(fileName) {
    const state = readJsonStateFile(uploadVerificationFile, { version: 1, files: {} });
    const name = String(fileName || '');
    const stem = name
        .replace(/\.snapshot\.json$/i, '')
        .replace(/\.integrity\.json$/i, '')
        .replace(/\.xlsx$/i, '')
        .replace(/\.txt$/i, '');
    const report = state.files?.[stem + '.xlsx'];
    const log = state.files?.[stem + '.txt'];
    return Boolean(report?.verified && log?.verified);
}

function queuePendingUpload(item) {
    const queue = readJsonStateFile(uploadQueueFile, { version: 1, items: [] });
    queue.items = Array.isArray(queue.items) ? queue.items : [];
    const key = String(item.filePath || '') + '|' + String(item.reportDate || '') + '|' + String(item.fileKind || '');
    queue.items = queue.items.filter(entry => entry.key !== key);
    queue.items.push({ ...item, key, queuedAt: Date.now(), attempts: Number(item.attempts || 0) });
    writeJsonStateFile(uploadQueueFile, queue);
}

function removePendingUpload(filePath, reportDate, fileKind) {
    const queue = readJsonStateFile(uploadQueueFile, { version: 1, items: [] });
    const key = String(filePath || '') + '|' + String(reportDate || '') + '|' + String(fileKind || '');
    queue.items = (Array.isArray(queue.items) ? queue.items : []).filter(entry => entry.key !== key);
    writeJsonStateFile(uploadQueueFile, queue);
}

async function retryPendingUploads() {
    const queue = readJsonStateFile(uploadQueueFile, { version: 1, items: [] });
    const items = Array.isArray(queue.items) ? [...queue.items] : [];
    if (!items.length) return { attempted: 0, remaining: 0 };
    for (const item of items.slice(0, 20)) {
        if (!item.filePath || !fs.existsSync(item.filePath)) {
            removePendingUpload(item.filePath, item.reportDate, item.fileKind);
            continue;
        }
        try {
            const result = await uploadFileToAppsScriptDrive(item.filePath, item.reportDate, item.fileKind, item.reportSummary || null, { fromQueue: true });
            if (result.ok) removePendingUpload(item.filePath, item.reportDate, item.fileKind);
        } catch (error) {
            writeControllerErrorLog('UPLOAD', error, { component: 'UPLOAD', errorCode: 'ERR-UPLOAD-RETRY', severity: 'WARN', file: path.basename(item.filePath) });
        }
    }
    const after = readJsonStateFile(uploadQueueFile, { version: 1, items: [] });
    return { attempted: items.length, remaining: Array.isArray(after.items) ? after.items.length : 0 };
}

// =========================================
// FUNCTION UPLOAD FILE TO APPS SCRIPT DRIVE
// Search: uploadFileToAppsScriptDrive
// Ver 0.1.13 Alpha || 2026-09-27 || JBallados
// Ver 0.1.13 Alpha || 2026-09-27 || JBallados || Dual_Report_Upload_Hotfix
// =========================================
async function uploadFileToAppsScriptDrive(filePath, reportDate, fileKind = 'report', reportSummary = null, options = {}) {

    const config = loadReportUploadConfig();
    if (!config) {
        return {
            configured: false,
            ok: false,
            fileName: path.basename(filePath || ''),
            fileKind,
            error: 'UPLOAD_NOT_CONFIGURED'
        };
    }
    if (!filePath || !fs.existsSync(filePath)) {
        const fileName = path.basename(filePath || '');
        console.error('[UPLOAD] File was not found:', filePath);
        return { configured: true, ok: false, fileName, fileKind, error: 'FILE_NOT_FOUND' };
    }

    const extension = path.extname(filePath).toLowerCase();
    const allowed = new Set(['.xlsx', '.xls', '.txt']);
    if (!allowed.has(extension)) {
        console.error('[UPLOAD] Unsupported Apps Script upload type:', extension);
        return {
            configured: true,
            ok: false,
            fileName: path.basename(filePath),
            fileKind,
            error: 'INVALID_FILE_TYPE'
        };
    }

    const uploadTraceId = createTraceId('UPLOAD');
    const fileBytes = fs.readFileSync(filePath);
    const checksumSha256 = crypto.createHash('sha256').update(fileBytes).digest('hex');
    const mimeType = extension === '.txt'
        ? 'text/plain'
        : extension === '.xls'
            ? 'application/vnd.ms-excel'
            : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    const payload = JSON.stringify({
        deviceId: config.deviceId,
        deviceToken: config.deviceToken,
        agentId: config.agentId,
        agentName: config.agentName,
        lastName: config.lastName,
        department: config.department || 'OOS',
        pod: config.pod,
        reportDate: String(reportDate),
        fileKind: fileKind === 'log' ? 'log' : 'report',
        fileName: path.basename(filePath),
        mimeType,
        fileBase64: fileBytes.toString('base64'),
        checksumSha256,
        reportSummary: fileKind === 'report' ? reportSummary : null,
        diagnosticTraceId: uploadTraceId
    });

    let lastError = null;
    for (let attempt = 1; attempt <= config.maxRetries; attempt++) {
        try {
            console.log(`[UPLOAD] Sending ${path.basename(filePath)} (attempt ${attempt}/${config.maxRetries}) [${uploadTraceId}]...`);
            writeStructuredActivityLog('upload.attempt.started', {
                fileName: path.basename(filePath),
                fileKind,
                reportDate: String(reportDate),
                attempt,
                maxRetries: config.maxRetries
            }, {
                severity: 'INFO',
                component: 'UPLOAD',
                eventCode: 'EVT-UPLOAD-ATTEMPT-START',
                traceId: uploadTraceId
            });
            const response = await requestReportUpload(config.endpoint, 'POST', payload);
            let result;
            try {
                result = JSON.parse(response.body);
            } catch (error) {
                const preview = String(response.body || '').replace(/\s+/g, ' ').slice(0, 180);
                throw new Error(`Upload service returned non-JSON response (HTTP ${response.statusCode}): ${preview}`);
            }

            if (response.statusCode >= 200 && response.statusCode < 300 && result.ok === true) {
                const action = String(result.action || (result.duplicate === true ? 'unchanged' : 'updated'));
                console.log(`[UPLOAD] ${path.basename(filePath)} ${action}. Drive ID: ${result.fileId || 'N/A'}`);
                logWithTimestamp(
                    `REPORT UPLOAD ${action.toUpperCase()}: ${path.basename(filePath)}`,
                    'INFO',
                    'UPLOAD',
                    { eventCode: 'EVT-UPLOAD-SUCCESS', traceId: uploadTraceId, attempt, fileKind, reportDate: String(reportDate) }
                );
                markUploadVerified(path.basename(filePath), reportDate, { fileId: result.fileId || null, checksumSha256, action });
                removePendingUpload(filePath, reportDate, fileKind);
                return {
                    configured: true,
                    ok: true,
                    fileName: path.basename(filePath),
                    fileKind,
                    action,
                    duplicate: result.duplicate === true,
                    fileId: result.fileId || null,
                    checksumSha256,
                    traceId: uploadTraceId
                };
            }

            const serverError = new Error(result.message || `Upload service returned HTTP ${response.statusCode}.`);
            serverError.code = String(result.error || '');
            serverError.nonRetryable = [
                'UNAUTHORIZED',
                'DEVICE_CREDENTIAL_REQUIRED',
                'DEVICE_NOT_REGISTERED',
                'INVALID_DEVICE_TOKEN',
                'DEVICE_BINDING_MISMATCH',
                'LAST_NAME_MISMATCH',
                'POD_FOLDER_NOT_FOUND',
                'DUPLICATE_POD_FOLDER',
                'INVALID_REPORT_SUMMARY',
                'INVALID_AGENT_ID',
                'INVALID_POD',
                'INVALID_FILE_TYPE',
                'INVALID_FILE_NAME',
                'INVALID_CHECKSUM',
                'FILE_TOO_LARGE'
            ].includes(serverError.code);
            throw serverError;
        } catch (error) {
            lastError = error;
            writeStructuredActivityLog('upload.attempt.failed', {
                fileName: path.basename(filePath),
                fileKind,
                reportDate: String(reportDate),
                attempt,
                maxRetries: config.maxRetries,
                errorCode: String(error?.code || 'UPLOAD_ATTEMPT_FAILED').slice(0, 96),
                message: redactSensitiveLogText(error?.message || String(error), 1200),
                retrying: !(error.nonRetryable || attempt >= config.maxRetries)
            }, {
                severity: error.nonRetryable || attempt >= config.maxRetries ? 'ERROR' : 'WARN',
                component: 'UPLOAD',
                eventCode: 'EVT-UPLOAD-ATTEMPT-FAILED',
                traceId: uploadTraceId
            });
            if (error.nonRetryable || attempt >= config.maxRetries) break;
            const delayMs = Math.min(15000, attempt * 4000);
            console.warn(`[UPLOAD] Attempt failed for ${path.basename(filePath)}: ${error.message}. Retrying in ${Math.round(delayMs / 1000)}s...`);
            await new Promise(resolve => setTimeout(resolve, delayMs));
        }
    }

    const message = lastError ? lastError.message : 'Unknown upload failure.';
    console.error('[UPLOAD] Upload failed. Local file was kept:', path.basename(filePath), message);
    const uploadErrorRecord = writeControllerErrorLog('UPLOAD', lastError || new Error(message), {
        component: 'UPLOAD',
        errorCode: String(lastError?.code || 'ERR-UPLOAD-FAILED').slice(0, 96),
        severity: 'ERROR',
        traceId: uploadTraceId,
        fileName: path.basename(filePath),
        fileKind,
        reportDate: String(reportDate),
        maxRetries: config.maxRetries
    });
    logWithTimestamp(
        'REPORT UPLOAD FAILED: ' + path.basename(filePath) + ' | ' + message,
        'ERROR',
        'UPLOAD',
        { eventCode: 'EVT-UPLOAD-FAILED', traceId: uploadErrorRecord?.traceId || uploadTraceId, fileKind, reportDate: String(reportDate) }
    );
    if (!options.fromQueue) {
        queuePendingUpload({
            filePath,
            reportDate,
            fileKind,
            reportSummary: fileKind === 'report' ? reportSummary : null,
            lastError: lastError?.code || message
        });
    }
    return {
        configured: true,
        ok: false,
        fileName: path.basename(filePath),
        fileKind,
        error: lastError?.code || 'UPLOAD_FAILED',
        message,
        traceId: uploadTraceId
    };

}

// =========================================
// FUNCTION UPLOAD DAILY REPORT PAIR TO DRIVE
// Search: uploadDailyReportPairToDrive
// Ver 0.1.13 Alpha || 2026-09-27 || JBallados || Dual_Report_Upload_Hotfix
// =========================================
async function uploadDailyReportPairToDrive(reportTarget, reportDate, reportSummary = null) {

    const config = loadReportUploadConfig();
    if (!config) return { configured: false, ok: false, partialFailure: false, results: [] };

    const targets = [
        { filePath: reportTarget.reportPath, fileKind: 'report' },
        { filePath: reportTarget.logPath, fileKind: 'log' }
    ];
    const results = [];
    for (const target of targets) {
        const summary = target.fileKind === 'report' ? reportSummary : null;
        results.push(await uploadFileToAppsScriptDrive(target.filePath, reportDate, target.fileKind, summary));
    }

    const successCount = results.filter(item => item.ok).length;
    return {
        configured: true,
        ok: successCount === results.length,
        partialFailure: successCount > 0 && successCount < results.length,
        successCount,
        totalFiles: results.length,
        pod: config.pod,
        results
    };

}

// =========================================
// FUNCTION BUILD REPORT SUMMARY FROM SIGNED SNAPSHOT
// Search: buildReportSummaryFromSignedSnapshot
// Ver 0.1.18 Alpha || 2026-09-29 || JBallados || TeamLead_Index_Retry_Fix
// =========================================
function buildReportSummaryFromSignedSnapshot(reportPath, reportDate, lastName) {
    const snapshotPath = String(reportPath || '').replace(/\.xlsx$/i, '.snapshot.json');
    if (!snapshotPath || !fs.existsSync(snapshotPath)) return null;

    try {
        const snapshot = JSON.parse(fs.readFileSync(snapshotPath, 'utf8'));
        const { hmac, ...core } = snapshot || {};
        const expectedHmac = crypto.createHmac('sha256', integrityKey).update(JSON.stringify(core)).digest('hex');
        if (!hmac || hmac !== expectedHmac) return null;
        if (String(core.reportDate || '') !== String(reportDate || '')) return null;

        const source = core.source || {};
        const mode1 = source.mode1Metrics || {};
        const mode2 = source.mode2Metrics || {};
        const combined = source.reportTiming?.combined || {};
        const overtimeRaw = source.overtimeStats || {};
        const activeSeconds = Math.max(0, Number(combined.activeSeconds || 0));
        const idleSeconds = Math.max(0, Number(combined.idleSeconds || 0));
        const breakSeconds = Math.max(0, Number(combined.breakSeconds || 0));
        const bioSeconds = Math.max(0, Number(combined.bioSeconds || 0));
        const hbioSeconds = Math.max(0, Number(combined.hbioSeconds || 0));
        const shiftStartedAt = Number(source.shiftStartedAt || 0) || null;
        const shiftEndedAt = Number(source.shiftEndedAt || 0) || null;
        const reportDepartment = normalizeDepartment(source.shiftDepartment || source.department || 'OOS', 'OOS') || 'OOS';
        const snapshotSchedule = getShiftSchedule(shiftStartedAt, reportDepartment);
        const sessions = Array.isArray(source.breakSessions) ? source.breakSessions : [];
        const mode1Pause = summarizePauseSessions(sessions, shiftStartedAt, reportDepartment, 1);
        const mode2Pause = summarizePauseSessions(sessions, shiftStartedAt, reportDepartment, 2);
        let combinedPause = summarizePauseSessions(sessions, shiftStartedAt, reportDepartment);
        if (combinedPause.breakSeconds + combinedPause.lunchSeconds === 0 && breakSeconds > 0) {
            combinedPause = splitPauseSeconds(breakSeconds, shiftStartedAt, reportDepartment);
        }
        const rawOvertimePauseSeconds = Math.max(0, Math.floor(Number(overtimeRaw.breakMs || 0) / 1000));
        let overtimePause = summarizePauseSessions(
            sessions,
            shiftStartedAt,
            reportDepartment,
            null,
            snapshotSchedule?.overtimeStartsAt || null,
            shiftEndedAt || null
        );
        if (overtimePause.breakSeconds + overtimePause.lunchSeconds === 0 && rawOvertimePauseSeconds > 0) {
            overtimePause = splitPauseSeconds(rawOvertimePauseSeconds, shiftStartedAt, reportDepartment);
        }

        return {
            schemaVersion: 2,
            reportDate: String(reportDate),
            lastName: sanitizeLastName(lastName),
            generatedAt: Number(core.generatedAt || Date.now()),
            confirmation: {
                tasks: Math.max(0, Number(mode1.tasks || 0)),
                jobs: Math.max(0, Number(mode1.jobs || 0)),
                activeSeconds: Math.max(0, Number(mode1.active || 0)),
                idleSeconds: Math.max(0, Number(mode1.idle || 0)),
                breakSeconds: mode1Pause.breakSeconds,
                lunchSeconds: mode1Pause.lunchSeconds,
                bioSeconds: Math.max(0, Number(mode1.bio || 0)),
                hbioSeconds: Math.max(0, Number(mode1.hbio || 0))
            },
            coverage: {
                tasks: Math.max(0, Number(mode2.tasks || 0)),
                jobs: Math.max(0, Number(mode2.jobs || 0)),
                activeSeconds: Math.max(0, Number(mode2.active || 0)),
                idleSeconds: Math.max(0, Number(mode2.idle || 0)),
                breakSeconds: mode2Pause.breakSeconds,
                lunchSeconds: mode2Pause.lunchSeconds,
                bioSeconds: Math.max(0, Number(mode2.bio || 0)),
                hbioSeconds: Math.max(0, Number(mode2.hbio || 0))
            },
            legacyUnassigned: {
                activeSeconds: Math.max(0, Number(source.reportTiming?.unassigned?.activeSeconds || 0)),
                idleSeconds: Math.max(0, Number(source.reportTiming?.unassigned?.idleSeconds || 0)),
                breakSeconds: Math.max(0, combinedPause.breakSeconds - mode1Pause.breakSeconds - mode2Pause.breakSeconds),
                lunchSeconds: Math.max(0, combinedPause.lunchSeconds - mode1Pause.lunchSeconds - mode2Pause.lunchSeconds),
                bioSeconds: 0,
                hbioSeconds: 0
            },
            combined: {
                tasks: Math.max(0, Number(mode1.tasks || 0)) + Math.max(0, Number(mode2.tasks || 0)),
                jobs: Math.max(0, Number(mode1.jobs || 0)) + Math.max(0, Number(mode2.jobs || 0)),
                activeSeconds,
                idleSeconds,
                breakSeconds: combinedPause.breakSeconds,
                lunchSeconds: combinedPause.lunchSeconds,
                bioSeconds,
                hbioSeconds,
                efficiency: calculateEfficiency(activeSeconds, idleSeconds)
            },
            overtime: {
                tasks: Math.max(0, Number(overtimeRaw.tasks || 0)),
                jobs: Math.max(0, Number(overtimeRaw.jobs || 0)),
                activeSeconds: Math.max(0, Math.floor(Number(overtimeRaw.activeMs || 0) / 1000)),
                idleSeconds: Math.max(0, Math.floor(Number(overtimeRaw.idleMs || 0) / 1000)),
                breakSeconds: overtimePause.breakSeconds,
                lunchSeconds: overtimePause.lunchSeconds,
                bioSeconds: Math.max(0, Math.floor(Number(overtimeRaw.bioMs || 0) / 1000)),
                hbioSeconds: Math.max(0, Math.floor(Number(overtimeRaw.hbioMs || 0) / 1000)),
                efficiency: calculateEfficiency(
                    Math.max(0, Math.floor(Number(overtimeRaw.activeMs || 0) / 1000)),
                    Math.max(0, Math.floor(Number(overtimeRaw.idleMs || 0) / 1000))
                )
            },
            shift: {
                startedAt: shiftStartedAt,
                endedAt: shiftEndedAt,
                regularEndAt: snapshotSchedule?.regularEndAt || null,
                department: reportDepartment,
                shiftType: snapshotSchedule?.shiftType || 'NON_DAY',
                breakType: snapshotSchedule?.breakType || 'BREAK',
                breakAllowanceMinutes: Number(snapshotSchedule?.breakMinutes || 0),
                lunchAllowanceMinutes: Number(snapshotSchedule?.lunchMinutes || 0),
                intervalCount: Number(snapshotSchedule?.intervalCount || 3)
            }
        };
    } catch {
        return null;
    }
}

// =========================================
// FUNCTION UPLOAD LATEST REPORT
// Search: uploadLatestReport
// Ver 0.1.13 Alpha || 2026-09-27 || JBallados
// Ver 0.1.13 Alpha || 2026-09-27 || JBallados || Dual_Report_Upload_Hotfix
// Ver 0.1.18 Alpha || 2026-09-29 || JBallados || TeamLead_Index_Retry_Fix
// =========================================
async function uploadLatestReport() {

    const reports = fs.readdirSync(reportsFolder)
        .filter(name => /\.xlsx$/i.test(name))
        .map(name => {
            const fullPath = path.join(reportsFolder, name);
            return { name, fullPath, modified: fs.statSync(fullPath).mtimeMs };
        })
        .sort((a, b) => b.modified - a.modified);

    if (reports.length === 0) {
        console.log('[UPLOAD] No Excel reports are available to upload.');
        return { configured: Boolean(loadReportUploadConfig()), ok: false, error: 'NO_REPORTS_FOUND', results: [] };
    }

    const latest = reports[0];
    const stem = latest.name.replace(/\.xlsx$/i, '');
    const logPath = path.join(reportsFolder, stem + '.txt');
    const dateMatch = latest.name.match(/\d{4}-\d{2}-\d{2}/);
    const reportDate = dateMatch ? dateMatch[0] : coverageDate(latest.modified);
    const uploadConfig = loadReportUploadConfig();
    const reportLastName = sanitizeLastName(
        uploadConfig?.lastName
        || latest.name.replace(/_\d{4}-\d{2}-\d{2}(?:_(?:OOS|ENCORD|CWH))?\.xlsx$/i, '')
    );
    const reportSummary = buildReportSummaryFromSignedSnapshot(latest.fullPath, reportDate, reportLastName);

    if (!reportSummary) {
        console.error('[UPLOAD] Cannot safely upload latest report because its signed report summary is unavailable.');
        return {
            configured: Boolean(uploadConfig),
            ok: false,
            error: 'REPORT_SUMMARY_UNAVAILABLE',
            message: 'Regenerate the report or use the pending upload retry so Team Lead indexing stays accurate.',
            results: []
        };
    }

    if (!fs.existsSync(logPath)) {
        console.error('[UPLOAD] Matching TXT log was not found:', logPath);
        const reportResult = await uploadFileToAppsScriptDrive(latest.fullPath, reportDate, 'report', reportSummary);
        return {
            configured: Boolean(loadReportUploadConfig()),
            ok: false,
            partialFailure: reportResult.ok,
            error: 'MATCHING_TXT_LOG_NOT_FOUND',
            results: [
                reportResult,
                {
                    configured: Boolean(loadReportUploadConfig()),
                    ok: false,
                    fileName: path.basename(logPath),
                    fileKind: 'log',
                    error: 'FILE_NOT_FOUND'
                }
            ]
        };
    }

    return uploadDailyReportPairToDrive({
        reportPath: latest.fullPath,
        logPath
    }, reportDate, reportSummary);

}

// =========================================
// FUNCTION STYLE REPORT SHEET
// Search: styleReportSheet
// Ver 0.1.18 Alpha || 2026-09-29 || JBallados
// =========================================
function styleReportSheet(sheet) {

    if (!sheet || sheet.rowCount < 1) return;
    sheet.views = [{ state: 'frozen', ySplit: Math.min(2, Math.max(1, sheet.rowCount > 2 ? 2 : 1)) }];

    const firstCellText = String(sheet.getCell(1, 1).value || '');
    const titleLike = /TRINOVATION|REPORT|DETAILS|OVERTIME|SESSION HISTORY|DIAGNOSTICS/i.test(firstCellText);
    const lastColumn = Math.max(1, sheet.columnCount || 1);
    if (titleLike && lastColumn > 1) {
        sheet.mergeCells(1, 1, 1, lastColumn);
    }

    const title = sheet.getRow(1);
    title.height = 26;
    title.eachCell({ includeEmpty: true }, cell => {
        cell.font = { ...(cell.font || {}), bold: true, color: { argb: 'FFFFFFFF' }, size: 16 };
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1F4E78' } };
        cell.alignment = { vertical: 'middle', horizontal: 'left' };
    });

    if (sheet.name === 'Summary' && String(sheet.getCell(2, 1).value || '').includes('DAILY PRODUCTIVITY REPORT')) {
        sheet.mergeCells(2, 1, 2, Math.max(4, lastColumn));
        const subtitle = sheet.getRow(2);
        subtitle.height = 22;
        subtitle.eachCell({ includeEmpty: true }, cell => {
            cell.font = { ...(cell.font || {}), bold: true, color: { argb: 'FF1F2937' }, size: 12 };
            cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFD9EAF7' } };
            cell.alignment = { vertical: 'middle', horizontal: 'left' };
        });
    }

    for (let rowNumber = 1; rowNumber <= sheet.rowCount; rowNumber++) {
        const row = sheet.getRow(rowNumber);
        const first = String(row.getCell(1).value || '');
        const headerLike = ['Metric', 'Mode', 'Job ID', 'Type'].includes(first);
        if (headerLike) {
            row.height = Math.max(Number(row.height || 0), 20);
        }
        row.eachCell({ includeEmpty: headerLike }, cell => {
            const text = cell.value === null || cell.value === undefined ? '' : String(cell.value);
            cell.alignment = {
                ...(cell.alignment || {}),
                vertical: 'middle',
                wrapText: text.length > 38 || Boolean(cell.alignment?.wrapText)
            };
            if (text.length > 55) row.height = Math.max(Number(row.height || 0), 34);
            if (headerLike) {
                cell.font = { ...(cell.font || {}), bold: true, color: { argb: 'FF1F2937' } };
                cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFEAF2F8' } };
            }
        });
    }

}
// End Modification Ver 0.1.18 Alpha

// =========================================
// FUNCTION AUTO FIT SHEET
// Search: autoFitSheet
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.1.18 Alpha || 2026-09-29 || JBallados
// =========================================
function autoFitSheet(sheet) {

    sheet.columns.forEach(column => {
        let max = 12;
        column.eachCell({ includeEmpty: true }, cell => {
            const value = cell.value === null || cell.value === undefined ? '' : String(cell.value);
            max = Math.max(max, Math.min(36, value.length));
        });
        column.width = max + 2;
    });

}
// End Modification Ver 0.1.18 Alpha

function populateSpecialSessionsSheet(sheet, savedSpecialSessions) {

    sheet.addRow(['BIO / HBIO SESSION HISTORY']);
    sheet.getRow(1).font = { bold: true, size: 16 };
    sheet.addRow(['Type', 'Session', 'Mode', 'Started', 'Ended', 'Duration Used', 'Remaining', 'Ended By']);
    sheet.getRow(2).font = { bold: true };
    const source = savedSpecialSessions || specialSessions;
    const rows = [];
    for (const type of ['BIO', 'HBIO']) {
        const allowance = source?.[type];
        for (const item of allowance?.history || []) {
            rows.push({ type, ...item });
        }
    }
    rows.sort((a, b) => Number(a.startedAt || 0) - Number(b.startedAt || 0));
    for (const item of rows) {
        sheet.addRow([
            item.type,
            item.session,
            Number(item.mode) === 2 ? 'Coverage' : 'Confirmation',
            item.startedAt ? new Date(item.startedAt).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : '',
            item.endedAt ? new Date(item.endedAt).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : '',
            formatDuration(item.duration || 0),
            formatDuration(item.remaining || 0),
            item.endedBy || ''
        ]);
    }
    if (source?.active) {
        const active = source.active;
        sheet.addRow([
            active.type,
            Number(active.sessionIndex || 0) + 1,
            Number(active.mode) === 2 ? 'Coverage' : 'Confirmation',
            active.startedAt ? new Date(active.startedAt).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : '',
            '',
            'ACTIVE',
            formatDuration(active.remainingAtStart || 0),
            'ACTIVE'
        ]);
    }
    if (!rows.length && !source?.active) sheet.addRow(['No BIO/HBIO sessions recorded']);
}

function populatePauseSessionsSheet(sheet, title, sessions, kind, shiftAnchor = shiftStartedAt, department = getShiftDepartment()) {

    const normalizedKind = String(kind || 'BREAK').toUpperCase() === 'LUNCH' ? 'LUNCH' : 'BREAK';
    const rows = (Array.isArray(sessions) ? sessions : [])
        .filter(session => pauseSessionKind(session, shiftAnchor, department) === normalizedKind)
        .sort((a, b) => Number(a?.started || 0) - Number(b?.started || 0));
    sheet.addRow([title]);
    sheet.getRow(1).font = { bold: true, size: 16 };
    sheet.addRow(['Type', 'Mode', 'Started', 'Ended', 'Duration', 'Allowance']);
    sheet.getRow(2).font = { bold: true };
    for (const session of rows) {
        const duration = Math.max(0, Number(session?.duration || 0));
        const row = sheet.addRow([
            normalizedKind === 'LUNCH' ? 'Lunch Break' : 'Break',
            Number(session?.mode) === 2 ? 'Coverage' : Number(session?.mode) === 1 ? 'Confirmation' : 'Unknown',
            session?.started ? new Date(Number(session.started)).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : '',
            session?.ended ? new Date(Number(session.ended)).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : '',
            excelDuration(duration),
            Math.max(0, Number(session?.allowanceMinutes || getShiftBreakMinutes(shiftAnchor, normalizedKind))) + ' minutes'
        ]);
        row.getCell(5).numFmt='[h]:mm:ss';
    }
    if (!rows.length) sheet.addRow(['No ' + (normalizedKind === 'LUNCH' ? 'lunch' : 'break') + ' sessions recorded.']);

}

function pauseSessionDurationInRange(session, rangeStart = null, rangeEnd = null) {
    const recorded = Math.max(0, Number(session?.duration || 0));
    const started = Math.max(0, Number(session?.started || 0));
    const ended = Math.max(started, Number(session?.ended || (started ? started + recorded * 1000 : 0)));
    if (!started || !ended) return recorded;
    if (rangeStart === null && rangeEnd === null) return recorded || Math.max(0, Math.floor((ended - started) / 1000));

    const from = Math.max(started, Number(rangeStart || 0));
    const requestedEnd = rangeEnd === null ? ended : Number(rangeEnd || ended);
    const to = Math.min(ended, requestedEnd);
    const overlap = Math.max(0, Math.floor((to - from) / 1000));
    return recorded > 0 ? Math.min(recorded, overlap) : overlap;
}

function summarizePauseSessions(sessions, shiftAnchor, department, mode = null, rangeStart = null, rangeEnd = null) {
    const summary = { breakSeconds: 0, lunchSeconds: 0 };
    for (const session of Array.isArray(sessions) ? sessions : []) {
        if (mode !== null && Number(session?.mode) !== Number(mode)) continue;
        const seconds = pauseSessionDurationInRange(session, rangeStart, rangeEnd);
        if (!seconds) continue;
        const kind = pauseSessionKind(session, shiftAnchor, department);
        if (kind === 'LUNCH') summary.lunchSeconds += seconds;
        else summary.breakSeconds += seconds;
    }
    return summary;
}


function excelDuration(seconds) {
    return Math.max(0, Number(seconds || 0)) / 86400;
}

function applyIdleCellFill(cell, idleSeconds) {
    const high = Math.max(0, Number(idleSeconds || 0)) > IDLE_HIGHLIGHT_SECONDS;
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: high ? 'FFFFC7CE' : 'FFC6EFCE' } };
    cell.font = { ...(cell.font || {}), color: { argb: high ? 'FF9C0006' : 'FF006100' } };
}

function populateOvertimeSheet(sheet, interval, overtime, reportDate, schedule, endedAt) {
    sheet.addRow(['OVERTIME']);
    sheet.getRow(1).font = { bold: true, size: 16 };
    sheet.addRow(['Report Date', reportDate]);
    sheet.addRow(['OT Started', schedule?.overtimeStartsAt ? new Date(schedule.overtimeStartsAt).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : 'N/A']);
    sheet.addRow(['Shift Ended', endedAt ? new Date(endedAt).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : 'Still Active / Not Recorded']);
    sheet.addRow(['OT Tasks', overtime.tasks || 0]);
    sheet.addRow(['OT Jobs', overtime.jobs || 0]);
    for (const [label, seconds] of [['OT Active', overtime.activeSeconds], ['OT Idle', overtime.idleSeconds], ['OT Break', overtime.breakSeconds], ['OT BIO', overtime.bioSeconds], ['OT HBIO', overtime.hbioSeconds]]) {
        const row = sheet.addRow([label, excelDuration(seconds)]);
        row.getCell(2).numFmt = '[h]:mm:ss';
        if (label === 'OT Idle') applyIdleCellFill(row.getCell(2), seconds);
    }
    const efficiency = calculateEfficiency(overtime.activeSeconds, overtime.idleSeconds);
    const effRow = sheet.addRow(['OT Efficiency', efficiency === null ? 'N/A' : efficiency / 100]);
    if (efficiency !== null) effRow.getCell(2).numFmt = '0.00%';
    sheet.addRow(['OT Tasks / Active Hour', calculateProductivity(overtime.tasks, overtime.activeSeconds) ?? 'N/A']);
    sheet.addRow([]);
    sheet.addRow(['Mode', 'Job ID', 'Tasks', 'Started', 'Finished', 'Idle', 'Active', 'Duration', 'Efficiency']);
    sheet.getRow(sheet.lastRow.number).font = { bold: true };
    for (const job of interval.jobs || []) {
        const eff = calculateEfficiency(job.active, job.idle);
        const row = sheet.addRow([
            Number(job.mode) === 1 ? 'Confirmation' : Number(job.mode) === 2 ? 'Coverage' : 'Unknown',
            job.jobId, job.tasks || 0,
            job.started ? new Date(job.started).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : '',
            job.finished ? new Date(job.finished).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : '',
            excelDuration(job.idle || 0), excelDuration(job.active || 0), excelDuration(job.duration || 0),
            eff === null ? 'N/A' : eff / 100
        ]);
        for (const col of [6,7,8]) row.getCell(col).numFmt = '[h]:mm:ss';
        if (eff !== null) row.getCell(9).numFmt = '0.00%';
        applyIdleCellFill(row.getCell(6), job.idle || 0);
    }
}

function populateDiagnosticsSheet(sheet, info) {
    sheet.addRow(['TRINOVATION AUTO COUNT TRACKER - DIAGNOSTICS']);
    sheet.getRow(1).font = { bold: true, size: 16 };
    const upload = info.uploadSettings || {};
    for (const row of [
        ['Report Date', info.reportDate],
        ['Controller Version', 'v' + info.controllerVersion + '-r' + Number(info.controllerRevision || 0)],
        ['Tampermonkey Source Version', info.tampermonkeyVersion ? 'v' + info.tampermonkeyVersion + '-r' + Number(info.tampermonkeyRevision || 0) : 'Unknown'],
        ['Device Registration', upload.deviceRegistered ? 'Registered' : 'Not Registered'],
        ['Agent ID', upload.agentId || 'Not configured'],
        ['Pod', upload.pod || 'Not configured'],
        ['Report Generated', new Date(info.reportGeneratedAt).toLocaleString('en-US', { timeZone: 'Asia/Manila', hour12: true })],
        ['Shift Started', info.shiftStartedAt ? new Date(info.shiftStartedAt).toLocaleString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : 'Not recorded'],
        ['Shift Ended', info.shiftEndedAt ? new Date(info.shiftEndedAt).toLocaleString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : 'Not recorded'],
        ['Integrity', 'Controller verified at generation'],
        ['Local Retention', LOCAL_RETENTION_DAYS + ' days']
    ]) sheet.addRow(row);
}

// =========================================
// FUNCTION GENERATE REPORT
// Search: generateReport
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// Ver 0.0.7 Alpha || 2026-09-14 || JBallados
// Ver 0.0.10 Alpha || 2026-09-24 || JBallados
// Ver 0.0.11 Alpha || 2026-09-24 || JBallados || Gdrive_Upload
// Ver 0.0.12 Alpha || 2026-09-27 || JBallados
// Ver 0.1.13 Alpha || 2026-09-27 || JBallados || Master integration
// Ver 0.1.15 Alpha || 2026-09-28 || JBallados || AppsScript_Only_Cleanup
// Ver 0.1.16 Alpha || 2026-09-28 || JBallados || Upload_Reporting_TeamLead_Index
// =========================================
async function generateReport(overrideStats, options = {}) {

    if (!overrideStats) settleModeTiming();
    assertStateIntegrity();
    const reportLastName = sanitizeLastName(options.lastName || reportSettings.lastName || process.env.TRACKER_LAST_NAME || (overrideStats ? 'Agent' : ''));
    if (!reportLastName) throw new Error('LAST_NAME_REQUIRED');
    const usedCompleted = overrideStats ? overrideStats.completedJobs || [] : completedJobs;
    const usedMode1Tasks = Number(overrideStats ? overrideStats.totalTaskCompleted || 0 : totalTaskCompleted);
    const usedMode1Jobs = Number(overrideStats ? overrideStats.totalJobsCompleted || 0 : totalJobsCompleted);
    const usedCoverage = overrideStats ? overrideStats.mode2 || {} : {
        taskCompleted: mode2TaskCompleted,
        jobsCompleted: mode2JobsCompleted,
        deletedBoxes: mode2DeletedBoxes,
        emptyAreaConfirmation: mode2EmptyAreaConfirmation,
        emptyAreaNoMatchFound: mode2EmptyAreaNoMatchFound,
        unblurredPerson: mode2UnblurredPerson,
        skippedTask: mode2SkippedTask
    };
    const usedBreaks = overrideStats ? overrideStats.breakSessions || [] : breakSessions;
    const usedLastFinished = overrideStats ? overrideStats.lastJobFinished || null : lastJobFinished;
    const reportTiming = overrideStats ? modeTimingSnapshotFromRaw(overrideStats.modeTiming || {}, overrideStats.legacyUnassignedTiming || {
        activeSeconds: overrideStats.totalActiveSeconds || 0,
        idleSeconds: overrideStats.totalIdleSeconds || 0
    }) : getModeTimingSnapshot();
    const mode1Timing = reportTiming.mode1;
    const mode2Timing = reportTiming.mode2;
    const mode1Metrics = {
        tasks: usedMode1Tasks,
        jobs: usedMode1Jobs,
        active: mode1Timing.activeSeconds,
        idle: mode1Timing.idleSeconds,
        break: mode1Timing.breakSeconds,
        bio: mode1Timing.bioSeconds || 0,
        hbio: mode1Timing.hbioSeconds || 0
    };
    const mode2Metrics = {
        tasks: Number(usedCoverage.taskCompleted || 0),
        jobs: Number(usedCoverage.jobsCompleted || 0),
        active: mode2Timing.activeSeconds,
        idle: mode2Timing.idleSeconds,
        break: mode2Timing.breakSeconds,
        bio: mode2Timing.bioSeconds || 0,
        hbio: mode2Timing.hbioSeconds || 0
    };
    const hasActivity = usedCompleted.length > 0
        || mode1Metrics.tasks > 0
        || mode2Metrics.tasks > 0
        || mode1Metrics.jobs > 0
        || mode2Metrics.jobs > 0
        || reportTiming.combined.activeSeconds > 0
        || reportTiming.combined.idleSeconds > 0
        || reportTiming.combined.breakSeconds > 0
        || reportTiming.combined.bioSeconds > 0
        || reportTiming.combined.hbioSeconds > 0;
    if (!hasActivity) return false;
    const workbook = new ExcelJS.Workbook();
    const now = new Date();
    const reportDate = options.reportDate || overrideStats?.shiftReportDate || overrideStats?.date || shiftReportDate || coverageDate(now.getTime());
    const reportDepartment = normalizeDepartment(
        options.department || overrideStats?.shiftDepartment || shiftDepartment || loadReportUploadConfig()?.department || 'OOS',
        'OOS'
    ) || 'OOS';
    const reportTarget = currentDailyReportTarget(reportLastName, reportDate, reportDepartment);
    prepareReportTargetForOverwrite(reportTarget);
    const reportFileName = path.basename(reportTarget.reportPath);
    const reportPath = reportTarget.reportPath;
    const summarySheet = workbook.addWorksheet('Summary');
    const confirmationSheet = workbook.addWorksheet('Confirmation');
    const coverageSheet = workbook.addWorksheet('Coverage');
    const detailsSheet = workbook.addWorksheet('Job Details');
    const specialSheet = workbook.addWorksheet('BIO-HBIO');
    const interval1Sheet = workbook.addWorksheet('Interval 1');
    const interval2Sheet = workbook.addWorksheet('Interval 2');
    const overtimeSheet = workbook.addWorksheet('Overtime');
    const diagnosticsSheet = workbook.addWorksheet('Diagnostics');
    const usedShiftStartedAt = Number(overrideStats?.shiftStartedAt || shiftStartedAt || 0) || null;
    const reportShiftSchedule = getShiftSchedule(usedShiftStartedAt, reportDepartment);
    const interval3Sheet = reportShiftSchedule?.intervalCount >= 3 ? workbook.addWorksheet('Interval 3') : null;
    const breakSheet = Number(reportShiftSchedule?.breakMinutes || 0) > 0 ? workbook.addWorksheet('Break Log') : null;
    const lunchSheet = Number(reportShiftSchedule?.lunchMinutes || 0) > 0 ? workbook.addWorksheet('Lunch Log') : null;
    const mode1Jobs = usedCompleted.filter(job => Number(job.mode) === 1);
    const mode2Jobs = usedCompleted.filter(job => Number(job.mode) === 2);
    const unknownJobs = usedCompleted.filter(job => Number(job.mode) !== 1 && Number(job.mode) !== 2);
    const combinedTasks = mode1Metrics.tasks + mode2Metrics.tasks;
    const combinedJobs = mode1Metrics.jobs + mode2Metrics.jobs;
    const combinedEfficiency = calculateEfficiency(reportTiming.combined.activeSeconds, reportTiming.combined.idleSeconds);
    const combinedProductivity = calculateProductivity(combinedTasks, reportTiming.combined.activeSeconds);
    summarySheet.addRow(['TRINOVATION AUTO COUNT TRACKER']);
    summarySheet.getRow(1).font = { bold: true, size: 18 };
    summarySheet.addRow(['DAILY PRODUCTIVITY REPORT']);
    summarySheet.getRow(2).font = { bold: true, size: 14 };
    summarySheet.addRow(['Report Date', reportDate]);
    summarySheet.addRow(['Department', reportDepartment]);
    const configuredAppsScript = loadReportUploadConfig();
    const assignedPod = configuredAppsScript?.pod || 'Not configured';
    summarySheet.addRow(['Last Name', reportLastName]);
    summarySheet.addRow(['Assigned Pod', assignedPod]);
    summarySheet.addRow(['Device ID', configuredAppsScript?.deviceId || localDeviceId]);
    summarySheet.addRow(['Upload Credential', configuredAppsScript?.credentialMode || 'Not configured']);
    summarySheet.addRow(['Report File Mode', 'Daily Department file - same Department/date generation overwrites only that Department copy']);
    summarySheet.addRow(['Generated At', new Date(now).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true })]);
    const mode1Pause = summarizePauseSessions(usedBreaks, usedShiftStartedAt, reportDepartment, 1);
    const mode2Pause = summarizePauseSessions(usedBreaks, usedShiftStartedAt, reportDepartment, 2);
    let combinedPause = summarizePauseSessions(usedBreaks, usedShiftStartedAt, reportDepartment);
    if (combinedPause.breakSeconds + combinedPause.lunchSeconds === 0 && reportTiming.combined.breakSeconds > 0) {
        combinedPause = splitPauseSeconds(reportTiming.combined.breakSeconds, usedShiftStartedAt, reportDepartment);
    }
    summarySheet.addRow(['Shift Type', reportShiftSchedule?.shiftType === 'ENCORD' ? 'ENCORD 8-hour Shift' : (reportShiftSchedule?.dayShift ? 'OOS Day Shift' : 'OOS Mid / Night Shift')]);
    summarySheet.addRow(['Pause Type', reportShiftSchedule?.breakType === 'BREAK_AND_LUNCH'
        ? 'Break (30m) + Lunch (60m)'
        : reportShiftSchedule?.breakType === 'LUNCH' ? 'Lunch Break (60m)' : 'Break (30m)']);
    summarySheet.addRow(['Regular Intervals', Number(reportShiftSchedule?.intervalCount || 3)]);
    summarySheet.addRow(['Shift Started', usedShiftStartedAt
        ? new Date(usedShiftStartedAt).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true })
        : 'Not recorded']);
    summarySheet.addRow(['Integrity', 'Controller verified at generation']);
    summarySheet.addRow([]);
    summarySheet.addRow(['Metric', 'Confirmation', 'Coverage', 'Combined']);
    summarySheet.getRow(summarySheet.lastRow.number).font = { bold: true };
    summarySheet.addRow(['Tasks Completed', mode1Metrics.tasks, mode2Metrics.tasks, combinedTasks]);
    summarySheet.addRow(['Jobs Completed', mode1Metrics.jobs, mode2Metrics.jobs, combinedJobs]);
    const pauseSummaryRows = [];
    if (Number(reportShiftSchedule?.breakMinutes || 0) > 0) {
        pauseSummaryRows.push(['Break Time', mode1Pause.breakSeconds, mode2Pause.breakSeconds, combinedPause.breakSeconds]);
    }
    if (Number(reportShiftSchedule?.lunchMinutes || 0) > 0) {
        pauseSummaryRows.push(['Lunch Time', mode1Pause.lunchSeconds, mode2Pause.lunchSeconds, combinedPause.lunchSeconds]);
    }
    const summaryTimeRows = [
        ['Active Time', mode1Metrics.active, mode2Metrics.active, reportTiming.combined.activeSeconds],
        ['Idle Time', mode1Metrics.idle, mode2Metrics.idle, reportTiming.combined.idleSeconds],
        ...pauseSummaryRows,
        ['BIO Time', mode1Metrics.bio, mode2Metrics.bio, reportTiming.combined.bioSeconds || 0],
        ['HBIO Time', mode1Metrics.hbio, mode2Metrics.hbio, reportTiming.combined.hbioSeconds || 0]
    ];
    for (const [label,a,b,c] of summaryTimeRows) {
        const row = summarySheet.addRow([label, excelDuration(a), excelDuration(b), excelDuration(c)]);
        for (const col of [2,3,4]) row.getCell(col).numFmt = '[h]:mm:ss';
        if (label === 'Idle Time') {
            applyIdleCellFill(row.getCell(2), a);
            applyIdleCellFill(row.getCell(3), b);
            applyIdleCellFill(row.getCell(4), c);
        }
    }
    const mode1Efficiency = calculateEfficiency(mode1Metrics.active, mode1Metrics.idle);
    const mode2Efficiency = calculateEfficiency(mode2Metrics.active, mode2Metrics.idle);
    const efficiencyRow = summarySheet.addRow(['Efficiency', mode1Efficiency === null ? 'N/A' : mode1Efficiency/100, mode2Efficiency === null ? 'N/A' : mode2Efficiency/100, combinedEfficiency === null ? 'N/A' : combinedEfficiency/100]);
    for (const col of [2,3,4]) if (typeof efficiencyRow.getCell(col).value === 'number') efficiencyRow.getCell(col).numFmt='0.00%';
    const mode1Productivity = calculateProductivity(mode1Metrics.tasks, mode1Metrics.active);
    const mode2Productivity = calculateProductivity(mode2Metrics.tasks, mode2Metrics.active);
    summarySheet.addRow(['Tasks / Active Hour', mode1Productivity ?? 'N/A', mode2Productivity ?? 'N/A', combinedProductivity ?? 'N/A']);
    summarySheet.addRow(['Productivity Note', '', '', 'Rate is shown only after at least ' + Math.ceil(PRODUCTIVITY_MIN_ACTIVE_SECONDS / 60) + ' minutes of Active time to avoid misleading short-sample projections.']);
    if (reportTiming.unassigned.activeSeconds > 0 || reportTiming.unassigned.idleSeconds > 0) {
        summarySheet.addRow([]);
        summarySheet.addRow(['Legacy / Unassigned Time', '', '', formatDuration(reportTiming.unassigned.activeSeconds + reportTiming.unassigned.idleSeconds)]);
        summarySheet.addRow(['Legacy / Unassigned Note', '', '', 'Older saved time could not be accurately assigned to a mode']);
    }
    summarySheet.addRow([]);
    summarySheet.addRow(['Last Job Finished', usedLastFinished || 'No jobs completed']);
    if (Number(reportShiftSchedule?.breakMinutes || 0) > 0) {
        summarySheet.addRow(['Recorded Break Sessions', formatDuration(combinedPause.breakSeconds)]);
    }
    if (Number(reportShiftSchedule?.lunchMinutes || 0) > 0) {
        summarySheet.addRow(['Recorded Lunch Sessions', formatDuration(combinedPause.lunchSeconds)]);
    }
    const usedOvertime = overrideStats?.overtimeStats
        ? {
            tasks: Number(overrideStats.overtimeStats.tasks || 0),
            jobs: Number(overrideStats.overtimeStats.jobs || 0),
            activeSeconds: Math.floor(Number(overrideStats.overtimeStats.activeMs || 0) / 1000),
            idleSeconds: Math.floor(Number(overrideStats.overtimeStats.idleMs || 0) / 1000),
            breakSeconds: Math.floor(Number(overrideStats.overtimeStats.breakMs || 0) / 1000),
            bioSeconds: Math.floor(Number(overrideStats.overtimeStats.bioMs || 0) / 1000),
            hbioSeconds: Math.floor(Number(overrideStats.overtimeStats.hbioMs || 0) / 1000)
        } : overtimeTimingSnapshot();
    summarySheet.addRow([]);
    summarySheet.addRow(['OVERTIME SUMMARY']);
    summarySheet.getRow(summarySheet.lastRow.number).font = { bold: true };
    summarySheet.addRow(['OT Tasks', usedOvertime.tasks]);
    summarySheet.addRow(['OT Jobs', usedOvertime.jobs]);
    const otActiveRow = summarySheet.addRow(['OT Active', excelDuration(usedOvertime.activeSeconds)]);
    const otIdleRow = summarySheet.addRow(['OT Idle', excelDuration(usedOvertime.idleSeconds)]);
    otActiveRow.getCell(2).numFmt='[h]:mm:ss';
    otIdleRow.getCell(2).numFmt='[h]:mm:ss';
    applyIdleCellFill(otIdleRow.getCell(2), usedOvertime.idleSeconds);
    let overtimePause = summarizePauseSessions(
        usedBreaks,
        usedShiftStartedAt,
        reportDepartment,
        null,
        reportShiftSchedule?.overtimeStartsAt || null,
        Number(overrideStats?.shiftEndedAt || shiftEndedAt || Date.now())
    );
    if (overtimePause.breakSeconds + overtimePause.lunchSeconds === 0 && usedOvertime.breakSeconds > 0) {
        overtimePause = splitPauseSeconds(usedOvertime.breakSeconds, usedShiftStartedAt, reportDepartment);
    }
    if (Number(reportShiftSchedule?.breakMinutes || 0) > 0) {
        const otBreakRow = summarySheet.addRow(['OT Break', excelDuration(overtimePause.breakSeconds)]);
        otBreakRow.getCell(2).numFmt='[h]:mm:ss';
    }
    if (Number(reportShiftSchedule?.lunchMinutes || 0) > 0) {
        const otLunchRow = summarySheet.addRow(['OT Lunch', excelDuration(overtimePause.lunchSeconds)]);
        otLunchRow.getCell(2).numFmt='[h]:mm:ss';
    }
    const otEff = calculateEfficiency(usedOvertime.activeSeconds, usedOvertime.idleSeconds);
    const otEffRow = summarySheet.addRow(['OT Efficiency', otEff === null ? 'N/A' : otEff/100]);
    if (otEff !== null) otEffRow.getCell(2).numFmt='0.00%';
    summarySheet.addRow(['OT Tasks / Active Hour', calculateProductivity(usedOvertime.tasks, usedOvertime.activeSeconds) ?? 'N/A']);
    populateModeSheet(confirmationSheet, 'CONFIRMATION REPORT', mode1Jobs, mode1Metrics, reportDate);
    populateModeSheet(coverageSheet, 'COVERAGE REPORT', mode2Jobs, mode2Metrics, reportDate, usedCoverage);
    populateSpecialSessionsSheet(specialSheet, overrideStats?.specialSessions || specialSessions);
    if (breakSheet) populatePauseSessionsSheet(breakSheet, 'BREAK LOG', usedBreaks, 'BREAK', usedShiftStartedAt, reportDepartment);
    if (lunchSheet) populatePauseSessionsSheet(lunchSheet, 'LUNCH BREAK LOG', usedBreaks, 'LUNCH', usedShiftStartedAt, reportDepartment);
    detailsSheet.addRow(['JOB DETAILS']);
    detailsSheet.getRow(1).font = { bold: true, size: 16 };
    detailsSheet.addRow(['Mode', 'Job ID', 'Tasks', 'Started', 'Finished', 'Idle', reportShiftSchedule?.breakType === 'BREAK_AND_LUNCH' ? 'Pause' : (reportShiftSchedule?.breakType === 'LUNCH' ? 'Lunch' : 'Break'), 'BIO', 'HBIO', 'Active', 'Duration', 'Efficiency']);
    detailsSheet.getRow(2).font = { bold: true };
    [...usedCompleted].sort((a, b) => Number(a.started || 0) - Number(b.started || 0)).forEach(job => {
        const modeLabel = Number(job.mode) === 1 ? 'Confirmation' : Number(job.mode) === 2 ? 'Coverage' : 'Unknown';
        const efficiency = calculateEfficiency(job.active, job.idle);
        const row = detailsSheet.addRow([
            modeLabel,
            job.jobId,
            job.tasks || 0,
            job.started ? new Date(job.started).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : '',
            job.finished ? new Date(job.finished).toLocaleTimeString('en-US', { timeZone: 'Asia/Manila', hour12: true }) : '',
            excelDuration(job.idle || 0),
            excelDuration(job.break || 0),
            excelDuration(job.bio || 0),
            excelDuration(job.hbio || 0),
            excelDuration(job.active || 0),
            excelDuration(job.duration || 0),
            efficiency === null ? 'N/A' : efficiency / 100
        ]);
        for (const col of [6,7,8,9,10,11]) row.getCell(col).numFmt='[h]:mm:ss';
        if (efficiency !== null) row.getCell(12).numFmt='0.00%';
        applyIdleCellFill(row.getCell(6), job.idle || 0);
    });
    if (unknownJobs.length > 0) {
        detailsSheet.addRow([]);
        detailsSheet.addRow(['Note', unknownJobs.length + ' legacy job(s) have no saved mode and are shown as Unknown.']);
    }
    const intervalGroups = buildReportIntervalGroups(usedCompleted, overrideStats || null, usedShiftStartedAt);
    const scheduleForReport = reportShiftSchedule;
    populateIntervalSheet(interval1Sheet, intervalGroups.interval1, SHIFT.interval1, reportDate, 'Interval 1', scheduleForReport);
    populateIntervalSheet(interval2Sheet, intervalGroups.interval2, SHIFT.interval2, reportDate, 'Interval 2', scheduleForReport);
    if (interval3Sheet) populateIntervalSheet(interval3Sheet, intervalGroups.interval3, SHIFT.interval3, reportDate, 'Interval 3', scheduleForReport);
    populateOvertimeSheet(overtimeSheet, intervalGroups.overtime, usedOvertime, reportDate, scheduleForReport, Number(overrideStats?.shiftEndedAt || shiftEndedAt || 0));
    populateDiagnosticsSheet(diagnosticsSheet, {
        reportDate,
        reportGeneratedAt: now.getTime(),
        controllerVersion: CONTROLLER_VERSION,
        controllerRevision: CONTROLLER_RELEASE_REVISION,
        tampermonkeyVersion: getTampermonkeyScriptInfo().version || 'Unknown',
        tampermonkeyRevision: getTampermonkeyScriptInfo().revision || 0,
        uploadSettings: getPublicReportUploadSettings(),
        shiftStartedAt: Number(overrideStats?.shiftStartedAt || shiftStartedAt || 0),
        shiftEndedAt: Number(overrideStats?.shiftEndedAt || shiftEndedAt || 0)
    });
    const reportSheets = [summarySheet, confirmationSheet, coverageSheet, detailsSheet, specialSheet, breakSheet, lunchSheet, interval1Sheet, interval2Sheet, interval3Sheet, overtimeSheet, diagnosticsSheet].filter(Boolean);
    reportSheets.forEach(sheet => {
        styleReportSheet(sheet);
        autoFitSheet(sheet);
    });
    const protectionPassword = reportProtectionPassword();
    for (const sheet of reportSheets) {
        await sheet.protect(protectionPassword, {
            selectLockedCells: true,
            selectUnlockedCells: true,
            formatCells: false,
            formatColumns: false,
            formatRows: false,
            insertColumns: false,
            insertRows: false,
            deleteColumns: false,
            deleteRows: false,
            sort: false,
            autoFilter: false,
            pivotTables: false,
            spinCount: 10000
        });
    }
    await workbook.xlsx.writeFile(reportPath);
    copyDailyLogSnapshot(reportTarget.logPath, reportDate);
    const sourceSnapshot = {
        reportDate,
        reportLastName,
        shiftDepartment: reportDepartment,
        shiftStartedAt: Number(overrideStats?.shiftStartedAt || shiftStartedAt || 0) || null,
        mode1Metrics,
        mode2Metrics,
        coverage: usedCoverage,
        reportTiming,
        completedJobs: usedCompleted,
        breakSessions: usedBreaks,
        specialSessions: overrideStats?.specialSessions || specialSessions,
        overtimeStats: overrideStats?.overtimeStats || overtimeStats,
        shiftReportDate: overrideStats?.shiftReportDate || shiftReportDate,
        shiftEndedAt: Number(overrideStats?.shiftEndedAt || shiftEndedAt || 0) || null,
        lastJobFinished: usedLastFinished
    };
    writeSignedSourceSnapshot(reportTarget, reportDate, sourceSnapshot);
    createReportIntegrityManifest(reportTarget, reportDate, sourceSnapshot);
    const verification = verifyGeneratedReport(reportPath);
    if (!verification.ok) throw new Error('REPORT_INTEGRITY_VERIFICATION_FAILED');
    markReportBundleReadOnly(reportTarget);
    const appsScriptConfig = loadReportUploadConfig();
    let appsScriptUpload = null;
    let resolvedDrive = {
        skipped: true,
        mode: 'apps-script',
        error: 'DEVICE_UPLOAD_NOT_CONFIGURED',
        message: 'Report was generated locally. Register this device in Settings to enable Drive upload.'
    };
    const reportSummary = {
        schemaVersion: 2,
        reportDate,
        lastName: reportLastName,
        generatedAt: now.getTime(),
        confirmation: {
            tasks: mode1Metrics.tasks,
            jobs: mode1Metrics.jobs,
            activeSeconds: mode1Metrics.active,
            idleSeconds: mode1Metrics.idle,
            breakSeconds: mode1Pause.breakSeconds,
            lunchSeconds: mode1Pause.lunchSeconds,
            bioSeconds: mode1Metrics.bio,
            hbioSeconds: mode1Metrics.hbio
        },
        coverage: {
            tasks: mode2Metrics.tasks,
            jobs: mode2Metrics.jobs,
            activeSeconds: mode2Metrics.active,
            idleSeconds: mode2Metrics.idle,
            breakSeconds: mode2Pause.breakSeconds,
            lunchSeconds: mode2Pause.lunchSeconds,
            bioSeconds: mode2Metrics.bio,
            hbioSeconds: mode2Metrics.hbio
        },
        legacyUnassigned: {
            activeSeconds: reportTiming.unassigned.activeSeconds || 0,
            idleSeconds: reportTiming.unassigned.idleSeconds || 0,
            breakSeconds: Math.max(0, combinedPause.breakSeconds - mode1Pause.breakSeconds - mode2Pause.breakSeconds),
            lunchSeconds: Math.max(0, combinedPause.lunchSeconds - mode1Pause.lunchSeconds - mode2Pause.lunchSeconds),
            bioSeconds: 0,
            hbioSeconds: 0
        },
        combined: {
            tasks: combinedTasks,
            jobs: combinedJobs,
            activeSeconds: reportTiming.combined.activeSeconds,
            idleSeconds: reportTiming.combined.idleSeconds,
            breakSeconds: combinedPause.breakSeconds,
            lunchSeconds: combinedPause.lunchSeconds,
            bioSeconds: reportTiming.combined.bioSeconds || 0,
            hbioSeconds: reportTiming.combined.hbioSeconds || 0,
            efficiency: combinedEfficiency
        },
        overtime: {
            tasks: usedOvertime.tasks,
            jobs: usedOvertime.jobs,
            activeSeconds: usedOvertime.activeSeconds,
            idleSeconds: usedOvertime.idleSeconds,
            breakSeconds: overtimePause.breakSeconds,
            lunchSeconds: overtimePause.lunchSeconds,
            bioSeconds: usedOvertime.bioSeconds,
            hbioSeconds: usedOvertime.hbioSeconds,
            efficiency: calculateEfficiency(usedOvertime.activeSeconds, usedOvertime.idleSeconds)
        },
        shift: {
            startedAt: Number(overrideStats?.shiftStartedAt || shiftStartedAt || 0) || null,
            endedAt: Number(overrideStats?.shiftEndedAt || shiftEndedAt || 0) || null,
            regularEndAt: reportShiftSchedule?.regularEndAt || null,
            department: reportDepartment,
            shiftType: reportShiftSchedule?.shiftType || 'NON_DAY',
            breakType: reportShiftSchedule?.breakType || 'BREAK',
            breakAllowanceMinutes: Number(reportShiftSchedule?.breakMinutes || 0),
            lunchAllowanceMinutes: Number(reportShiftSchedule?.lunchMinutes || 0),
            intervalCount: Number(reportShiftSchedule?.intervalCount || 3)
        }
    };
    if (appsScriptConfig) {
        appsScriptUpload = await uploadDailyReportPairToDrive(reportTarget, reportDate, reportSummary);
        resolvedDrive = {
            ok: appsScriptUpload.ok,
            mode: 'apps-script',
            partialFailure: appsScriptUpload.partialFailure,
            results: appsScriptUpload.results,
            error: appsScriptUpload.ok
                ? null
                : appsScriptUpload.partialFailure
                    ? 'APPS_SCRIPT_PARTIAL_UPLOAD'
                    : 'APPS_SCRIPT_UPLOAD_FAILED',
            message: appsScriptUpload.ok
                ? 'Apps Script updated the daily XLSX report and TXT log.'
                : appsScriptUpload.partialFailure
                    ? 'Only one of the daily XLSX/TXT files uploaded successfully.'
                    : 'Apps Script could not upload the daily XLSX/TXT files.'
        };
    }
    logWithTimestamp('REPORT GENERATED + VERIFIED: ' + reportFileName);
    if (appsScriptUpload?.configured) {
        if (appsScriptUpload.ok) {
            logWithTimestamp('APPS SCRIPT REPORT+LOG UPLOAD COMPLETE: ' + reportFileName + ' + ' + path.basename(reportTarget.logPath));
        } else if (appsScriptUpload.partialFailure) {
            const failedFiles = appsScriptUpload.results.filter(item => !item.ok).map(item => item.fileName).join(', ');
            logWithTimestamp('APPS SCRIPT PARTIAL UPLOAD FAILURE: ' + failedFiles);
        } else {
            logWithTimestamp('APPS SCRIPT REPORT+LOG UPLOAD FAILED: ' + reportFileName);
        }
    } else if (resolvedDrive.ok === false) {
        logWithTimestamp('GOOGLE DRIVE UPLOAD FAILED: ' + (resolvedDrive.error || 'One or more files failed to upload.'));
    } else if (resolvedDrive.ok === true) {
        logWithTimestamp('GOOGLE DRIVE UPLOAD COMPLETE: ' + reportFileName);
    }
    lastReportStatus = {
        state: resolvedDrive.ok === true ? 'VERIFIED' : resolvedDrive.ok === false ? 'PENDING' : 'LOCAL',
        generatedAt: Date.now(),
        reportFileName,
        drive: {
            ok: resolvedDrive.ok === true,
            mode: resolvedDrive.mode || 'apps-script',
            error: resolvedDrive.error || null
        }
    };
    return {
        success: true,
        reportFileName,
        reportPath,
        logFileName: path.basename(reportTarget.logPath),
        localSnapshotFileName: path.basename(reportTarget.snapshotPath),
        localIntegrityFileName: path.basename(reportTarget.integrityPath),
        assignedPod: configuredAppsScript?.pod || null,
        verification,
        appsScriptUpload,
        drive: resolvedDrive
    };

}

// =========================================
// FUNCTION RESET ALL TIME TASKS
// Search: resetAllTimeTasks
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function resetAllTimeTasks(reason) {

    allTimeTasks = 0;
    resetCoverageCounters(false);
    saveStats();
    const note = reason ? "AUTO RESET: " + reason : "AUTO RESET: Scheduled";
    logWithTimestamp(note);
    lastLogTimePH = "AUTO RESET";
    scheduleDashboard();
    broadcastToBrowser("reset_counters");

}
