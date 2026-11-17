import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    StateLayer {
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full
        onClicked: Notifs.dnd = !Notifs.dnd
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: Notifs.dnd ? "notifications_off" : "notifications"
        fill: Notifs.dnd ? 1 : 0
        color: Notifs.dnd ? Colours.palette.m3error : Colours.palette.m3secondary
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Medium).build()

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
