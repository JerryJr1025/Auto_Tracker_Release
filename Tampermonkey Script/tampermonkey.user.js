// ==UserScript==
// @name Prototype Job & Task Handler Version 0.0.6 Alpha
// @namespace http://tampermonkey.net/
// @version 0.0.6
// @description Live Job Tracker Overlay with Idle Detection and Node.js Backend
// @author JBallados
// @match *://*.labeling-tools.augmoto.com/*
// @match *://labeling-tools.augmoto.com/*
// @grant GM_xmlhttpRequest
// @grant GM_getValue
// @grant GM_setValue
// @connect localhost
// @updateURL https://raw.githubusercontent.com/JerryJr1025/Auto_Tracker_Release/main/Tampermonkey%20Script/tampermonkey.meta.js
// @downloadURL https://raw.githubusercontent.com/JerryJr1025/Auto_Tracker_Release/main/Tampermonkey%20Script/tampermonkey.user.js
// @run-at document-end
// ==/UserScript==

(function () {
    'use strict';

    const SERVER = "http://localhost:9000";
    const IDLE_TIMEOUT = 30 * 1000;
    let idleTimer = null;
    let currentStatus = "ACTIVE";
    let eventSource = null;
    let lastJobId = "";
    let lastJobUrl = location.href;
    let lastJobDescription = "";
    let useLocalCounters = false;
    let counterLocked = false;
    let pendingReset = false;
    let ignoreInitialStats = false;
    let currentIntervalNumber = Number(GM_getValue("currentIntervalNumber", 1));
    let currentIntervalStartedAt = null;
    let submitLocked = false;
    let submitRequestInProgress = false;
    let trackingMode = 0;
    let lastHandledSubmitTime = 0;
    const SUBMIT_DEBOUNCE_MS = 500;
    let localCounters = {
        totalTaskCompleted: 0,
        totalJobsCompleted: 0
    };
    let mode2Stats = {
        mode2TaskCompleted: 0,
        mode2JobsCompleted: 0,
        mode2DeletedBoxes: 0,
        mode2EmptyAreaConfirmation: 0,
        mode2EmptyAreaNoMatchFound: 0,
        mode2UnblurredPerson: 0,
        mode2SkippedTask: 0
    };

// =========================================
// FUNCTION APPLY SERVER INTERVAL
// Search: applyServerInterval
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function applyServerInterval(stats) {

    if (!stats || !stats.currentInterval || stats.currentInterval.number === undefined) {
        console.warn("⚠️ Server did not provide a valid interval.");
        return;
    }
    const serverInterval = Number(stats.currentInterval.number);
    if (!Number.isFinite(serverInterval) || serverInterval < 1) {
        console.warn("⚠️ Invalid server interval:", stats.currentInterval.number);
        return;
    }
    currentIntervalNumber = serverInterval;
    console.log("🔢 Interval synchronized from server:", currentIntervalNumber);
    if ($("interval")) {
        $("interval").innerText = getIntervalName(currentIntervalNumber);
    }

}

// =========================================
// FUNCTION INITIALIZE LOCAL COUNTERS FROM STATS
// Search: initializeLocalCountersFromStats
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function initializeLocalCountersFromStats(stats) {

    if (!stats) return;
    localCounters.totalTaskCompleted = stats.intervalCounters?.mode1?.taskCompleted ?? stats.allTimeTasks ?? stats.totalTaskCompleted ?? 0;
    localCounters.totalJobsCompleted = stats.intervalCounters?.mode1?.jobsCompleted ?? stats.totalJobsCompleted ?? 0;
    applyServerInterval(stats);
    if (pendingReset || ignoreInitialStats) {
        counterLocked = true;
        useLocalCounters = true;
        pendingReset = false;
        ignoreInitialStats = false;
    } else {
        counterLocked = false;
        useLocalCounters = true;
    }
    updateStats(stats);

}

// =========================================
// FUNCTION $
// Search: $
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function $(id) {

    return document.getElementById(id);

}

// =========================================
// FUNCTION PAGE TEXT
// Search: pageText
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function pageText() {

    if (!document.body) return '';
    const body = document.body.cloneNode(true);
    body.querySelectorAll('#tracker-overlay, script, style, noscript').forEach(el => el.remove());
    return body.innerText || body.textContent || '';

}

// =========================================
// FUNCTION GET JOB ID
// Search: getJobId
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function getJobId() {

    const route = location.pathname.match(/\/jobs\/(JOB_\d+)(?:\/|$)/i);
    if (route) return route[1];
    const match = pageText().match(/JOB_\d+/i);
    return match ? match[0] : 'None';

}
    let previousJobId = null;

// =========================================
// FUNCTION UPDATE JOB DISPLAY
// Search: updateJobDisplay
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function updateJobDisplay() {

    const currentJob = getJobId();
    if ($("job")) {
        $("job").innerText = currentJob;
    }
    if (previousJobId && currentJob !== previousJobId) {
        if ($("new-job")) {
            $("new-job").innerText = currentJob;
        }
    }
    previousJobId = currentJob;

}

// =========================================
// FUNCTION PH TIME
// Search: phTime
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function phTime() {

    return new Date().toLocaleTimeString("en-US", {
        timeZone: "Asia/Manila"
    });

}

// =========================================
// FUNCTION CREATE REQUEST ID
// Search: createRequestId
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function createRequestId() {

    return Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 10);

}

// =========================================
// FUNCTION PH DATE TIME
// Search: phDateTime
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function phDateTime() {

    return new Date().toLocaleString("en-US", {
        timeZone: "Asia/Manila",
        year: "numeric",
        month: "numeric",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
        hour12: true
    });

}

// =========================================
// FUNCTION API
// Search: api
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function api(method, endpoint, data, callback) {

    console.log("🌐 API REQUEST:", method, endpoint, data);
    GM_xmlhttpRequest({
        method,
        url: SERVER + endpoint,
        headers: {
            "Content-Type": "application/json"
        },
        data: data ? JSON.stringify(data) : undefined,
        onload(res) {
            console.log("📥 API RESPONSE:", res.status, res.responseText);
            if (!callback) return;
            try {
                const parsed = JSON.parse(res.responseText);
                console.log("📦 PARSED RESPONSE:", parsed);
                callback(parsed);
            } catch (error) {
                console.error("❌ API JSON PARSE ERROR:", error);
                callback(null);
            }
        },
        onerror(error) {
            console.error("❌ API REQUEST ERROR:", error);
            if (callback) {
                callback(null);
            }
        },
        ontimeout() {
            console.error("❌ API REQUEST TIMEOUT");
            if (callback) {
                callback(null);
            }
        }
    });

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
// FUNCTION CREATE OVERLAY
// Search: createOverlay
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function createOverlay(stats) {

    if ($("tracker-overlay")) return;
    const overlay = document.createElement("div");
    overlay.id = "tracker-overlay";
    overlay.innerHTML = `

<div id="tracker-header"

style="

    cursor:move;

    background:#27272a;

    padding:6px;

    margin:-12px -12px 10px -12px;

    text-align:center;

    font-size:11px;

    font-weight:bold;

    border-radius:8px 8px 0 0;

    user-select:none;

">

    JOB TRACKER VER. 0.0.27 ALPHA

</div>



<div style="font-family:monospace">



    <div style="display:flex;justify-content:space-between">

        <span>PH Time</span>

        <strong id="clock">--:--:--</strong>

    </div>



    <div style="display:flex;justify-content:space-between">

        <span>Status</span>

        <strong id="status" style="color:#4ade80">

            ACTIVE

        </strong>

    </div>

    <div style="display:flex;justify-content:space-between">
    <span>Tracking Mode</span>
    <strong id="tracking-mode" style="color:#38bdf8">
        MODE 1
    </strong>
    </div>



    <div style="display:flex;justify-content:space-between">

        <span>Current Interval</span>

        <strong id="interval">

            1ST

        </strong>

    </div>



   <hr>

<!-- =============================== -->
<!-- MODE 1 COUNTERS -->
<!-- =============================== -->

<div style="
    font-weight:bold;
    margin-bottom:4px;
    color:#a1a1aa;
">
    MODE 1 — CONFIRMATION
</div>

<div style="display:flex;justify-content:space-between">
    <span>Tasks</span>
    <strong id="mode1-tasks">
        ${stats.totalTaskCompleted || 0}
    </strong>
</div>

<div style="display:flex;justify-content:space-between">
    <span>Jobs</span>
    <strong id="mode1-jobs">
        ${stats.totalJobsCompleted || 0}
    </strong>
</div>


<hr>


<!-- =============================== -->
<!-- MODE 2 COUNTERS -->
<!-- =============================== -->

<div style="
    font-weight:bold;
    margin-bottom:4px;
    color:#a1a1aa;
">
    MODE 2 — COVERAGE
</div>

<div style="display:flex;justify-content:space-between">
    <span>Tasks</span>
    <strong id="mode2-tasks">
        0
    </strong>
</div>

<div style="display:flex;justify-content:space-between">
    <span>Jobs</span>
    <strong id="mode2-jobs">
        0
    </strong>
</div>


<div style="display:flex;justify-content:space-between">
    <span>Empty Confirm</span>
    <strong id="mode2-empty-confirm">
        0
    </strong>
</div>

<div style="display:flex;justify-content:space-between">
    <span>Empty No Match</span>
    <strong id="mode2-empty-nomatch">
        0
    </strong>
</div>

<div style="display:flex;justify-content:space-between">
    <span>Unblurred Person</span>
    <strong id="mode2-unblurred">
        0
    </strong>
</div>

<div style="display:flex;justify-content:space-between">
    <span>Deleted Boxes</span>
    <strong id="mode2-deleted">0</strong>
</div>

<div style="display:flex;justify-content:space-between">
    <span>Skipped Task</span>
    <strong id="mode2-skipped">
        0
    </strong>
</div>


<hr>


    <div style="display:flex;justify-content:space-between">

        <span>Current Job</span>

        <strong id="job" style="color:#facc15">

            ${stats.currentJobId || getJobId()}

        </strong>

    </div>



    <div style="display:flex;justify-content:space-between">

        <span>New Job</span>

        <strong id="new-job" style="color:#38bdf8">

            None

        </strong>

    </div>



</div>

`;
    Object.assign(overlay.style, {
        position: "fixed",
        top: GM_getValue("trackerTop", "70px"),
        left: GM_getValue("trackerLeft", "20px"),
        width: "260px",
        background: "#18181b",
        color: "#fff",
        padding: "12px",
        border: "1px solid #333",
        borderRadius: "8px",
        fontFamily: "Segoe UI",
        fontSize: "13px",
        zIndex: 999999,
        boxShadow: "0 0 15px rgba(0,0,0,.5)"
    });
    document.body.appendChild(overlay);
    makeDraggable(overlay, $("tracker-header"));

}

// =========================================
// FUNCTION MAKE DRAGGABLE
// Search: makeDraggable
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function makeDraggable(element, handle) {

    let isDragging = false;
    let startX = 0;
    let startY = 0;
    let startLeft = 0;
    let startTop = 0;
    const dragHandle = handle || element;
    dragHandle.style.cursor = "move";
    dragHandle.addEventListener("pointerdown", startDrag);
    function startDrag(e) {
        if (e.button !== 0) return;
        isDragging = true;
        startX = e.clientX;
        startY = e.clientY;
        startLeft = element.offsetLeft;
        startTop = element.offsetTop;
        dragHandle.setPointerCapture(e.pointerId);
        document.addEventListener("pointermove", drag);
        document.addEventListener("pointerup", stopDrag);
    }
    function drag(e) {
        if (!isDragging) return;
        const left = startLeft + (e.clientX - startX);
        const top = startTop + (e.clientY - startY);
        element.style.left = left + "px";
        element.style.top = top + "px";
        GM_setValue("trackerLeft", element.style.left);
        GM_setValue("trackerTop", element.style.top);
    }
    function stopDrag(e) {
        isDragging = false;
        try {
            dragHandle.releasePointerCapture(e.pointerId);
        } catch {}
        document.removeEventListener("pointermove", drag);
        document.removeEventListener("pointerup", stopDrag);
    }

}

// =========================================
// FUNCTION START CLOCK
// Search: startClock
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function startClock() {

    setInterval(() => {
        const clock = $("clock");
        if (clock) {
            clock.innerText = phTime();
        }
        updateJobDisplay();
    }, 1000);

}

// =========================================
// FUNCTION SET STATUS
// Search: setStatus
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function setStatus(status) {

    currentStatus = status;
    const el = $("status");
    if (!el) return;
    el.innerText = status;
    el.style.color = status === "ACTIVE" ? "#4ade80" : status === "IDLE" ? "#ef4444" : "#facc15";

}

// =========================================
// FUNCTION LOG
// Search: log
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function log(message) {

    const el = $("log");
    if (!el) return;
    el.innerText = message;

}

// =========================================
// FUNCTION UPDATE STATS
// Search: updateStats
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function updateStats(data) {

    if (!data) return;
    console.log("📊 SERVER DATA:", data);
    if (data.trackingMode !== undefined) {
        const serverMode = Number(data.trackingMode);
        if (serverMode === 1 || serverMode === 2) {
            trackingMode = serverMode;
            console.log("🎯 Tracking Mode from Server:", trackingMode);
        }
    }
    if (data.intervalCounters?.mode1) {
        localCounters.totalTaskCompleted = Number(data.intervalCounters.mode1.taskCompleted) || 0;
        localCounters.totalJobsCompleted = Number(data.intervalCounters.mode1.jobsCompleted) || 0;
    }
    const coverage = data.intervalCounters?.mode2 ?? data.mode2;
    if (coverage) {
        mode2Stats.mode2DeletedBoxes = Number(coverage.deletedBoxes) || 0;
        mode2Stats.mode2TaskCompleted = Number(coverage.taskCompleted) || 0;
        mode2Stats.mode2JobsCompleted = Number(coverage.jobsCompleted) || 0;
        mode2Stats.mode2EmptyAreaConfirmation = Number(coverage.emptyAreaConfirmation) || 0;
        mode2Stats.mode2EmptyAreaNoMatchFound = Number(coverage.emptyAreaNoMatchFound) || 0;
        mode2Stats.mode2UnblurredPerson = Number(coverage.unblurredPerson) || 0;
        mode2Stats.mode2SkippedTask = Number(coverage.skippedTask) || 0;
        console.log("📊 Mode 2 stats synchronized:", mode2Stats);
    }
    if (data.currentInterval && data.currentInterval.number !== undefined) {
        const serverInterval = Number(data.currentInterval.number);
        if (Number.isFinite(serverInterval) && serverInterval >= 1) {
            currentIntervalNumber = serverInterval;
            console.log("🔢 Current Interval from Server:", currentIntervalNumber);
        } else {
            console.warn("⚠️ Invalid interval received from server:", data.currentInterval.number);
        }
    }
    function updateMode2UI() {
        const modeEl = $("tracking-mode");
        if (modeEl) {
            if (trackingMode === 1) {
                modeEl.innerText = "MODE 1";
                modeEl.style.color = "#4ade80";
            } else if (trackingMode === 2) {
                modeEl.innerText = "MODE 2";
                modeEl.style.color = "#38bdf8";
            } else {
                modeEl.innerText = "NOT SET";
                modeEl.style.color = "#facc15";
            }
        }
        if ($("mode1-tasks")) {
            $("mode1-tasks").innerText = localCounters.totalTaskCompleted || 0;
        }
        if ($("mode1-jobs")) {
            $("mode1-jobs").innerText = localCounters.totalJobsCompleted || 0;
        }
        if ($("mode2-tasks")) {
            $("mode2-tasks").innerText = mode2Stats.mode2TaskCompleted || 0;
        }
        if ($("mode2-jobs")) {
            $("mode2-jobs").innerText = mode2Stats.mode2JobsCompleted || 0;
        }
        if ($("mode2-deleted")) $("mode2-deleted").innerText = mode2Stats.mode2DeletedBoxes || 0;
        if ($("mode2-empty-confirm")) {
            $("mode2-empty-confirm").innerText = mode2Stats.mode2EmptyAreaConfirmation || 0;
        }
        if ($("mode2-empty-nomatch")) {
            $("mode2-empty-nomatch").innerText = mode2Stats.mode2EmptyAreaNoMatchFound || 0;
        }
        if ($("mode2-unblurred")) {
            $("mode2-unblurred").innerText = mode2Stats.mode2UnblurredPerson || 0;
        }
        if ($("mode2-skipped")) {
            $("mode2-skipped").innerText = mode2Stats.mode2SkippedTask || 0;
        }
    }
    updateMode2UI();
    const taskCount = Number(data.intervalCounters?.mode1?.taskCompleted ?? data.allTimeTasks ?? data.totalTaskCompleted ?? 0);
    if ($("tasks")) {
        $("tasks").innerText = taskCount;
    }
    const jobCount = Number(data.intervalCounters?.mode1?.jobsCompleted ?? data.totalJobsCompleted ?? 0);
    if ($("jobs")) {
        $("jobs").innerText = jobCount;
    }
    if ($("job")) {
        $("job").innerText = data.currentJobId && data.currentJobId !== "No Active Job Detected" ? data.currentJobId : getJobId();
    }
    if ($("interval")) {
        $("interval").innerText = getIntervalName(currentIntervalNumber);
    }
    if (data.agentStatus) {
        setStatus(data.agentStatus);
    }

}

// =========================================
// FUNCTION LOAD STATS
// Search: loadStats
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function loadStats() {

    api("GET", "/stats", null, function (data) {
        if (!data) return;
        updateStats(data);
        if (data.agentStatus) {
            setStatus(data.agentStatus);
        }
    });

}

// =========================================
// FUNCTION RESET IDLE TIMER
// Search: resetIdleTimer
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function resetIdleTimer() {

    if (currentStatus === "IDLE") {
        setStatus("ACTIVE");
        console.log("Sending active_alert");
        api("POST", "/", {
            action: "active_alert"
        });
    }
    clearTimeout(idleTimer);
    idleTimer = setTimeout(() => {
        setStatus("IDLE");
        console.log("Sending idle_alert");
        api("POST", "/", {
            action: "idle_alert"
        });
    }, IDLE_TIMEOUT);

}

// =========================================
// FUNCTION START IDLE TRACKING
// Search: startIdleTracking
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function startIdleTracking() {

    ["mousemove", "mousedown", "keydown", "wheel", "touchstart"].forEach(eventName => {
        window.addEventListener(eventName, resetIdleTimer, true);
    });
    resetIdleTimer();

}

// =========================================
// FUNCTION RESET LOCAL COUNTERS
// Search: resetLocalCounters
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function resetLocalCounters(data) {

    lastHandledSkipTime = 0;
    initializeLocalCountersFromStats(data);

}

// =========================================
// FUNCTION CONNECT EVENTS
// Search: connectEvents
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function connectEvents() {

    if (eventSource) {
        eventSource.close();
    }
    eventSource = new EventSource(SERVER + "/events");
    eventSource.onopen = () => {
        log("Connected");
    };
    eventSource.onmessage = event => {
        try {
            const data = JSON.parse(event.data);
            if (data.action === "interval_reset") {
                const serverInterval = Number(data.currentInterval?.number);
                console.log("🔄 INTERVAL RESET EVENT RECEIVED:", serverInterval);
                if (Number.isFinite(serverInterval) && serverInterval >= 1) {
                    currentIntervalNumber = serverInterval;
                    if ($("interval")) {
                        $("interval").innerText = getIntervalName(currentIntervalNumber);
                    }
                    log("🔄 Interval changed to " + getIntervalName(currentIntervalNumber));
                    console.log("✅ Interval updated and saved:", currentIntervalNumber);
                } else {
                    console.warn("⚠️ Invalid interval_reset received:", data.currentInterval);
                }
                lastHandledSkipTime = 0;
                initializeLocalCountersFromStats(data);
                return;
            }
            if (data.action === "reset_counters") {
                log("🔄 Counters Reset");
                resetLocalCounters(data);
            } else if (data.action === "reset_all_counters") {
                log("🔄 Full Reset");
                resetLocalCounters(data);
            } else {
                initializeLocalCountersFromStats(data);
                if (data.action) {
                    log("Server: " + data.action);
                }
            }
        } catch (err) {
            console.error("❌ SSE update error:", err);
        }
    };
    eventSource.onerror = () => {
        log("Reconnecting...");
        eventSource.close();
        setTimeout(connectEvents, 3000);
    };

}

// =========================================
// FUNCTION HANDLE VISIBILITY CHANGE
// Search: handleVisibilityChange
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function handleVisibilityChange() {

    if (document.hidden) {
        console.log("Tab Hidden");
        api("POST", "/", {
            action: "tab_hidden"
        });
    } else {
        console.log("Tab Visible");
        api("POST", "/", {
            action: "tab_visible"
        });
    }

}

// =========================================
// FUNCTION HANDLE WINDOW BLUR
// Search: handleWindowBlur
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function handleWindowBlur() {

    console.log("Window Lost Focus");
    api("POST", "/", {
        action: "window_blur"
    });

}

// =========================================
// FUNCTION HANDLE WINDOW FOCUS
// Search: handleWindowFocus
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function handleWindowFocus() {

    console.log("Window Focused");
    api("POST", "/", {
        action: "window_focus"
    });

}

// =========================================
// FUNCTION GET SUBMIT TASK SNAPSHOT
// Search: getSubmitTaskSnapshot
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function getSubmitTaskSnapshot() {

    const text = pageText();
    return text.replace(/\s+/g, " ").trim();

}

// =========================================
// FUNCTION WAIT FOR TASK CHANGE
// Search: waitForTaskChange
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function waitForTaskChange(previousTaskPosition) {

    let attempts = 0;
    const checker = setInterval(() => {
        attempts++;
        const taskData = getCurrentTaskPosition();
        if (taskData) {
            const currentPosition = taskData.position;
            console.log("🔎 Checking task position:", previousTaskPosition, "→", currentPosition);
            if (previousTaskPosition !== null && currentPosition > previousTaskPosition) {
                clearInterval(checker);
                submitLocked = false;
                submitRequestInProgress = false;
                console.log("✅ Task position advanced:", previousTaskPosition, "→", currentPosition);
                console.log("🔓 Submit unlocked.");
                return;
            }
            if (taskData.total > 0 && currentPosition >= taskData.total) {
                clearInterval(checker);
                submitLocked = false;
                submitRequestInProgress = false;
                console.log("🏁 Job task limit reached:", currentPosition, "/", taskData.total);
                console.log("🔓 Submit unlocked.");
                return;
            }
        }
        if (attempts >= 50) {
            clearInterval(checker);
            submitLocked = false;
            submitRequestInProgress = false;
            console.warn("⚠️ Task position did not advance.");
            console.log("🔓 Submit unlocked by timeout.");
        }
    }, 100);

}

// =========================================
// FUNCTION GET CURRENT TASK POSITION
// Search: getCurrentTaskPosition
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function getCurrentTaskPosition() {

    const text = pageText();
    const match = text.match(/tasks?\s*:\s*(\d+)\s*\/\s*(\d+)/i);
    if (!match) {
        return null;
    }
    return {
        position: parseInt(match[1], 10),
        total: parseInt(match[2], 10)
    };

}

// =========================================
// FUNCTION PARSE COVERAGE METRICS
// Search: parseCoverageMetrics
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function parseCoverageMetrics(text) {

    const labels = {
        emptyAreaConfirmation: /Out of Stock Confirmed\s*\(\s*(\d+)\s*\)/i,
        emptyAreaNoMatchFound: /Empty Area\s*\(\s*(\d+)\s*\)/i,
        unblurredPerson: /Unblurred Persons?\s*\(\s*(\d+)\s*\)/i,
        deletedBoxes: /Deleted\s*\(\s*(\d+)\s*\)/i
    };
    const result = {};
    for (const [key, pattern] of Object.entries(labels)) {
        const match = text.match(pattern);
        if (!match) return null;
        result[key] = Number(match[1]);
        if (!Number.isSafeInteger(result[key])) return null;
    }
    return result;

}

// =========================================
// FUNCTION GET COVERAGE METRICS
// Search: getCoverageMetrics
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function getCoverageMetrics() {

    const headings = [...document.querySelectorAll('body *')].filter(el => !el.closest('#tracker-overlay') && el.getClientRects().length && /^(Out of Stock Confirmed|Empty Area|Unblurred Persons?|Deleted)\s*\(\s*\d+\s*\)$/i.test((el.textContent || '').trim())).map(el => el.textContent.trim());
    return parseCoverageMetrics(headings.join('\n'));

}

// =========================================
// FUNCTION IS SUBMIT TARGET
// Search: isSubmitTarget
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function isSubmitTarget(target) {

    if (!target || !(target instanceof Element)) {
        return false;
    }
    if (target.closest("#tracker-overlay")) {
        return false;
    }
    const candidates = [target.innerText, target.textContent, target.getAttribute("aria-label"), target.value, target.dataset && target.dataset.action];
    return candidates.some(value => {
        if (value == null) return false;
        const normalized = String(value).replace(/\s+/g, " ").trim().toLowerCase();
        return normalized === "submit" || normalized === "submit task";
    });

}
    let lastHandledSkipTime = 0;

// =========================================
// FUNCTION HANDLE SKIP
// Search: handleSkip
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function handleSkip(event) {

    if (!event.isTrusted || trackingMode !== 2) return;
    const target = event.target instanceof Element ? event.target.closest('button, [role="button"], input[type="button"]') : null;
    if (!target || target.disabled || target.getAttribute('aria-disabled') === 'true' || target.closest('#tracker-overlay')) return;
    const labels = [target.innerText, target.textContent, target.getAttribute('aria-label'), target.value, target.dataset?.action];
    if (!labels.some(value => /^(skip|skip task)$/i.test(String(value || '').trim()))) return;
    const now = Date.now();
    if (now - lastHandledSkipTime < SUBMIT_DEBOUNCE_MS) return;
    lastHandledSkipTime = now;
    resetIdleTimer();
    api('POST', '/', {
        action: 'coverage_skip'
    });

}

// =========================================
// FUNCTION HANDLE SUBMIT
// Search: handleSubmit
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function handleSubmit(event) {

    if (!event.isTrusted) return;
    const target = event.target instanceof Element ? event.target.closest('button, [role="button"], input[type="submit"]') : null;
    if (!target || target.disabled || target.getAttribute('aria-disabled') === 'true') return;
    const isSubmit = isSubmitTarget(target);
    if (!isSubmit) return;
    if (target.closest("#tracker-overlay")) {
        return;
    }
    console.log("🎯 VALID SUBMIT CLICK:", target.tagName, target.innerText?.trim());
    const now = Date.now();
    if (now - lastHandledSubmitTime < SUBMIT_DEBOUNCE_MS) {
        console.log("⏳ Duplicate Submit click ignored.");
        return;
    }
    if (submitLocked) {
        console.log("⏳ Submit already locked.");
        return;
    }
    if (submitRequestInProgress) {
        console.log("⏳ Submit request already in progress.");
        return;
    }
    const coverageMetrics = trackingMode === 2 ? getCoverageMetrics() : null;
    if (trackingMode === 2 && !coverageMetrics) {
        log('Coverage not recorded: unable to read all four sidebar counts.');
        console.warn('Coverage snapshot missing; no tracker counters changed.');
        return;
    }
    submitLocked = true;
    submitRequestInProgress = true;
    lastHandledSubmitTime = now;
    const previousTaskSnapshot = getSubmitTaskSnapshot();
    const previousTaskData = getCurrentTaskPosition();
    const previousTaskPosition = previousTaskData ? previousTaskData.position : null;
    const previousTotalTasks = previousTaskData ? previousTaskData.total : null;
    console.log("📌 Submitted task position:", previousTaskPosition, "/", previousTotalTasks);
    resetIdleTimer();
    const jobId = getJobId();
    let isJobFinished = false;
    const currentTaskData = getCurrentTaskPosition();
    if (currentTaskData) {
        const current = currentTaskData.position;
        const total = currentTaskData.total;
        console.log("📊 Submit task position:", current, "/", total);
        if (Number.isFinite(current) && Number.isFinite(total) && total > 0 && current >= total) {
            isJobFinished = true;
            console.log("🏁 Final task detected.");
        } else {
            console.log("➡️ Job still has remaining tasks.");
        }
    } else {
        console.warn("⚠️ Unable to determine current task position.");
        isJobFinished = false;
    }
    const requestId = createRequestId();
    console.log("📤 Sending submit request:", requestId);
    api("POST", "/", {
        action: "click_submit",
        coverageMetrics,
        requestId: requestId,
        jobId: jobId,
        isJobFinished: isJobFinished,
        intervalNumber: currentIntervalNumber,
        submittedTaskPosition: previousTaskPosition,
        submittedTaskSnapshot: previousTaskSnapshot,
        totalTasks: previousTotalTasks ? previousTaskData.total : 0
    }, function (data) {
        if (!data || data.success === false || data.error) {
            submitRequestInProgress = false;
            submitLocked = false;
            console.warn("⚠️ Submit received no response.");
            return;
        }
        if (typeof data.allTimeTasks === "number") {
            localCounters.totalTaskCompleted = data.allTimeTasks;
        }
        if (typeof data.totalTaskCompleted === "number") {
            localCounters.totalTaskCompleted = data.totalTaskCompleted;
        }
        if (typeof data.totalJobsCompleted === "number") {
            localCounters.totalJobsCompleted = data.totalJobsCompleted;
        }
        updateStats(data);
        log(`✅ Task submitted ${isJobFinished ? "(Job Complete)" : ""}`);
        if (previousTaskPosition !== null) {
            waitForTaskChange(previousTaskPosition);
        } else {
            setTimeout(() => {
                submitLocked = false;
                submitRequestInProgress = false;
                console.log("🔓 Submit unlocked by safety timeout.");
            }, 5000);
        }
    });

}

// =========================================
// FUNCTION MONITOR JOB
// Search: monitorJob
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function monitorJob() {

    const newJobId = getJobId();
    if (!newJobId || newJobId === "No Jobs Detected" || newJobId === lastJobId) {
        return;
    }
    api("POST", "/", {
        action: "job_changed",
        previousJobId: lastJobId,
        newJobId,
        newUrl: location.href,
        newDescription: window.location.pathname
    });
    lastJobId = newJobId;
    log("New Job: " + newJobId);

}

// =========================================
// FUNCTION INIT
// Search: init
// Ver 0.0.5 Alpha || 2026-09-07 || JBallados
// =========================================
function init() {

    console.log("🚀 Initializing Prototype Tracker...");
    const initialStats = {
        totalTaskCompleted: 0,
        totalJobsCompleted: 0,
        currentJobId: getJobId(),
        agentStatus: "ACTIVE",
        currentInterval: {
            number: 1,
            tasks: 0
        }
    };
    createOverlay(initialStats);
    console.log("🖥️ Tracker UI created.");
    startClock();
    startIdleTracking();
    connectEvents();
    window.addEventListener("click", handleSkip, true);
    window.addEventListener("click", handleSubmit, true);
    document.addEventListener("visibilitychange", handleVisibilityChange);
    window.addEventListener("blur", handleWindowBlur);
    window.addEventListener("focus", handleWindowFocus);
    setInterval(monitorJob, 1000);
    console.log("🌐 Loading server stats...");
    api("GET", "/stats", null, function (stats) {
        if (!stats) {
            console.warn("⚠️ Server stats unavailable.");
            log("Server unavailable");
            return;
        }
        console.log("📊 Initial server stats:", stats);
        initializeLocalCountersFromStats(stats);
        updateStats(stats);
        if (stats.agentStatus) {
            setStatus(stats.agentStatus);
        }
        log("Ready");
        console.log("✅ Tracker initialized successfully.");
    });
    log("Connecting...");
    console.log("✅ Tracker initialization complete.");

}
    if (document.readyState === "loading") {
        window.addEventListener("DOMContentLoaded", init, {
            once: true
        });
    } else {
        init();
    }
})();
