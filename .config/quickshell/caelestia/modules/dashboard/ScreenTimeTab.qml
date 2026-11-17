pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    readonly property int chartHeight: 120
    readonly property int maxApps: 6
    readonly property int weekMax: Math.max(1, ...ScreenTime.week.map(d => d.seconds))
    readonly property var apps: ScreenTime.topApps.slice(0, maxApps)
    readonly property int appMax: Math.max(1, apps[0]?.seconds ?? 1)

    implicitWidth: 840
    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        // Today + last 7 days
        StyledRect {
            Layout.preferredWidth: 380
            Layout.fillHeight: true
            implicitHeight: weekColumn.implicitHeight + Tokens.padding.large * 2

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: weekColumn

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                StyledText {
                    text: "Screen time today"
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    text: ScreenTime.format(ScreenTime.todayTotal)
                    font: Tokens.font.body.builders.large.size(36).weight(Font.Medium).build()
                    color: Colours.palette.m3primary
                }

                StyledText {
                    text: `Daily average ${ScreenTime.format(ScreenTime.weekAverage)}`
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillHeight: true
                    Layout.minimumHeight: Tokens.spacing.medium
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Repeater {
                        model: ScreenTime.week

                        ColumnLayout {
                            id: day

                            required property var modelData

                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: ScreenTime.format(day.modelData.seconds)
                                font: Tokens.font.label.small
                                color: Colours.palette.m3onSurface
                                opacity: hover.hovered ? 1 : 0

                                Behavior on opacity {
                                    Anim {
                                        type: Anim.DefaultEffects
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                implicitHeight: root.chartHeight

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: Math.min(28, parent.width - 2)
                                    height: Math.max(2, Math.round(root.chartHeight * day.modelData.seconds / root.weekMax))
                                    topLeftRadius: 4
                                    topRightRadius: 4
                                    color: day.modelData.isToday ? Colours.palette.m3primary : Colours.palette.m3outline
                                    opacity: hover.hovered || day.modelData.isToday ? 1 : 0.6

                                    Behavior on height {
                                        Anim {}
                                    }
                                }

                                HoverHandler {
                                    id: hover
                                }
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: day.modelData.label
                                font: Tokens.font.label.small
                                color: day.modelData.isToday ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }
                }
            }
        }

        // Most used apps today
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: appColumn.implicitHeight + Tokens.padding.large * 2

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: appColumn

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledText {
                    text: "Most used today"
                    color: Colours.palette.m3onSurfaceVariant
                }

                Repeater {
                    model: root.apps

                    RowLayout {
                        id: app

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        Item {
                            implicitWidth: 26
                            implicitHeight: 26

                            IconImage {
                                anchors.fill: parent
                                visible: app.modelData.app !== ""
                                asynchronous: true
                                source: app.modelData.app ? Icons.getAppIcon(app.modelData.app, "application-x-executable") : ""
                            }

                            MaterialIcon {
                                anchors.centerIn: parent
                                visible: app.modelData.app === ""
                                text: "desktop_windows"
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            RowLayout {
                                Layout.fillWidth: true

                                StyledText {
                                    Layout.fillWidth: true
                                    text: app.modelData.name
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    text: ScreenTime.format(app.modelData.seconds)
                                    color: Colours.palette.m3onSurfaceVariant
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 4

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 2
                                    color: Colours.palette.m3outline
                                    opacity: 0.25
                                }

                                Rectangle {
                                    width: Math.max(4, Math.round(parent.width * app.modelData.seconds / root.appMax))
                                    height: parent.height
                                    radius: 2
                                    color: Colours.palette.m3primary

                                    Behavior on width {
                                        Anim {}
                                    }
                                }
                            }
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.large
                    visible: root.apps.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    text: "Nothing recorded yet — check back in a minute"
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
