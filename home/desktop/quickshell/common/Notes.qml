pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Day notes and their reminders. The calendar adds them (right click a day),
// Reminder shows them when due, and the clock marks a day that has some.
//
// Kept in ~/.local/state/can-notes.json as
//   { "2026-11-25": [{ id, text, time: "14:30" | "", reminded, snoozeUntil }] }
// and watched, so an edit by hand shows up too.
//
// A note with a time is due at that time on its day; one without, at 09:00
// (or as soon as the shell runs that day). Due notes collect in `due` until
// dismissed or snoozed.
Singleton {
    id: root

    property var notes: ({})
    // [{ date, id, text, time }], oldest first.
    property var due: []

    readonly property string untimed: "09:00"

    function key(d: date): string {
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    }

    function list(d: date): var {
        return root.notes[root.key(d)] ?? [];
    }

    // Copy, change, assign: a property var only notifies on assignment.
    function edit(dateKey: string, change: var): void {
        const all = Object.assign({}, root.notes);
        const day = (all[dateKey] ?? []).map(n => Object.assign({}, n));
        change(day);
        if (day.length > 0)
            all[dateKey] = day;
        else
            delete all[dateKey];
        root.notes = all;
        file.setText(JSON.stringify(root.notes, null, 2) + "\n");
    }

    function add(d: date, text: string, time: string): void {
        const t = text.trim();
        if (!t)
            return;
        const hm = /^([01]?\d|2[0-3])[:.]?([0-5]\d)$/.exec(time.trim());
        root.edit(root.key(d), day => {
            day.push({
                id: Date.now().toString(36),
                text: t,
                time: hm ? `${hm[1].padStart(2, "0")}:${hm[2]}` : "",
                reminded: false,
                snoozeUntil: 0
            });
            day.sort((a, b) => (a.time || root.untimed).localeCompare(b.time || root.untimed));
        });
        root.check();
    }

    function remove(dateKey: string, id: string): void {
        root.edit(dateKey, day => day.splice(day.findIndex(n => n.id === id), 1));
        root.due = root.due.filter(n => n.id !== id);
    }

    function dismiss(id: string): void {
        root.due = root.due.filter(n => n.id !== id);
    }

    function snooze(dateKey: string, id: string, minutes: int): void {
        root.edit(dateKey, day => {
            const n = day.find(n => n.id === id);
            if (n) {
                n.reminded = false;
                n.snoozeUntil = Date.now() + minutes * 60000;
            }
        });
        root.dismiss(id);
    }

    // Today's notes whose moment has come and that have not been shown.
    function check(): void {
        const now = new Date();
        const today = root.key(now);
        const hm = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
        const fresh = (root.notes[today] ?? []).filter(n => !n.reminded && (n.snoozeUntil > 0 ? Date.now() >= n.snoozeUntil : hm >= (n.time || root.untimed)));
        if (fresh.length === 0)
            return;
        root.edit(today, day => day.forEach(n => {
                if (fresh.some(f => f.id === n.id)) {
                    n.reminded = true;
                    n.snoozeUntil = 0;
                }
            }));
        root.due = root.due.concat(fresh.map(n => ({
                    date: today,
                    id: n.id,
                    text: n.text,
                    time: n.time
                })));
    }

    FileView {
        id: file

        path: `${Quickshell.env("HOME")}/.local/state/can-notes.json`
        watchChanges: true
        atomicWrites: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            try {
                root.notes = JSON.parse(text()) ?? {};
            } catch (e) {
                console.warn(`notes: ${e}`);
            }
            root.check();
        }
    }

    // qs ipc call notes add "Süt al" "18:30"   (today; the time may be "")
    // qs ipc call notes dismiss                (every reminder on screen)
    IpcHandler {
        target: "notes"

        function add(text: string, time: string): void {
            root.add(new Date(), text, time);
        }
        function dismiss(): void {
            root.due = [];
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 20000
        onTriggered: root.check()
    }
}
