pragma ComponentBehavior: Bound

// Horizontal clock for the top bar (patched from the vertical original).
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.bar.popouts as BarPopouts

StyledRect {
    id: root

    property BarPopouts.Wrapper popouts
    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.large : Tokens.padding.extraSmall

    implicitWidth: layout.implicitWidth + root.padding * 2
    implicitHeight: Tokens.sizes.bar.innerWidth

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    // Main clock area: toggles the dashboard
    StateLayer {
        anchors.fill: parent
        radius: Tokens.rounding.full
        onClicked: {
            const s = ShellState.forActive();
            s.dashboard = !s.dashboard;
        }
    }

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        Loader {
            Layout.alignment: Qt.AlignVCenter
            asynchronous: true
            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: "calendar_month"
                color: root.colour
            }
        }

        Loader {
            Layout.alignment: Qt.AlignVCenter
            asynchronous: true
            active: Config.bar.clock.showDate
            visible: active

            sourceComponent: StyledText {
                text: Time.format("ddd d MMM")
                font: Tokens.font.body.builders.small.build()
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Time.hourStr + ":" + Time.minuteStr + (Config.bar.clock.showSeconds ? ":" + Time.format("ss") : "") + (Units.twelveHourClock ? " " + Time.amPmStr.toLowerCase() : "")
            font: Tokens.font.body.builders.small.scale(1.1).weight(Font.DemiBold).build()
            color: root.colour
        }
    }
}
