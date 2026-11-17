pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components.misc
import qs.services
import qs.utils

Singleton {
    id: root

    property list<NotifData> list: []
    readonly property list<NotifData> notClosed: list.filter(n => !n.closed)
    readonly property list<NotifData> popups: list.filter(n => n.popup)
    property alias dnd: props.dnd

    property bool loaded

    function hasFullscreen(): bool {
        for (const monitor of Hypr.monitors.values) {
            if (monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1))
                return true;
        }
        return false;
    }

    function shouldShowPopup(): bool {
        if (props.dnd || ShellState.anySidebarOpen())
            return false;
        if (GlobalConfig.notifs.fullscreen === NotifsFullscreen.Off && hasFullscreen())
            return false;
        return true;
    }

    onDndChanged: {
        applyQuiet();

        if (!GlobalConfig.utilities.toasts.dndChanged)
            return;

        if (dnd)
            Toaster.toast(Tr.tr("Do not disturb enabled"), Tr.tr("Popups and notification sounds are now disabled"), "do_not_disturb_on");
        else
            Toaster.toast(Tr.tr("Do not disturb disabled"), Tr.tr("Popups and notification sounds are now enabled"), "do_not_disturb_off");
    }

    // Apps play their own notification sounds, so the shell can't simply skip them.
    // Instead, while DND is on, the audio streams of an app that just sent a
    // notification are muted for a moment. Only streams that are new (or that
    // carried a previous notification sound) are touched, so e.g. a video already
    // playing in the same app keeps going.
    readonly property int quietBefore: 2000
    readonly property int quietAfter: 3000
    property var quietWindows: []
    property var streamSeen: ({}) // node id -> first seen (ms)
    property var mutedStreams: ({}) // node id -> app, streams currently muted by us
    property var dingStreams: ({}) // node ids we have muted before
    property var staleApps: ({}) // apps whose stream vanished while muted by us

    function streamNames(node: var): list<string> {
        const p = node.properties ?? {};
        return [p["application.name"], p["application.process.binary"], node.name].filter(s => s && s.length > 2).map(s => s.toLowerCase());
    }

    function syncStreams(): void {
        const now = Date.now();
        const alive = {};
        for (const node of Audio.streams) {
            if (!node?.isSink)
                continue;
            alive[node.id] = true;
            if (!(node.id in streamSeen))
                streamSeen[node.id] = now;
        }
        for (const id of Object.keys(streamSeen)) {
            if (alive[id])
                continue;
            delete streamSeen[id];
            delete dingStreams[id];
            if (id in mutedStreams) {
                // WirePlumber remembers the mute, undo it when the app's next stream appears
                staleApps[mutedStreams[id]] = true;
                delete mutedStreams[id];
            }
        }
        applyQuiet();
    }

    function applyQuiet(): void {
        const now = Date.now();
        quietWindows = quietWindows.filter(q => q.until > now);

        for (const node of Audio.streams) {
            if (!node?.isSink || !node.ready || !node.audio)
                continue;

            const names = streamNames(node);
            const app = names[0] ?? "";
            const seen = streamSeen[node.id] ?? now;
            const hit = props.dnd && quietWindows.some(q => (seen >= q.from - quietBefore || dingStreams[node.id]) && names.some(s => q.tokens.some(t => s.includes(t) || t.includes(s))));

            if (hit) {
                if (!node.audio.muted || staleApps[app] || node.id in mutedStreams) {
                    node.audio.muted = true;
                    mutedStreams[node.id] = app;
                    dingStreams[node.id] = true;
                    delete staleApps[app];
                }
            } else if (node.id in mutedStreams) {
                node.audio.muted = false;
                delete mutedStreams[node.id];
            } else if (staleApps[app]) {
                node.audio.muted = false;
                delete staleApps[app];
            }
        }

        quietTimer.running = quietWindows.length > 0 || Object.keys(mutedStreams).length > 0;
    }

    function quietApp(notif: Notification): void {
        const tokens = [notif.appName, notif.desktopEntry].filter(s => s && s.length > 2).map(s => s.toLowerCase());
        if (tokens.length === 0)
            return;
        const now = Date.now();
        quietWindows.push({
            tokens,
            from: now,
            until: now + quietAfter
        });
        applyQuiet();
    }

    Component.onCompleted: syncStreams()

    Timer {
        id: quietTimer

        interval: 100
        repeat: true
        onTriggered: root.applyQuiet()
    }

    Connections {
        function onStreamsChanged(): void {
            root.syncStreams();
        }

        target: Audio
    }

    onListChanged: {
        if (loaded)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: storage.setText(JSON.stringify(root.notClosed.map(n => ({
                    time: n.time,
                    id: n.id,
                    summary: n.summary,
                    body: n.body,
                    appIcon: n.appIcon,
                    appName: n.appName,
                    image: n.image,
                    expireTimeout: n.expireTimeout,
                    urgency: n.urgency,
                    resident: n.resident,
                    hasActionIcons: n.hasActionIcons,
                    actions: n.actions,
                    hasInlineReply: n.hasInlineReply,
                    inlineReplyPlaceholder: n.inlineReplyPlaceholder
                }))))
    }

    PersistentProperties {
        id: props

        property bool dnd

        reloadableId: "notifs"
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        inlineReplySupported: true
        extraHints: ["inhibitions"]

        onNotification: notif => {
            notif.tracked = true;

            if (props.dnd)
                root.quietApp(notif);

            const comp = notifComp.createObject(root, {
                popup: root.shouldShowPopup(),
                notification: notif
            });
            root.list = [comp, ...root.list];
        }
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/notifs.json`
        onLoaded: {
            const data = JSON.parse(text());
            for (const notif of data) {
                const properties = Object.assign({}, notif);

                // Backwards compatibility for old notifications
                if (properties.notificationId === undefined && properties.id !== undefined)
                    properties.notificationId = properties.id;

                delete properties.id;
                root.list.push(notifComp.createObject(root, properties));
            }
            root.list.sort((a, b) => b.time - a.time);
            root.loaded = true;
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.loaded = true;
                Qt.callLater(() => setText("[]"));
            }
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clearNotifs"
        description: "Clear all notifications"
        onPressed: {
            for (const notif of root.list.slice())
                notif.close();
        }
    }

    IpcHandler {
        function clear(): void {
            for (const notif of root.list.slice())
                notif.close();
        }

        function isDndEnabled(): bool {
            return props.dnd;
        }

        function toggleDnd(): void {
            props.dnd = !props.dnd;
        }

        function enableDnd(): void {
            props.dnd = true;
        }

        function disableDnd(): void {
            props.dnd = false;
        }

        target: "notifs"
    }

    Component {
        id: notifComp

        NotifData {}
    }
}
