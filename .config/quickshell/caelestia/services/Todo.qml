pragma Singleton

// Task list shown in the dashboard. Saved in ~/.local/state/caelestia/todo.json
// as [{ id, text, done, created }]
import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property var items: []

    readonly property int count: items.length
    readonly property int doneCount: items.filter(i => i.done).length
    // Open tasks first (newest on top), completed ones below
    readonly property var sorted: items.slice().sort((a, b) => (a.done - b.done) || (b.created - a.created))

    function add(text: string): void {
        const t = text.trim();
        if (!t)
            return;
        const now = Date.now();
        items = items.concat([{
                id: `${now}-${Math.floor(Math.random() * 1e6)}`,
                text: t,
                done: false,
                created: now
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

    function clearDone(): void {
        items = items.filter(i => !i.done);
        save();
    }

    function save(): void {
        store.setText(JSON.stringify(items, null, 2));
    }

    FileView {
        id: store

        path: `${Paths.state}/todo.json`
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (Array.isArray(data))
                    root.items = data;
            } catch (e) {
                console.warn("Todo: could not parse saved tasks");
            }
        }
    }
}
