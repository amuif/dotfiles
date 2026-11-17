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
        onClicked: NightLight.toggle()
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: "bedtime"
        fill: NightLight.enabled ? 1 : 0
        color: NightLight.enabled ? Colours.palette.m3primary : Colours.palette.m3secondary
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
