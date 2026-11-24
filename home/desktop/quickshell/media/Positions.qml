pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    property var tracks: ({})
    property real now: Date.now()

    function keyOf(p: var): string {
        const m = p?.metadata ?? {};
        return `${m["xesam:url"] ?? ""}|${p?.trackTitle ?? ""}`;
    }

    function broken(p: var): bool {
        return /firefox/i.test(`${p?.identity ?? ""} ${p?.desktopEntry ?? ""}`);
    }

    function reported(p: var): real {
        return p?.positionSupported && !root.broken(p) ? (p.position ?? 0) : 0;
    }

    function update(): void {
        const t = Date.now();
        const next = {};
        for (const p of Mpris.players.values) {
            const id = p.dbusName;
            const key = root.keyOf(p);
            const playing = p.isPlaying;
            const real = root.reported(p);
            let s = root.tracks[id];
            if (!s || s.key !== key)
                s = {
                    key,
                    base: real > 0.5 ? real : 0,
                    at: t,
                    playing
                };
            else if (real > 0.5)
                s = {
                    key,
                    base: real,
                    at: t,
                    playing
                };
            else if (s.playing !== playing)
                s = {
                    key,
                    base: s.playing ? s.base + (t - s.at) / 1000 : s.base,
                    at: t,
                    playing
                };
            next[id] = s;
        }
        root.tracks = next;
        root.now = t;
    }

    function get(p: var): real {
        if (!p)
            return 0;
        const real = root.reported(p);
        if (real > 0.5)
            return real;
        const s = root.tracks[p.dbusName];
        if (!s || s.key !== root.keyOf(p))
            return 0;
        return s.playing ? s.base + (root.now - s.at) / 1000 : s.base;
    }

    function seek(p: var, to: real): void {
        const s = root.tracks[p?.dbusName];
        if (!s)
            return;
        const next = Object.assign({}, root.tracks);
        next[p.dbusName] = {
            key: s.key,
            base: Math.max(0, to),
            at: Date.now(),
            playing: s.playing
        };
        root.tracks = next;
    }

    function sync(p: var, to: real): void {
        const key = root.keyOf(p);
        const next = Object.assign({}, root.tracks);
        next[p.dbusName] = {
            key,
            base: to,
            at: Date.now(),
            playing: p.isPlaying
        };
        root.tracks = next;
    }

    Process {
        id: seekWatch

        property bool seeked: false

        running: Mpris.players.values.some(p => root.broken(p))
        command: ["dbus-monitor", "--session", "type='signal',interface='org.mpris.MediaPlayer2.Player',member='Seeked'"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("member=Seeked")) {
                    seekWatch.seeked = true;
                    return;
                }
                const m = /^\s*int64 (-?\d+)/.exec(line);
                if (!seekWatch.seeked || !m)
                    return;
                seekWatch.seeked = false;
                const to = Number(m[1]) / 1e6;
                if (to <= 0.5)
                    return;
                for (const p of Mpris.players.values)
                    if (root.broken(p))
                        root.sync(p, to);
            }
        }
    }

    Timer {
        interval: 1000
        running: Mpris.players.values.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.update()
    }
}
