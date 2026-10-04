#!/bin/bash
# Auto Tracker macOS installer / launcher
# Ver 0.1.16 Alpha || 2026-09-28 || JBallados || macOS_Installer_ErrorLogging
# Ver 0.1.20 Alpha || 2026-10-02 || JBallados || Friendly_FirstSetup_PathRecovery
# Ver 0.1.21 Alpha || 2026-10-03 || JBallados || Node_Readiness_TM_Validation
# Ver 0.1.21 Rev2 || 2026-10-03 || JBallados || Flexible_Source_Discovery
# Ver 0.1.21 Rev2 || 2026-10-03 || JBallados || Safe_Port_Reuse_Update_Preservation_FastSetup

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$SCRIPT_DIR"

# Finder-launched .command files can receive a smaller PATH than Terminal.
# Add the normal Apple Silicon and Intel Homebrew locations without disabling
# any macOS security controls.
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

if [[ -f "$TARGET_DIR/frontend/tampermonkey/Auto_Tracker.user.js" ]]; then
    export TRACKER_TAMPERMONKEY_SOURCE="$TARGET_DIR/frontend/tampermonkey/Auto_Tracker.user.js"
elif [[ -f "$TARGET_DIR/Tampermonkey_Modifications/TamperMonkey Mods" ]]; then
    export TRACKER_TAMPERMONKEY_SOURCE="$TARGET_DIR/Tampermonkey_Modifications/TamperMonkey Mods"
elif [[ -f "$TARGET_DIR/TamperMonkey Mods" ]]; then
    export TRACKER_TAMPERMONKEY_SOURCE="$TARGET_DIR/TamperMonkey Mods"
else
    export TRACKER_TAMPERMONKEY_SOURCE="$TARGET_DIR/Tampermonkey_Modifications/TamperMonkey Mods"
fi
EXPECTED_CONTROLLER_VERSION="0.1.21"
EXPECTED_CONTROLLER_REVISION=2
PACKAGED_CONTROLLER="$TARGET_DIR/backend/node/server.js"
RUNTIME_CONTROLLER="$TARGET_DIR/server.js"
BATCH_FILE="$TARGET_DIR/Auto_Tracker.bat"
export TRACKER_CONTROLLER_SOURCE="$RUNTIME_CONTROLLER"

cd "$TARGET_DIR" || exit 1
mkdir -p "$TARGET_DIR/Logs" "$TARGET_DIR/Backups" "$TARGET_DIR/Reports"

DATE_KEY="$(date '+%Y-%m-%d')"
STAMP="$(date '+%Y%m%d_%H%M%S')"
STARTUP_ERROR_LOG="$TARGET_DIR/Logs/macos_startup_errors_$DATE_KEY.log"
RUNTIME_ERROR_LOG="$TARGET_DIR/Logs/macos_runtime_errors_$DATE_KEY.log"

log() {
    printf '%s\n' "$*" | tee -a "$RUNTIME_ERROR_LOG"
}

fail() {
    log "[ERROR] $*"
    log "[INFO] Error logs: $TARGET_DIR/Logs"
    if [[ "${TRACKER_NONINTERACTIVE:-0}" != "1" ]]; then
        printf '\nPress Enter to close...'
        read -r _ || true
    fi
    exit 1
}

read_controller_identity() {
    local file="$1"
    local version revision
    version="$(sed -nE "s/^const[[:space:]]+CONTROLLER_VERSION[[:space:]]*=[[:space:]]*['\"]([^'\"]+)['\"];.*/\1/p" "$file" 2>/dev/null | head -n 1)"
    revision="$(sed -nE 's/^const[[:space:]]+CONTROLLER_SOURCE_RELEASE_REVISION[[:space:]]*=[[:space:]]*([0-9]+);.*/\1/p' "$file" 2>/dev/null | head -n 1)"
    [[ -n "$version" ]] || return 1
    printf '%s|%s\n' "$version" "${revision:-0}"
}

