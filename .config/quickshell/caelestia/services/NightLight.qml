pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.services

Singleton {
    id: root

    property alias enabled: props.enabled

    readonly property string shaderPath: `${Quickshell.env("HOME")}/.config/hypr/shaders/nightlight.frag`
    readonly property string scriptPath: `${Quickshell.env("HOME")}/.config/hypr/scripts/nightlight.sh`

    function toggle() {
        props.enabled = !props.enabled;
    }

    function applyState() {
        applyProc.exec([root.scriptPath, enabled ? "on" : "off"]);
    }

    onEnabledChanged: {
        applyState();
        if (enabled)
            Toaster.toast(Tr.tr("Night light enabled"), Tr.tr("Blue light filter turned on"), "bedtime");
        else
            Toaster.toast(Tr.tr("Night light disabled"), Tr.tr("Screen colors restored"), "bedtime");
    }

    PersistentProperties {
        id: props

        property bool enabled

        reloadableId: "nightLight"
    }

    Process {
        id: applyProc
    }

    Connections {
        function onConfigReloaded() {
            if (props.enabled)
                root.applyState();
        }

        target: Hypr
    }

    Component.onCompleted: {
        if (props.enabled)
            root.applyState();
    }

    IpcHandler {
        function isEnabled() {
            return props.enabled;
        }

        function toggle() {
            root.toggle();
        }

        function enable() {
            props.enabled = true;
        }

        function disable() {
            props.enabled = false;
        }

        target: "nightLight"
    }
}
