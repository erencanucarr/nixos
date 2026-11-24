pragma Singleton

import QtQuick
import Quickshell
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

    Timer {
        interval: 1000
        running: Mpris.players.values.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.update()
    }
}