version_revision_ge() {
    local current_version="$1" current_revision="$2" required_version="$3" required_revision="$4"
    local c1=0 c2=0 c3=0 r1=0 r2=0 r3=0
    IFS='.' read -r c1 c2 c3 <<<"$current_version"
    IFS='.' read -r r1 r2 r3 <<<"$required_version"
    c1="${c1:-0}"; c2="${c2:-0}"; c3="${c3:-0}"
    r1="${r1:-0}"; r2="${r2:-0}"; r3="${r3:-0}"
    if (( c1 != r1 )); then (( c1 > r1 )); return; fi
    if (( c2 != r2 )); then (( c2 > r2 )); return; fi
    if (( c3 != r3 )); then (( c3 > r3 )); return; fi
    (( ${current_revision:-0} >= ${required_revision:-0} ))
}

controller_file_is_same_or_newer() {
    local candidate="$1" reference="$2"
    local candidate_identity reference_identity cv cr rv rr
    candidate_identity="$(read_controller_identity "$candidate")" || return 1
    reference_identity="$(read_controller_identity "$reference")" || return 1
    IFS='|' read -r cv cr <<<"$candidate_identity"
    IFS='|' read -r rv rr <<<"$reference_identity"
    version_revision_ge "$cv" "$cr" "$rv" "$rr"
}

port_9000_is_open() {
    node -e 'const net=require("net");let done=false;const finish=c=>{if(done)return;done=true;try{s.destroy()}catch{};process.exit(c)};const s=net.connect({host:"127.0.0.1",port:9000});s.on("connect",()=>finish(0));s.on("error",()=>finish(1));setTimeout(()=>finish(1),900);' >/dev/null 2>&1
}

probe_running_tracker() {
    node -e 'const http=require("http");const req=http.get("http://127.0.0.1:9000/stats",res=>{let d="";res.setEncoding("utf8");res.on("data",c=>d+=c);res.on("end",()=>{try{const s=JSON.parse(d);if(!s.controllerVersion)process.exit(2);process.stdout.write(String(s.controllerVersion)+"|"+String(Number(s.controllerRevision||0))+"|"+(s.shiftStarted?"1":"0"))}catch{process.exit(2)}})});req.setTimeout(1500,()=>req.destroy(new Error("timeout")));req.on("error",()=>process.exit(2));' 2>/dev/null
}

find_port_9000_pid() {
    if command -v lsof >/dev/null 2>&1; then
        lsof -ti tcp:9000 2>/dev/null | head -n 1 || true
    fi
}

refresh_runtime_path() {
    hash -r 2>/dev/null || true

    if command -v node >/dev/null 2>&1 && node --version >/dev/null 2>&1; then
        return 0
    fi

    for dir in /opt/homebrew/bin /usr/local/bin; do
        if [[ -x "$dir/node" ]]; then
            export PATH="$dir:$PATH"
            hash -r 2>/dev/null || true
            command -v node >/dev/null 2>&1 && node --version >/dev/null 2>&1 && return 0
        fi
    done

    # Support an existing NVM install. Nothing is installed or modified here.
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        # shellcheck disable=SC1090
        . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1 || true
        hash -r 2>/dev/null || true
    fi

    command -v node >/dev/null 2>&1 && node --version >/dev/null 2>&1
}

wait_for_node_ready() {
    local attempt
    for attempt in 1 2 3 4 5; do
        if refresh_runtime_path; then
            return 0
        fi
        echo "[INFO] Node.js is not visible yet. Re-checking... ($attempt/5)"
        sleep 2
    done
    return 1
}

