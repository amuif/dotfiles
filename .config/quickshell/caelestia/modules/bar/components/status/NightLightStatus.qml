import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property color colour

    implicitWidth: icon.implicitWidth + Tokens.padding.extraSmall
    implicitHeight: icon.implicitHeight

    StateLayer {
        anchors.fill: parent
        radius: Tokens.rounding.full
        onClicked: NightLight.toggle()
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        animate: true
        text: "bedtime"
        fill: NightLight.enabled ? 1 : 0
        color: NightLight.enabled ? Colours.palette.m3primary : root.colour
        fontStyle: Tokens.font.icon.medium

        Behavior on color {
            CAnim {}
        }

        Behavior on fill {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
