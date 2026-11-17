pragma ComponentBehavior: Bound

// Top-bar patch: the original vertical workspace strip (WorkspacesVertical.qml)
// rotated -90deg so it runs left -> right. Labels/icons are counter-rotated in
// Workspace.qml / SpecialWorkspaces.qml so they stay upright.
import QtQuick
import Quickshell

Item {
    id: root

    required property ShellScreen screen
    required property bool fullscreen

    implicitWidth: inner.implicitHeight
    implicitHeight: inner.implicitWidth

    WorkspacesVertical {
        id: inner

        anchors.centerIn: parent
        width: implicitWidth
        height: implicitHeight
        rotation: -90

        screen: root.screen
        fullscreen: root.fullscreen
    }
}
