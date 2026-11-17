import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar

    // Bar: show the extra (hidden) right-side icons — toggled with Super+M
    property bool barExpanded

    // Dashboard state
    property int dashboardTab
    property bool dashboardInput
    property string dashboardTabRequest
    property date dashboardDate: new Date()

    // Notification input state
    property bool notifInput
}
