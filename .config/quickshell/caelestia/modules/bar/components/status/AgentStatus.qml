import QtQuick
import QtQuick.Effects
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Bar ring: Claude logo (monochrome) inside a ring showing Claude's 5h session usage
Item {
    id: root

    required property color colour

    readonly property real ratio: AgentUsage.claude?.ratio ?? 0
    readonly property color mono: Colours.palette.m3onSurface
    readonly property color level: ratio >= 0.9 ? Colours.palette.m3error : ratio >= 0.7 ? Colours.palette.m3tertiary : mono

    implicitWidth: Tokens.font.icon.medium.pointSize * 1.45
    implicitHeight: implicitWidth

    CircularProgress {
        anchors.fill: parent
        value: root.ratio
        strokeWidth: 2
        spacing: 2
        fgColour: root.level
        bgColour: Qt.alpha(root.mono, 0.2)

        Behavior on value {
            Anim {}
        }
    }

    // Plain mipmapped image + MultiEffect tint: crisp at small sizes (ColouredIcon blurred it)
    Image {
        anchors.centerIn: parent
        source: `file://${Quickshell.shellPath("assets/agents/claude.png")}`
        width: Math.round(root.implicitWidth * 0.55)
        height: width
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        smooth: true
        mipmap: true
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1
            colorizationColor: root.mono
            brightness: 1
        }
    }
}
