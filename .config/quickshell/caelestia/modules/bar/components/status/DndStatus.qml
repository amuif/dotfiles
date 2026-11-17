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
        onClicked: Notifs.dnd = !Notifs.dnd
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        animate: true
        text: Notifs.dnd ? "notifications_off" : "notifications"
        fill: Notifs.dnd ? 1 : 0
        color: Notifs.dnd ? Colours.palette.m3error : root.colour
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
