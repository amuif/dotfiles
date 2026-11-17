pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Dropdown for the agents ring: just name + 5h-window percentage per agent
ColumnLayout {
    id: root

    spacing: Tokens.spacing.medium
    width: 220

    Component.onCompleted: AgentUsage.refresh()

    StyledText {
        visible: AgentUsage.agents.length === 0
        text: "No AI agents found"
        color: Colours.palette.m3onSurfaceVariant
    }

    Repeater {
        model: AgentUsage.agents

        ColumnLayout {
            id: row

            required property var modelData
            readonly property real ratio: modelData.ratio ?? 0
            readonly property color accent: ratio >= 0.9 ? Colours.palette.m3error : ratio >= 0.7 ? Colours.palette.m3tertiary : Colours.palette.m3primary

            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: row.modelData.icon
                    color: row.accent
                    fill: row.modelData.running ? 1 : 0
                }

                StyledText {
                    Layout.fillWidth: true
                    text: row.modelData.name
                    elide: Text.ElideRight
                }

                StyledText {
                    text: `${Math.round(row.ratio * 100)}%`
                    color: row.accent
                    font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                }
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 4
                radius: Tokens.rounding.full
                color: Colours.palette.m3surfaceContainerHighest

                StyledRect {
                    implicitHeight: parent.height
                    width: parent.width * row.ratio
                    radius: Tokens.rounding.full
                    color: row.accent

                    Behavior on width {
                        Anim {}
                    }
                }
            }
        }
    }
}
