pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services

// Preview popup for a screenshot. Opened by clicking the "Screenshot taken"
// notification (see Picker.qml), or via `qs -c caelestia ipc call screenshot preview <path>`.
// Every action closes the popup once it's done.
Scope {
    id: scope

    function show(path: string): void {
        loader.path = path;
        loader.activeAsync = true;
    }

    LazyLoader {
        id: loader

        property string path

        function close(): void {
            activeAsync = false;
        }

        StyledWindow {
            id: win

            name: "screenshot-preview"
            screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            // Dim backdrop, click outside the card to dismiss
            Rectangle {
                anchors.fill: parent
                color: Qt.alpha("black", 0.45)

                MouseArea {
                    anchors.fill: parent
                    onClicked: loader.close()
                }
            }

            StyledRect {
                id: card

                anchors.centerIn: parent
                width: layout.implicitWidth + Tokens.padding.large * 2
                height: layout.implicitHeight + Tokens.padding.large * 2
                radius: Tokens.rounding.large
                color: Colours.palette.m3surfaceContainer

                focus: true
                Keys.onEscapePressed: loader.close()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier))
                        copyBtn.clicked();
                    else if (event.key === Qt.Key_Delete)
                        deleteBtn.clicked();
                    else if (event.key === Qt.Key_E)
                        editBtn.clicked();
                }

                // Swallow clicks so they don't hit the backdrop
                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    id: layout

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.medium

                    StyledClippingRect {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: img.paintedWidth || 200
                        implicitHeight: img.paintedHeight || 120
                        radius: Tokens.rounding.medium
                        color: "transparent"

                        Image {
                            id: img

                            anchors.centerIn: parent
                            width: win.width * 0.6
                            height: win.height * 0.6
                            source: loader.path ? `file://${loader.path}` : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: win.width * 0.6
                        text: loader.path
                        elide: Text.ElideMiddle
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Tokens.spacing.small

                        IconTextButton {
                            id: copyBtn

                            icon: "content_copy"
                            text: qsTr("Copy")
                            isRound: true
                            type: IconTextButton.Filled
                            onClicked: {
                                Quickshell.execDetached(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", loader.path]);
                                loader.close();
                            }
                        }

                        IconTextButton {
                            id: editBtn

                            icon: "edit"
                            text: qsTr("Edit")
                            isRound: true
                            type: IconTextButton.Tonal
                            onClicked: {
                                Quickshell.execDetached(["swappy", "-f", loader.path]);
                                loader.close();
                            }
                        }

                        IconTextButton {
                            icon: "folder_open"
                            text: qsTr("Folder")
                            isRound: true
                            type: IconTextButton.Tonal
                            onClicked: {
                                Quickshell.execDetached(["xdg-open", loader.path.substring(0, loader.path.lastIndexOf("/"))]);
                                loader.close();
                            }
                        }

                        IconTextButton {
                            id: deleteBtn

                            icon: "delete"
                            text: qsTr("Delete")
                            isRound: true
                            type: IconTextButton.Tonal
                            inactiveColour: Colours.palette.m3errorContainer
                            inactiveOnColour: Colours.palette.m3onErrorContainer
                            onClicked: {
                                // Remove the file, and clear the clipboard if it still holds this screenshot
                                Quickshell.execDetached(["sh", "-c", 'if wl-paste --type image/png 2>/dev/null | cmp -s - "$1"; then wl-copy --clear; fi; rm -f -- "$1"', "sh", loader.path]);
                                loader.close();
                            }
                        }

                        IconTextButton {
                            icon: "close"
                            text: qsTr("Close")
                            isRound: true
                            type: IconTextButton.Text
                            onClicked: loader.close()
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "screenshot"

        function preview(path: string): void {
            scope.show(path);
        }
    }
}