ensure_node() {
    if refresh_runtime_path; then
        return 0
    fi

    echo "[STEP 1/5] Node.js is required but was not detected."
    echo "[INFO] Auto Tracker will not disable Gatekeeper or macOS security settings."
    echo

    if command -v brew >/dev/null 2>&1; then
        read -r -p "Install Node.js with your existing Homebrew installation now? [Y/n]: " answer
        case "${answer:-Y}" in
            y|Y|yes|YES)
                echo "[INFO] Installing Node.js with Homebrew..."
                brew install node 2>>"$STARTUP_ERROR_LOG" || {
                    echo "[WARN] Homebrew could not install Node.js. Using the official Node.js page instead."
                }
                echo "[INFO] Waiting for Node.js to become available in this same installer session..."
                wait_for_node_ready && return 0
                ;;
            *)
                echo "[INFO] Homebrew installation skipped."
                ;;
        esac
    else
        echo "[INFO] Homebrew was not found. That is okay; it is not required."
    fi

    echo
    echo "[INFO] Opening the official Node.js download page."
    echo "[INFO] Install the LTS package, keep this window open, then return here."
    open "https://nodejs.org/en/download" >/dev/null 2>&1 || true

    while true; do
        read -r -p "After Node.js finishes installing, press R to re-check or Q to quit: " choice
        case "${choice^^}" in
            R)
                if refresh_runtime_path; then
                    echo "[OK] Node.js is available. Continuing setup..."
                    return 0
                fi
                echo "[WARN] Node.js is still not detected. Make sure the installer finished, then try R again."
                ;;
            Q)
                return 1
                ;;
            *)
                echo "Please enter R or Q."
                ;;
        esac
    done
}

echo "=================================================="
echo " AUTO TRACKER v0.1.21-r2 - macOS"
echo "=================================================="
echo
echo "[INFO] Safe setup: no Gatekeeper bypass, no certificate bypass, no hidden credential changes."
echo

if [[ ! -w "$TARGET_DIR" ]]; then
    fail "This folder is not writable. Move the Auto Tracker folder to Downloads, Documents, or another folder you can edit, then try again."
fi

ensure_node || fail "Node.js setup was not completed."
command -v npm >/dev/null 2>&1 || fail "npm was not found. Repair the Node.js installation."

echo "[OK] Node.js: $(node --version 2>/dev/null || echo unknown)"
echo "[OK] npm: $(npm --version 2>/dev/null || echo unknown)"

if [[ ! -f "$TARGET_DIR/package.json" ]]; then
    cat > "$TARGET_DIR/package.json" <<'JSON'
{
  "name": "trinovation-auto-count-tracker",
  "private": true,
  "dependencies": {
    "exceljs": "4.4.0"
  }
}
JSON
fi

echo "[STEP 2/5] Preparing files and backup..."
BACKUP_DIR="$TARGET_DIR/Backups/$STAMP"
mkdir -p "$BACKUP_DIR"
for item in server.js stats.json mode2_stats.json .tracker-integrity-key .tracker-integrity.json .tracker-report-settings.json .tracker-tampermonkey-identity.json .tracker-device-id report-upload-config.json; do
    if [[ -f "$TARGET_DIR/$item" ]]; then
        cp -f "$TARGET_DIR/$item" "$BACKUP_DIR/$item" 2>>"$STARTUP_ERROR_LOG" || true
    fi
done
for folder in Logs Reports Integrity_Quarantine Tampermonkey_Modifications; do
    if [[ -d "$TARGET_DIR/$folder" ]]; then
        cp -R "$TARGET_DIR/$folder" "$BACKUP_DIR/" 2>>"$STARTUP_ERROR_LOG" || true
    fi
done

echo "[INFO] Backup created: $BACKUP_DIR"

PACKAGED_VALID=0
RUNTIME_VALID=0
if [[ -f "$PACKAGED_CONTROLLER" ]] && node --check "$PACKAGED_CONTROLLER" >/dev/null 2>>"$STARTUP_ERROR_LOG"; then
    PACKAGED_VALID=1
fi
if [[ -f "$RUNTIME_CONTROLLER" ]] && node --check "$RUNTIME_CONTROLLER" >/dev/null 2>>"$STARTUP_ERROR_LOG"; then
    RUNTIME_VALID=1
fi

