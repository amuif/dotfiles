pragma ComponentBehavior: Bound

// Horizontal system tray for the top bar (patched from the vertical original).
// Compact/expand mode is dropped: all tray icons are always shown in a row.
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property alias layout: layout
    readonly property alias items: items
    readonly property Item expandIcon: dummyExpand

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.medium : Tokens.padding.extraSmall

    property bool expanded

    readonly property real nonAnimWidth: items.count > 0 ? layout.implicitWidth + padding * 2 : 0

    clip: true
    visible: width > 0

    implicitHeight: Tokens.sizes.bar.innerWidth
    implicitWidth: nonAnimWidth

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Item {
        id: dummyExpand
        visible: false
    }

    Row {
        id: layout

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.padding
        spacing: Tokens.spacing.small

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: ScriptModel {
                values: SystemTray.items.values.filter(i => i.status !== Status.Passive && !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
            }

            TrayItem {}
        }
    }

    Behavior on implicitWidth {
        Anim {}
    }
}
