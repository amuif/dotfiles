import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Bar ring: highest 5h-window usage across local AI agents (see AgentUsage)
Item {
    id: root

    required property color colour

    readonly property real ratio: AgentUsage.maxRatio
    readonly property color level: ratio >= 0.9 ? Colours.palette.m3error : ratio >= 0.7 ? Colours.palette.m3tertiary : colour

    implicitWidth: Tokens.font.icon.medium.pointSize * 1.45
    implicitHeight: implicitWidth

    CircularProgress {
        anchors.fill: parent
        value: root.ratio
        strokeWidth: 2
        spacing: 2
        fgColour: root.level
        bgColour: Qt.alpha(root.colour, 0.25)

        Behavior on value {
            Anim {}
        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        text: "smart_toy"
        color: root.level
        fill: AgentUsage.anyRunning ? 1 : 0
        fontStyle: Tokens.font.icon.builders.small.scale(0.8).build()
    }
}
