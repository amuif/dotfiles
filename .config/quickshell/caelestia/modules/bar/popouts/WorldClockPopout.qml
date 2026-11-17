pragma ComponentBehavior: Bound

// World clock drop-down: search all timezones and pick one to show in the bar.
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    required property PopoutState popouts

    readonly property var results: WorldClock.search(search.text)

    spacing: Tokens.spacing.medium
    implicitWidth: 380

    function choose(z: string): void {
        WorldClock.setZone(z);
        search.text = "";
        root.popouts.hasCurrent = false;
    }

    Component.onCompleted: focusTimer.start()

    Connections {
        function onCurrentNameChanged(): void {
            if (root.popouts.currentName === "worldclock")
                focusTimer.start();
        }

        target: root.popouts
    }

    Timer {
        id: focusTimer

        interval: 150
        onTriggered: search.forceActiveFocus()
    }

    // Header: current selection
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        spacing: Tokens.spacing.medium

        MaterialIcon {
            text: "public"
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.large
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: WorldClock.zone ? WorldClock.city : qsTr("No city selected")
                font: Tokens.font.title.small
                color: Colours.palette.m3onSurface
            }

            StyledText {
                visible: WorldClock.current !== null
                text: WorldClock.current ? `${WorldClock.timeStr}${WorldClock.dayDiff ? "  (" + WorldClock.dayDiff + " day)" : ""}  ·  ${WorldClock.formatOffset(WorldClock.current.offset)}` : ""
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        IconButton {
            visible: WorldClock.zone !== ""
            icon: "close"
            type: IconButton.Text
            onClicked: root.choose("")
        }
    }

    SearchBar {
        id: search

        Layout.fillWidth: true
        placeholderText: qsTr("Search city…")
        clip: true
        topPadding: Tokens.padding.medium
        bottomPadding: Tokens.padding.medium

        Keys.onDownPressed: list.incrementCurrentIndex()
        Keys.onUpPressed: list.decrementCurrentIndex()
        Keys.onReturnPressed: {
            const item = root.results[list.currentIndex];
            if (item)
                root.choose(item.zone);
        }
        Keys.onEscapePressed: root.popouts.hasCurrent = false
        onTextChanged: list.currentIndex = 0
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        visible: !WorldClock.loaded || root.results.length === 0
        text: WorldClock.loaded ? qsTr("No matches") : qsTr("Loading timezones…")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    StyledListView {
        id: list

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(root.results.length, 7) * 52
        clip: true
        highlightMoveDuration: 120
        keyNavigationEnabled: true

        model: root.results

        highlight: StyledRect {
            radius: Tokens.rounding.large
            color: Colours.palette.m3secondaryContainer
        }

        delegate: Item {
            id: row

            required property var modelData
            required property int index

            width: list.width
            height: 52

            StateLayer {
                radius: Tokens.rounding.large
                onClicked: root.choose(row.modelData.zone)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.large
                anchors.rightMargin: Tokens.padding.large
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.city
                        elide: Text.ElideRight
                        color: row.modelData.zone === WorldClock.zone ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        font: Tokens.font.body.medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: `${row.modelData.region}  ·  ${WorldClock.formatOffset(row.modelData.offset)}`
                        elide: Text.ElideRight
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }
                }

                StyledText {
                    text: {
                        Time.minutes;
                        return WorldClock.formatFor(row.modelData.offset);
                    }
                    color: Colours.palette.m3tertiary
                    font: Tokens.font.mono.small
                }
            }
        }
    }
}
