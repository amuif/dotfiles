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
import qs.components.misc
import qs.services
import qs.utils

// Themed clipboard history (cliphist). Toggle: `qs -c caelestia ipc call clipboard toggle`
// or the caelestia:clipboard global shortcut.
// Enter/click copies and closes · Shift+Del / bin deletes · Esc closes.
Scope {
    id: scope

    readonly property string thumbDir: `${Paths.cache}/clipboard`
    property var entries: [] // { id, preview, image }

    function toggle(): void {
        if (loader.active) {
            loader.activeAsync = false;
        } else {
            entries = [];
            lister.running = true;
            loader.activeAsync = true;
        }
    }

    function copy(entry: var): void {
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.id]);
        loader.activeAsync = false;
    }

    function remove(entry: var): void {
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\t\\n" "$1" | cliphist delete; [ -n "$2" ] && rm -f -- "$2"', "sh", entry.id, entry.image]);
        entries = entries.filter(e => e.id !== entry.id);
    }

    function wipe(): void {
        Quickshell.execDetached(["sh", "-c", 'cliphist wipe; rm -rf -- "$1"', "sh", thumbDir]);
        entries = [];
    }

    // Lists history; decodes image entries into thumbnail files (cached by id)
    Process {
        id: lister

        command: ["sh", "-c", `
            dir="$1"; mkdir -p "$dir"
            tab=$(printf '\\t')
            cliphist list | while IFS="$tab" read -r id rest; do
                case "$rest" in
                    "[[ binary data"*)
                        ext=$(printf '%s' "$rest" | awk '{print $(NF-2)}')
                        f="$dir/$id.$ext"
                        [ -s "$f" ] || cliphist decode "$id" > "$f"
                        printf '%s\\t%s\\t%s\\n' "$id" "$rest" "$f" ;;
                    *) printf '%s\\t%s\\t\\n' "$id" "$rest" ;;
                esac
            done
        `, "sh", scope.thumbDir]
        stdout: StdioCollector {
            onStreamFinished: {
                scope.entries = text.split("\n").filter(l => l.length).map(l => {
                    const parts = l.split("\t");
                    return {
                        id: parts[0],
                        image: parts[parts.length - 1],
                        preview: parts.slice(1, -1).join("\t")
                    };
                });
            }
        }
    }

    LazyLoader {
        id: loader

        StyledWindow {
            id: win

            name: "clipboard"
            screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            readonly property var filtered: {
                const q = search.text.trim().toLowerCase();
                if (!q)
                    return scope.entries;
                return scope.entries.filter(e => e.preview.toLowerCase().includes(q) || (e.image && "image".includes(q)));
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha("black", 0.35)

                MouseArea {
                    anchors.fill: parent
                    onClicked: loader.activeAsync = false
                }
            }

            StyledRect {
                anchors.centerIn: parent
                width: Math.min(640, win.width - 64)
                height: Math.min(720, win.height - 128)
                radius: Tokens.rounding.large
                color: Colours.palette.m3surfaceContainer

                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        StyledTextField {
                            id: search

                            Layout.fillWidth: true
                            placeholderText: qsTr("Search clipboard")
                            leadingIcon: "content_paste_search"
                            focus: true
                            Component.onCompleted: forceActiveFocus()

                            onTextChanged: list.currentIndex = 0
                            Keys.onEscapePressed: loader.activeAsync = false
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onReturnPressed: list.currentItem && scope.copy(list.currentItem.modelData)
                            Keys.onEnterPressed: list.currentItem && scope.copy(list.currentItem.modelData)
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier) && list.currentItem) {
                                    scope.remove(list.currentItem.modelData);
                                    event.accepted = true;
                                }
                            }
                        }

                        IconTextButton {
                            icon: "delete_sweep"
                            text: qsTr("Clear")
                            isRound: true
                            type: IconTextButton.Tonal
                            disabled: scope.entries.length === 0
                            onClicked: scope.wipe()
                        }
                    }

                    ListView {
                        id: list

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: Tokens.spacing.small
                        model: win.filtered
                        highlightMoveDuration: 120
                        keyNavigationWraps: true

                        StyledScrollBar.vertical: StyledScrollBar {
                            flickable: list
                        }

                        delegate: StyledRect {
                            id: item

                            required property var modelData
                            required property int index
                            readonly property bool selected: ListView.isCurrentItem

                            width: ListView.view.width
                            height: modelData.image ? 132 : Math.max(48, text.implicitHeight + Tokens.padding.medium * 2)
                            radius: Tokens.rounding.medium
                            color: selected ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh

                            StateLayer {
                                radius: Tokens.rounding.medium
                                onClicked: scope.copy(item.modelData)
                            }

                            HoverHandler {
                                onHoveredChanged: if (hovered)
                                    list.currentIndex = item.index
                            }

                            StyledClippingRect {
                                id: thumb

                                visible: !!item.modelData.image
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: Tokens.padding.small
                                width: visible ? Math.min(img.implicitWidth * height / Math.max(1, img.implicitHeight), parent.width * 0.6) : 0
                                radius: Tokens.rounding.small

                                Image {
                                    id: img

                                    anchors.fill: parent
                                    source: item.modelData.image ? `file://${item.modelData.image}` : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.height: 240
                                }
                            }

                            StyledText {
                                id: text

                                anchors.left: thumb.visible ? thumb.right : parent.left
                                anchors.right: del.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Tokens.padding.medium
                                anchors.rightMargin: Tokens.padding.small
                                text: item.modelData.image ? item.modelData.preview.replace(/^\[\[ binary data /, "").replace(/ \]\]$/, "") : item.modelData.preview
                                maximumLineCount: 3
                                wrapMode: Text.WrapAnywhere
                                elide: Text.ElideRight
                                color: item.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                font: item.modelData.image ? Tokens.font.body.small : Tokens.font.body.medium
                            }

                            IconButton {
                                id: del

                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.rightMargin: Tokens.padding.small
                                icon: "delete"
                                type: IconButton.Text
                                onClicked: scope.remove(item.modelData)
                            }
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        visible: list.count === 0
                        text: lister.running ? qsTr("Loading…") : qsTr("Clipboard is empty")
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Enter copy  ·  Shift+Del delete  ·  Esc close")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            scope.toggle();
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clipboard"
        description: "Toggle clipboard history"
        onPressed: scope.toggle()
    }
}
