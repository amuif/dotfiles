pragma Singleton

// Project-grouped task list shown in the dashboard Tasks tab.
// Saved in ~/.local/state/caelestia/todo.json as
//   { projects: [{ id, name, created }], items: [{ id, project, text, done, created }] }
// The old format (a bare array of items) is migrated into an "Inbox" project on load.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property var projects: []
    property var items: []

    readonly property int count: items.length
    readonly property int doneCount: items.filter(i => i.done).length

    // Projects with their counts, newest first
    readonly property var projectList: projects.map(p => {
        const tasks = items.filter(i => i.project === p.id);
        const done = tasks.filter(i => i.done).length;
        return Object.assign({}, p, {
            total: tasks.length,
            done: done,
            open: tasks.length - done
        });
    }).sort((a, b) => b.created - a.created)

    function newId(): string {
        return `${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
    }

    function project(id: string): var {
        return projectList.find(p => p.id === id) ?? null;
    }

    // Open tasks first (newest on top), completed ones below
    function tasksFor(projectId: string): var {
        return items.filter(i => i.project === projectId).sort((a, b) => (a.done - b.done) || (b.created - a.created));
    }

    function addProject(name: string): string {
        const n = name.trim();
        if (!n)
            return "";
        const existing = projects.find(p => p.name.toLowerCase() === n.toLowerCase());
        if (existing)
            return existing.id;
        const id = newId();
        projects = projects.concat([{
                id: id,
                name: n,
                created: Date.now()
            }]);
        save();
        return id;
    }

    function renameProject(id: string, name: string): void {
        const n = name.trim();
        if (!n)
            return;
        projects = projects.map(p => p.id === id ? Object.assign({}, p, {
                name: n
            }) : p);
        save();
    }

    function removeProject(id: string): void {
        projects = projects.filter(p => p.id !== id);
        items = items.filter(i => i.project !== id);
        save();
    }

    function add(projectId: string, text: string): void {
        const t = text.trim();
        if (!t || !projectId)
            return;
        items = items.concat([{
                id: newId(),
                project: projectId,
                text: t,
                done: false,
                created: Date.now()
            }]);
        save();
    }

    function toggle(id: string): void {
        items = items.map(i => i.id === id ? Object.assign({}, i, {
                done: !i.done
            }) : i);
        save();
    }

    function remove(id: string): void {
        items = items.filter(i => i.id !== id);
        save();
    }

    function clearDone(projectId: string): void {
        items = items.filter(i => !(i.done && i.project === projectId));
        save();
    }

    function save(): void {
        store.setText(JSON.stringify({
            projects: projects,
            items: items
        }, null, 2));
    }

    FileView {
        id: store

        path: `${Paths.state}/todo.json`
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (Array.isArray(data)) {
                    // Old flat list -> Inbox project
                    if (data.length > 0) {
                        const inbox = {
                            id: root.newId(),
                            name: "Inbox",
                            created: Date.now()
                        };
                        root.projects = [inbox];
                        root.items = data.map(i => Object.assign({}, i, {
                                project: inbox.id
                            }));
                        root.save();
                    }
                } else if (data && typeof data === "object") {
                    root.projects = Array.isArray(data.projects) ? data.projects : [];
                    root.items = Array.isArray(data.items) ? data.items : [];
                }
            } catch (e) {
                console.warn("Todo: could not parse saved tasks");
            }
        }
    }
}
