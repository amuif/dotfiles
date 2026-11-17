pragma Singleton

// Screen time tracker: counts seconds per focused app while the session is
// in use (not idle, not locked). Saved in ~/.local/state/caelestia/screentime.json
// as { "YYYY-MM-DD": { "<window class>": seconds } }
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.utils

Singleton {
    id: root

    readonly property int tickSeconds: 5
    readonly property int idleSeconds: 120
    readonly property int keepDays: 60

    property var days: ({})
    property bool locked
    property bool loaded
    property bool dirty
    property int revision
    property real lastTick: Date.now()

    readonly property bool idle: idleMonitor.isIdle
    readonly property bool counting: loaded && !locked && !idle

    readonly property string todayKey: {
        Time.hours; // re-evaluate across midnight
        return keyFor(new Date());
    }

    readonly property int todayTotal: {
        revision;
        return totalFor(todayKey);
    }

    // [{ app, name, seconds }] for today, most used first
    readonly property var topApps: {
        revision;
        const day = days[todayKey] ?? {};
        return Object.keys(day).map(app => ({
                    app,
                    name: nameFor(app),
                    seconds: Math.round(day[app])
                })).filter(a => a.seconds >= 30).sort((a, b) => b.seconds - a.seconds);
    }

    // Last 7 days, oldest first: [{ key, label, seconds, isToday }]
    readonly property var week: {
        revision;
        todayKey;
        const out = [];
        const now = new Date();
        for (let i = 6; i >= 0; i--) {
            const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
            const key = keyFor(d);
            out.push({
                key,
                label: d.toLocaleDateString(Qt.locale(), "ddd"),
                seconds: totalFor(key),
                isToday: i === 0
            });
        }
        return out;
    }

    readonly property int weekAverage: {
        const used = week.filter(d => d.seconds > 0);
        return used.length ? Math.round(used.reduce((a, d) => a + d.seconds, 0) / used.length) : 0;
    }

    function keyFor(d: date): string {
        const p = n => n < 10 ? `0${n}` : `${n}`;
        return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
    }

    function totalFor(key: string): int {
        const day = days[key];
        if (!day)
            return 0;
        let sum = 0;
        for (const app in day)
            sum += day[app];
        return Math.round(sum);
    }

    function nameFor(app: string): string {
        if (!app)
            return "Desktop";
        return DesktopEntries.heuristicLookup(app)?.name ?? app;
    }

    function format(seconds: int): string {
        const m = Math.floor(seconds / 60);
        if (m < 1)
            return seconds > 0 ? "<1m" : "0m";
        const h = Math.floor(m / 60);
        return h > 0 ? `${h}h ${m % 60}m` : `${m}m`;
    }

    function activeApp(): string {
        // The Wayland toplevel list knows the focused app right from startup;
        // Hyprland's IPC object is only filled in after the first window event
        return ToplevelManager.activeToplevel?.appId || Hypr.activeToplevel?.lastIpcObject?.class || "";
    }

    function save(): void {
        if (!loaded || !dirty)
            return;
        dirty = false;
        store.setText(JSON.stringify(days));
    }

    function prune(data: var): var {
        const keys = Object.keys(data).sort();
        while (keys.length > keepDays)
            delete data[keys.shift()];
        return data;
    }

    Component.onDestruction: save()

    IdleMonitor {
        id: idleMonitor

        timeout: root.idleSeconds
        respectInhibitors: true
    }

    Timer {
        interval: root.tickSeconds * 1000
        repeat: true
        running: true
        onTriggered: {
            const now = Date.now();
            const delta = (now - root.lastTick) / 1000;
            root.lastTick = now;

            // A long gap means the machine was suspended; don't count it
            if (!root.counting || delta <= 0 || delta > root.tickSeconds * 4)
                return;

            const key = root.todayKey;
            const app = root.activeApp();
            const day = root.days[key] ?? (root.days[key] = {});
            day[app] = (day[app] ?? 0) + delta;
            root.dirty = true;
            root.revision++;
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.save()
    }

    FileView {
        id: store

        path: `${Paths.state}/screentime.json`
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data && typeof data === "object")
                    root.days = root.prune(data);
            } catch (e) {
                console.warn("ScreenTime: could not parse saved data, starting fresh");
            }
            root.loaded = true;
            root.revision++;
        }
        onLoadFailed: root.loaded = true
    }
}