if [[ "$RUNTIME_VALID" == "1" && "$PACKAGED_VALID" == "1" ]] && controller_file_is_same_or_newer "$RUNTIME_CONTROLLER" "$PACKAGED_CONTROLLER"; then
    echo "[OK] Existing runtime controller is same/newer than the packaged source. Keeping it."
    export TRACKER_CONTROLLER_SOURCE="$PACKAGED_CONTROLLER"
elif [[ "$PACKAGED_VALID" == "1" ]]; then
    cp -f "$PACKAGED_CONTROLLER" "$RUNTIME_CONTROLLER" 2>>"$STARTUP_ERROR_LOG" || fail "Could not copy backend/node/server.js."
    echo "[OK] Packaged controller copied to runtime."
    export TRACKER_CONTROLLER_SOURCE="$PACKAGED_CONTROLLER"
elif [[ "$RUNTIME_VALID" == "1" ]]; then
    echo "[OK] Existing runtime controller is valid. Keeping it."
    export TRACKER_CONTROLLER_SOURCE="$RUNTIME_CONTROLLER"
elif [[ -f "$BATCH_FILE" ]]; then
    TMP_CONTROLLER="$TARGET_DIR/.server.js.extract.$"
    if ! awk 'BEGIN{found=0} {sub(/\r$/, ""); if(found){print; next} if($0=="___JS_START___"){found=1}} END{if(!found) exit 2}' "$BATCH_FILE" >"$TMP_CONTROLLER"; then
        rm -f "$TMP_CONTROLLER"
        fail "Embedded JavaScript start marker was not found in Auto_Tracker.bat."
    fi
    [[ -s "$TMP_CONTROLLER" ]] || { rm -f "$TMP_CONTROLLER"; fail "Embedded JavaScript section is empty."; }
    node --check "$TMP_CONTROLLER" >/dev/null 2>>"$STARTUP_ERROR_LOG" || { rm -f "$TMP_CONTROLLER"; fail "Embedded controller fallback failed syntax validation."; }
    mv -f "$TMP_CONTROLLER" "$RUNTIME_CONTROLLER" || fail "Could not install the embedded controller fallback."
    export TRACKER_CONTROLLER_SOURCE="$RUNTIME_CONTROLLER"
    echo "[INFO] Embedded compatibility backend extracted from Auto_Tracker.bat."
else
    fail "No valid controller source was found. Expected backend/node/server.js, server.js, or Auto_Tracker.bat fallback."
fi

echo "[STEP 3/5] Checking Node dependencies..."
if node -e "require('exceljs')" >/dev/null 2>>"$STARTUP_ERROR_LOG"; then
    echo "[OK] Existing dependencies are already ready."
else
    echo "[INFO] ExcelJS is not ready yet. First-time setup may take a few minutes on a slower connection."
    echo "[INFO] Using the fastest safe npm path available..."
    FIRST_NPM_FAILED=0
    if [[ -f "$TARGET_DIR/package-lock.json" ]]; then
        npm ci --omit=optional --prefer-offline --no-audit --no-fund --progress=false >>"$RUNTIME_ERROR_LOG" 2>>"$STARTUP_ERROR_LOG" || FIRST_NPM_FAILED=1
    else
        npm install --save-exact exceljs@4.4.0 --omit=optional --prefer-offline --no-audit --no-fund --progress=false >>"$RUNTIME_ERROR_LOG" 2>>"$STARTUP_ERROR_LOG" || FIRST_NPM_FAILED=1
    fi
    if [[ "$FIRST_NPM_FAILED" == "1" ]]; then
        echo "[WARN] Fast dependency install failed. Retrying ExcelJS once..."
        sleep 2
        npm install --save-exact exceljs@4.4.0 --omit=optional --no-audit --no-fund --progress=false >>"$RUNTIME_ERROR_LOG" 2>>"$STARTUP_ERROR_LOG" || fail "ExcelJS install failed after retry."
    fi
fi

