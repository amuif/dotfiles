pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

Item {
    id: root

    implicitWidth: 840
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.large

            Column {
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: "Tasks"
                    font: Tokens.font.body.builders.large.size(20).weight(Font.DemiBold).build()
                }

                StyledText {
                    text: {
                        if (Todo.count === 0)
                            return "Nothing on your list";
                        const open = Todo.count - Todo.doneCount;
                        return open === 0 ? "All done" : `${open} to do · ${Todo.doneCount} done`;
                    }
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Item {
                Layout.fillWidth: true
            }

            TextButton {
                visible: Todo.doneCount > 0
                type: TextButton.Text
                text: "Clear done"
                onClicked: Todo.clearDone()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledTextField {
                id: field

                function submit(): void {
                    Todo.add(text);
                    text = "";
                }

                Layout.fillWidth: true
                verticalPadding: Tokens.padding.medium
                radius: Tokens.rounding.medium
                leadingIcon: "add_task"
                placeholderText: "Add a task"
                onAccepted: submit()
            }

            IconButton {
                Layout.alignment: Qt.AlignVCenter
                icon: "arrow_upward"
                disabled: field.text.trim().length === 0
                onClicked: field.submit()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 300

            StyledListView {
                id: list

                anchors.fill: parent
                clip: true
                spacing: Tokens.spacing.small

                model: ScriptModel {
                    values: Todo.sorted
                    objectProp: "id"
                }

                delegate: StyledRect {
                    id: task

                    required property var modelData

                    width: list.width
                    implicitHeight: taskRow.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.medium
                    color: Colours.tPalette.m3surfaceContainer

                    RowLayout {
                        id: taskRow

                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.small
                        anchors.rightMargin: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        IconButton {
                            type: IconButton.Text
                            icon: task.modelData.done ? "check_circle" : "radio_button_unchecked"
                            onClicked: Todo.toggle(task.modelData.id)
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: task.modelData.text
                            elide: Text.ElideRight
                            font.strikeout: task.modelData.done
                            color: task.modelData.done ? Colours.palette.m3outline : Colours.palette.m3onSurface
                        }

                        IconButton {
                            type: IconButton.Text
                            icon: "close"
                            onClicked: Todo.remove(task.modelData.id)
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: Todo.count === 0
                spacing: Tokens.spacing.small

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "checklist"
                    fontStyle: Tokens.font.icon.extraLarge
                    color: Colours.palette.m3outline
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Type a task above and press Enter"
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }
}
