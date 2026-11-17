pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Dropdown for the agents ring: one card per AI agent found on this machine
ColumnLayout {
    id: root

    spacing: Tokens.spacing.medium
    width: 340

    Component.onCompleted: AgentUsage.refresh()

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            Layout.fillWidth: true
            text: "Agent usage"
            font: Tokens.font.title.small
        }

        StyledText {
            text: `updated ${AgentUsage.formatAgo(AgentUsage.updated)}`
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
        }
    }

    StyledText {
        visible: AgentUsage.agents.length === 0
        text: "No AI agents found on this machine"
        color: Colours.palette.m3onSurfaceVariant
    }

    Repeater {
        model: AgentUsage.agents

        StyledRect {
            id: card

            required property var modelData
            readonly property var a: modelData
            readonly property var win: a.window
            readonly property bool tokens: a.unit === "tokens"
            readonly property color accent: a.ratio >= 0.9 ? Colours.palette.m3error : a.ratio >= 0.7 ? Colours.palette.m3tertiary : Colours.palette.m3primary

            Layout.fillWidth: true
            implicitHeight: cardCol.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: cardCol

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                // Name row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: card.a.icon
                        color: card.accent
                        fill: 1
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: card.a.name
                        font: Tokens.font.body.builders.large.weight(Font.Medium).build()
                        elide: Text.ElideRight
                    }

                    StyledRect {
                        implicitWidth: statusText.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: statusText.implicitHeight + Tokens.padding.extraSmall * 2
                        radius: Tokens.rounding.full
                        color: card.a.running ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest

                        StyledText {
                            id: statusText

                            anchors.centerIn: parent
                            text: card.a.running ? "running" : "idle"
                            font: Tokens.font.body.small
                            color: card.a.running ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                        }
                    }
                }

                // Current 5h window
                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: card.win ? `${AgentUsage.formatCount(card.win.total)} ${card.a.unit} this 5h window` : "No activity in the last 5h"
                        color: Colours.palette.m3onSurface
                    }

                    StyledText {
                        visible: !!card.win
                        text: `${Math.round(card.a.ratio * 100)}%`
                        color: card.accent
                        font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3surfaceContainerHighest

                    StyledRect {
                        implicitHeight: parent.height
                        width: parent.width * (card.a.ratio ?? 0)
                        radius: Tokens.rounding.full
                        color: card.accent

                        Behavior on width {
                            Anim {}
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    text: {
                        const parts = [];
                        if (card.win)
                            parts.push(`resets in ${AgentUsage.formatDuration(card.win.end - Date.now())}`);
                        parts.push(`${card.a.peak > 0 ? "busiest 5h" : "baseline"}: ${AgentUsage.formatCount(card.a.reference)}`);
                        return parts.join(" · ");
                    }
                }

                // Today / week
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    text: {
                        const t = card.a.today, w = card.a.week;
                        const today = card.tokens ? `${AgentUsage.formatCount(t.total)} tokens · ${t.count} replies` : `${t.count} prompts`;
                        const week = card.tokens ? AgentUsage.formatCount(w.total) : `${w.count}`;
                        return `Today ${today} · 7d ${week}` + (card.a.model ? ` · ${card.a.model}` : "") + ` · last ${AgentUsage.formatAgo(card.a.lastActivity)}`;
                    }
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "From local logs only. % compares this 5h window with your busiest one; it is not your plan quota."
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
    }
}
