pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

// Dropdown for the Claude ring: Claude's 5h session + 7-day usage, other agents below
ColumnLayout {
    id: root

    property bool showOthers

    spacing: Tokens.spacing.medium
    width: 240

    Component.onCompleted: AgentUsage.refresh()

    function accent(r: real): color {
        return r >= 0.9 ? Colours.palette.m3error : r >= 0.7 ? Colours.palette.m3tertiary : Colours.palette.m3onSurface;
    }

    // ---- Claude ----
    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        ColouredIcon {
            source: AgentUsage.logo(AgentUsage.claude ?? { logo: "claude.png" })
            implicitSize: 18
            colour: Colours.palette.m3onSurface
        }

        StyledText {
            Layout.fillWidth: true
            text: "Claude"
            font: Tokens.font.body.builders.large.weight(Font.Medium).build()
        }
    }

    StyledText {
        visible: !AgentUsage.claude
        text: "Claude Code not found"
        color: Colours.palette.m3onSurfaceVariant
    }

    UsageRow {
        visible: !!AgentUsage.claude
        label: "5h session"
        ratio: AgentUsage.claude?.ratio ?? 0
    }

    UsageRow {
        visible: !!AgentUsage.claude
        label: "7 days"
        ratio: AgentUsage.claude?.week?.ratio ?? 0
    }

    // ---- Other agents (collapsible) ----
    Item {
        Layout.fillWidth: true
        visible: AgentUsage.others.length > 0
        implicitHeight: othersRow.implicitHeight + Tokens.padding.small * 2

        StateLayer {
            radius: Tokens.rounding.small
            onClicked: root.showOthers = !root.showOthers
        }

        RowLayout {
            id: othersRow

            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.small
            anchors.rightMargin: Tokens.padding.small

            StyledText {
                Layout.fillWidth: true
                text: `Other agents (${AgentUsage.others.length})`
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            MaterialIcon {
                text: root.showOthers ? "expand_less" : "expand_more"
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    Repeater {
        model: root.showOthers ? AgentUsage.others : []

        ColumnLayout {
            id: other

            required property var modelData

            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                ColouredIcon {
                    source: AgentUsage.logo(other.modelData)
                    implicitSize: 16
                    colour: Colours.palette.m3onSurface
                }

                StyledText {
                    Layout.fillWidth: true
                    text: other.modelData.name
                    elide: Text.ElideRight
                }
            }

            UsageRow {
                label: "5h session"
                ratio: other.modelData.ratio ?? 0
            }

            UsageRow {
                label: "7 days"
                ratio: other.modelData.week?.ratio ?? 0
            }
        }
    }

    component UsageRow: ColumnLayout {
        id: usage

        required property string label
        required property real ratio

        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: usage.label
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            StyledText {
                text: `${Math.round(usage.ratio * 100)}%`
                color: root.accent(usage.ratio)
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
                width: parent.width * Math.min(1, usage.ratio)
                radius: Tokens.rounding.full
                color: root.accent(usage.ratio)

                Behavior on width {
                    Anim {}
                }
            }
        }
    }
}
