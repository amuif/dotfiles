pragma ComponentBehavior: Bound

import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

RowLayout {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen
    readonly property int vPadding: Tokens.padding.large
    readonly property int hPadding: Tokens.padding.large

    // Entries only shown when the bar is expanded (Super+M)
    readonly property var extraEntries: ["tray", "power", "dnd", "nightLight"]
    readonly property bool expanded: screenState.barExpanded

    // Background "islands": one per run of entries between spacers, in bar coords
    readonly property int islandPadding: Tokens.padding.medium
    property var islands: []

    function updateIslands(): void {
        const out = [];
        let cur = null;
        for (let i = 0; i < repeater.count; i++) {
            const it = repeater.itemAt(i) as EntryWrapper;
            if (!it)
                continue;
            if (it.entryId === "spacer") {
                if (cur)
                    out.push(cur);
                cur = null;
                continue;
            }
            if (!it.visible || it.width <= 0)
                continue;
            // Right island hugs the first status icon (the agents ring) on its left edge
            const lpad = it.entryId === "statusIcons" ? 0 : islandPadding;
            const l = it.x + it.centerShift - lpad;
            const r = it.x + it.centerShift + it.width + islandPadding;
            cur = cur ? { x: cur.x, r: r } : { x: l, r: r };
        }
        if (cur)
            out.push(cur);
        islands = out.map(i => ({ x: i.x, width: i.r - i.x }));
    }

    onWidthChanged: Qt.callLater(updateIslands)

    function closeTray(): void {
        if (!Config.bar.tray.compact)
            return;

        for (let i = 0; i < repeater.count; i++) {
            const tray = (repeater.itemAt(i) as EntryWrapper)?.item as Tray;
            if (tray)
                tray.expanded = false;
        }
    }

    function checkPopout(x: real): void {
        const ch = childAt(x, height / 2) as EntryWrapper;

        if (ch?.entryId !== "tray")
            closeTray();

        if (!ch) {
            popouts.hasCurrent = false;
            return;
        }

        const id = ch.entryId;

        if (id === "statusIcons" && Config.bar.popouts.statusIcons) {
            const items = (ch.item as StatusIcons).items;
            const icon = items.childAt(mapToItem(items, x, 0).x, items.height / 2);
            if (icon && icon.name && icon.name.length > 0) {
                popouts.currentName = icon.name;
                popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, icon.implicitWidth / 2, 0).x);
                popouts.hasCurrent = true;
            } else {
                popouts.hasCurrent = false;
            }
        } else if (id === "tray" && Config.bar.popouts.tray) {
            const tray = ch.item as Tray;
            const local = mapToItem(tray.layout, x, 0).x;
            const trayItem = tray.layout.childAt(local, tray.layout.height / 2);
            let index = -1;
            for (let i = 0; i < tray.items.count; i++)
                if (tray.items.itemAt(i) === trayItem)
                    index = i;
            if (trayItem && index >= 0) {
                popouts.currentName = `traymenu${index}`;
                popouts.currentCenter = Qt.binding(() => trayItem.mapToItem(root, trayItem.implicitWidth / 2, 0).x);
                popouts.hasCurrent = true;
            } else {
                popouts.hasCurrent = false;
            }
        } else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.activeWindow.showOnHover) {
            popouts.currentName = id.toLowerCase();
            popouts.currentCenter = (ch.item as Item).mapToItem(root, (ch.item as Item).implicitWidth / 2, 0).x ?? 0;
            popouts.hasCurrent = true;
        }
    }

    function handleWheel(x: real, angleDelta: point): void {
        const ch = childAt(x, height / 2) as EntryWrapper;
        if (ch?.entryId === "workspaces" && Config.bar.scrollActions.workspaces) {
            // Workspace scroll
            const mon = Hypr.monitorFor(screen);
            const specialWs = mon?.lastIpcObject.specialWorkspace.name;
            if (specialWs?.length > 0)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("${specialWs.slice(8)}")` : `togglespecialworkspace ${specialWs.slice(8)}`);
            else if (angleDelta.y < 0 || mon.activeWorkspace?.id > 1)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "r${angleDelta.y > 0 ? "-" : "+"}1" })` : `workspace r${angleDelta.y > 0 ? "-" : "+"}1`);
        } else if (x >= width / 2 && Config.bar.scrollActions.volume) {
            // Volume scroll on right half
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        } else if (Config.bar.scrollActions.brightness) {
            // Brightness scroll on left half
            const monitor = Brightness.getMonitorForScreen(screen);
            if (angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + GlobalConfig.services.brightnessIncrement);
            else if (angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - GlobalConfig.services.brightnessIncrement);
        }
    }

    spacing: Tokens.spacing.medium

    Repeater {
        id: repeater

        model: ScriptModel {
            values: root.Config.bar.entries.values.filter(e => e.enabled)
        }

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: EntryWrapper {
                    Layout.fillWidth: true
                }
            }
            DelegateChoice {
                roleValue: "logo"
                delegate: EntryWrapper {
                    OsIcon {
                        objectName: "taskbarLogo"
                    }
                }
            }
            DelegateChoice {
                roleValue: "workspaces"
                delegate: EntryWrapper {
                    Workspaces {
                        objectName: "taskbarWorkspaces"
                        screen: root.screen
                        fullscreen: root.fullscreen
                    }
                }
            }
            DelegateChoice {
                roleValue: "activeWindow"
                delegate: EntryWrapper {
                    ActiveWindow {
                        objectName: "taskbarActiveWindow"
                        bar: root
                        monitor: Brightness.getMonitorForScreen(root.screen)
                    }
                }
            }
            DelegateChoice {
                roleValue: "tray"
                delegate: EntryWrapper {
                    Tray {
                        objectName: "taskbarTray"
                    }
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: EntryWrapper {
                    Clock {
                        objectName: "taskbarClock"
                        popouts: root.popouts
                    }
                }
            }
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: EntryWrapper {
                    StatusIcons {
                        objectName: "taskbarStatusIcons"
                        expanded: root.expanded
                    }
                }
            }
            DelegateChoice {
                roleValue: "nightLight"
                delegate: EntryWrapper {
                    NightLightButton {
                        objectName: "taskbarNightLight"
                    }
                }
            }
            DelegateChoice {
                roleValue: "dnd"
                delegate: EntryWrapper {
                    DndButton {
                        objectName: "taskbarDnd"
                    }
                }
            }
            DelegateChoice {
                roleValue: "power"
                delegate: EntryWrapper {
                    Power {
                        objectName: "taskbarPowerButton"
                        screenState: root.screenState
                    }
                }
            }
        }
    }

    component EntryWrapper: Item {
        required property var modelData
        required property int index
        default property Item item
        readonly property string entryId: modelData.id

        visible: !root.extraEntries.includes(entryId) || root.expanded

        // Keep the clock dead-centre on screen no matter how wide the side groups get
        readonly property real centerShift: entryId === "clock" ? Math.round((root.width - width) / 2 - x) : 0
        transform: Translate { x: centerShift }
        onCenterShiftChanged: Qt.callLater(root.updateIslands)
        onXChanged: Qt.callLater(root.updateIslands)
        onWidthChanged: Qt.callLater(root.updateIslands)
        onVisibleChanged: Qt.callLater(root.updateIslands)
        Component.onCompleted: Qt.callLater(root.updateIslands)

        Layout.leftMargin: index === 0 ? root.hPadding : 0
        Layout.rightMargin: index === repeater.count - 1 ? root.hPadding : 0
        Layout.alignment: Qt.AlignVCenter

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item
    }
}
