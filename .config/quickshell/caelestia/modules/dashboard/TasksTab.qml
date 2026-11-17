pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

// Tasks grouped by project.
//   Projects view: list of projects (click one to open it, type a name to create one)
//   Project view:  that project's tasks with a check toggle (click the row to tick it)
Item {
    id: root

    // "" = projects overview, otherwise the open project's id
    property string currentProject: ""
    readonly property var project: currentProject ? Todo.project(currentProject) : null
    readonly property bool inProject: project !== null

    function open(id: string): void {
        currentProject = id;
        field.text = "";
        field.forceActiveFocus();
    }

    function back(): void {
        currentProject = "";
        field.text = "";
    }

    // Project deleted from under us -> go back
    onProjectChanged: if (currentProject && !project)
        currentProject = ""

    implicitWidth: 840
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: root.inProject ? 0 : Tokens.padding.large
            Layout.rightMargin: Tokens.padding.large
            spacing: Tokens.spacing.small

            IconButton {
                Layout.alignment: Qt.AlignVCenter
                visible: root.inProject
                type: IconButton.Text
                icon: "arrow_back"
                onClicked: root.back()
            }

            Column {
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: root.inProject ? root.project.name : "Projects"
                    font: Tokens.font.body.builders.large.size(20).weight(Font.DemiBold).build()
                }

                StyledText {
                    color: Colours.palette.m3onSurfaceVariant
                    text: {
                        if (root.inProject) {
                            const p = root.project;
                            if (p.total === 0)
                                return "No tasks yet";
                            return p.open === 0 ? "All done" : `${p.open} to do · ${p.done} done`;
                        }
                        const n = Todo.projects.length;
                        if (n === 0)
                            return "No projects yet";
                        const open = Todo.count - Todo.doneCount;
                        return `${n} project${n === 1 ? "" : "s"} · ${open} open task${open === 1 ? "" : "s"}`;
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            TextButton {
                visible: root.inProject && root.project.done > 0
                type: TextButton.Text
                text: "Clear done"
                onClicked: Todo.clearDone(root.currentProject)
            }
        }

        // Input: new project / new task
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledTextField {
                id: field

                function submit(): void {
                    if (text.trim().length === 0)
                        return;
                    if (root.inProject) {
                        Todo.add(root.currentProject, text);
                        text = "";
                    } else {
                        const id = Todo.addProject(text);
                        text = "";
                        if (id)
                            root.open(id);
                    }
                }

                Layout.fillWidth: true
                verticalPadding: Tokens.padding.medium
                radius: Tokens.rounding.medium
                leadingIcon: root.inProject ? "add_task" : "create_new_folder"
                placeholderText: root.inProject ? `Add a task to ${root.project.name}` : "New project name"
                onAccepted: submit()
                Keys.onEscapePressed: event => {
                    if (root.inProject) {
                        root.back();
                        event.accepted = true;
                    } else {
                        event.accepted = false;
                    }
                }
            }

            IconButton {
                Layout.alignment: Qt.AlignVCenter
                icon: "arrow_upward"
                disabled: field.text.trim().length === 0
                onClicked: field.submit()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 300

            // ---------- Projects overview ----------
            // Created only while shown (layouts inside hidden items report 0 height,
            // which made the rows stack on top of each other)
            Loader {
                anchors.fill: parent
                active: !root.inProject

                sourceComponent: StyledListView {
                    id: projectsList

                    anchors.fill: parent
                    clip: true
                    spacing: Tokens.spacing.small

                    model: ScriptModel {
                        values: Todo.projectList
                        objectProp: "id"
                    }

                    delegate: StyledRect {
                        id: proj

                        required property var modelData
                        property bool confirmDelete

                        width: ListView.view.width
                        implicitHeight: Math.max(64, projRow.implicitHeight + Tokens.padding.medium * 2)
                        radius: Tokens.rounding.medium
                        color: Colours.tPalette.m3surfaceContainer

                        StateLayer {
                            radius: proj.radius
                            onClicked: root.open(proj.modelData.id)
                        }

                        RowLayout {
                            id: projRow

                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.large
                            anchors.rightMargin: Tokens.padding.small
                            spacing: Tokens.spacing.medium

                            StyledRect {
                                implicitWidth: implicitHeight
                                implicitHeight: folderIcon.implicitHeight + Tokens.padding.small * 2
                                radius: Tokens.rounding.full
                                color: proj.modelData.total > 0 && proj.modelData.open === 0 ? Colours.palette.m3tertiaryContainer : Colours.palette.m3primaryContainer

                                MaterialIcon {
                                    id: folderIcon

                                    anchors.centerIn: parent
                                    text: proj.modelData.total > 0 && proj.modelData.open === 0 ? "task_alt" : "folder"
                                    fill: 1
                                    color: proj.modelData.total > 0 && proj.modelData.open === 0 ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onPrimaryContainer
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.extraSmall

                                StyledText {
                                    Layout.fillWidth: true
                                    text: proj.modelData.name
                                    elide: Text.ElideRight
                                    font: Tokens.font.body.builders.large.weight(Font.Medium).build()
                                }

                                StyledText {
                                    text: {
                                        const p = proj.modelData;
                                        if (p.total === 0)
                                            return "Empty";
                                        return p.open === 0 ? `All ${p.total} done` : `${p.open} to do · ${p.done} done`;
                                    }
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.body.small
                                }

                                // Progress bar
                                StyledRect {
                                    Layout.fillWidth: true
                                    Layout.topMargin: Tokens.spacing.extraSmall
                                    visible: proj.modelData.total > 0
                                    implicitHeight: 4
                                    radius: Tokens.rounding.full
                                    color: Colours.palette.m3surfaceContainerHighest

                                    StyledRect {
                                        implicitHeight: parent.height
                                        width: parent.width * (proj.modelData.total > 0 ? proj.modelData.done / proj.modelData.total : 0)
                                        radius: Tokens.rounding.full
                                        color: Colours.palette.m3primary

                                        Behavior on width {
                                            Anim {}
                                        }
                                    }
                                }
                            }

                            // Delete: first click arms, second click deletes (with its tasks)
                            IconButton {
                                type: IconButton.Text
                                icon: proj.confirmDelete ? "delete_forever" : "delete"
                                onClicked: {
                                    if (proj.confirmDelete)
                                        Todo.removeProject(proj.modelData.id);
                                    else {
                                        proj.confirmDelete = true;
                                        disarm.restart();
                                    }
                                }

                                Timer {
                                    id: disarm

                                    interval: 2500
                                    onTriggered: proj.confirmDelete = false
                                }
                            }

                            MaterialIcon {
                                text: "chevron_right"
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: !root.inProject && Todo.projects.length === 0
                spacing: Tokens.spacing.small

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "folder_open"
                    fontStyle: Tokens.font.icon.extraLarge
                    color: Colours.palette.m3outline
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Type a project name above and press Enter"
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            // ---------- Tasks inside a project ----------
            // Created only while shown (layouts inside hidden items report 0 height,
            // which made the rows stack on top of each other)
            Loader {
                anchors.fill: parent
                active: root.inProject

                sourceComponent: StyledListView {
                    id: tasksList

                    anchors.fill: parent
                    clip: true
                    spacing: Tokens.spacing.small

                    model: ScriptModel {
                        values: root.inProject ? Todo.tasksFor(root.currentProject) : []
                        objectProp: "id"
                    }

                    delegate: StyledRect {
                        id: task

                        required property var modelData

                        width: ListView.view.width
                        implicitHeight: Math.max(48, taskRow.implicitHeight + Tokens.padding.small * 2)
                        radius: Tokens.rounding.medium
                        color: Colours.tPalette.m3surfaceContainer

                        // Whole row toggles the task
                        StateLayer {
                            radius: task.radius
                            onClicked: Todo.toggle(task.modelData.id)
                        }

                        RowLayout {
                            id: taskRow

                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.small
                            anchors.rightMargin: Tokens.padding.small
                            spacing: Tokens.spacing.small

                            IconButton {
                                type: IconButton.Text
                                icon: task.modelData.done ? "check_circle" : "radio_button_unchecked"
                                onClicked: Todo.toggle(task.modelData.id)
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: task.modelData.text
                                elide: Text.ElideRight
                                font.strikeout: task.modelData.done
                                color: task.modelData.done ? Colours.palette.m3outline : Colours.palette.m3onSurface
                            }

                            IconButton {
                                type: IconButton.Text
                                icon: "close"
                                onClicked: Todo.remove(task.modelData.id)
                            }
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: root.inProject && (root.project?.total ?? 0) === 0
                spacing: Tokens.spacing.small

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "checklist"
                    fontStyle: Tokens.font.icon.extraLarge
                    color: Colours.palette.m3outline
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Type a task above and press Enter"
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }
}