echo "[STEP 4/5] Validating controller and Tampermonkey source..."
node -e "require('exceljs')" >/dev/null 2>>"$STARTUP_ERROR_LOG" || fail "ExcelJS verification failed."
node --check "$TARGET_DIR/server.js" 2>>"$STARTUP_ERROR_LOG" || fail "Controller syntax validation failed."
[[ -f "$TRACKER_TAMPERMONKEY_SOURCE" ]] || fail "Tampermonkey source was not found."
node --check "$TRACKER_TAMPERMONKEY_SOURCE" 2>>"$STARTUP_ERROR_LOG" || fail "Tampermonkey userscript syntax validation failed."
echo "[OK] Controller/userscript validation: PASSED"

REUSE_RUNNING_CONTROLLER=0
if port_9000_is_open; then
    RUNNING_TRACKER="$(probe_running_tracker || true)"
    PORT_PID="$(find_port_9000_pid)"
    if [[ -z "$RUNNING_TRACKER" ]]; then
        fail "Port 9000 is in use by an unverified application. Auto Tracker will not terminate it."
    fi

    IFS='|' read -r RUNNING_VERSION RUNNING_REVISION RUNNING_SHIFT <<<"$RUNNING_TRACKER"
    echo "[WARN] Verified Auto Tracker detected on port 9000: v$RUNNING_VERSION-r$RUNNING_REVISION${PORT_PID:+ (PID $PORT_PID)}."

    if version_revision_ge "$RUNNING_VERSION" "$RUNNING_REVISION" "$EXPECTED_CONTROLLER_VERSION" "$EXPECTED_CONTROLLER_REVISION"; then
        REUSE_RUNNING_CONTROLLER=1
        echo "[OK] Same/newer Auto Tracker is already running. Reusing it instead of starting a duplicate."
    else
        if [[ "$RUNNING_SHIFT" == "1" ]]; then
            fail "The older Auto Tracker has an active shift. End the shift normally before replacing/restarting the controller."
        fi
        [[ -n "$PORT_PID" ]] || fail "Older Auto Tracker was verified, but its PID could not be determined safely."
        read -r -p "Stop the older Auto Tracker and start Rev2? [Y/n]: " answer
        case "${answer:-Y}" in
            y|Y|yes|YES)
                kill "$PORT_PID" 2>>"$STARTUP_ERROR_LOG" || fail "Could not stop the older Auto Tracker PID $PORT_PID."
                for _ in 1 2 3 4 5 6 7 8 9 10; do
                    port_9000_is_open || break
                    sleep 1
                done
                port_9000_is_open && fail "The older Auto Tracker did not release port 9000 after 10 seconds."
                echo "[OK] Older Auto Tracker stopped safely."
                ;;
            *)
                fail "Port 9000 must be free before Rev2 can replace the older tracker."
                ;;
        esac
    fi
fi

echo "[STEP 5/5] Setup checks completed."
echo
echo "[OK] Controller validation passed."
echo "[INFO] First-time device setup:"
echo "       1. Open the labeling tool."
echo "       2. Dock Auto Tracker Left or Right."
echo "       3. Open Settings -> First-Time / Device Setup."
echo "       4. Enter Apps Script URL, Registration Token, Department, Agent ID, Agent Name, Last Name, and Pod."
echo "[INFO] Last Name controls the filename; Department + Pod control the exact Google Drive destination."
echo "[INFO] Diagnostic logs are stored in: $TARGET_DIR/Logs"
echo

if [[ "$REUSE_RUNNING_CONTROLLER" == "1" ]]; then
    echo "[OK] Auto Tracker is already running on 127.0.0.1:9000."
    echo "[INFO] No second controller was started."
    exit 0
fi

while true; do
    node "$TARGET_DIR/server.js" 2> >(tee -a "$RUNTIME_ERROR_LOG" >&2)
    exit_code=$?
    echo
    echo "Controller stopped with exit code $exit_code."
    echo "[R] Restart Controller"
    echo "[Q] Quit"
    read -r -p "Select: " choice
    case "${choice^^}" in
        R) ;;
        Q) exit 0 ;;
        *) echo "Invalid choice. Restarting controller." ;;
    esac
done
