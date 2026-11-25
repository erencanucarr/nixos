pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    property var tracks: ({})
    property real now: Date.now()
    property int watchers: 0

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

    function put(id: string, s: var): void {
        const next = Object.assign({}, root.tracks);
        if (s)
            next[id] = s;
        else
            delete next[id];
        root.tracks = next;
    }

    function record(p: var): void {
        if (!p)
            return;
        const t = Date.now();
        const key = root.keyOf(p);
        const playing = p.isPlaying;
        const real = root.reported(p);
        const s = root.tracks[p.dbusName];
        if (!s || s.key !== key || real > 0.5)
            root.put(p.dbusName, {
                key,
                base: real > 0.5 ? real : 0,
                at: t,
                playing
            });
        else if (s.playing !== playing)
            root.put(p.dbusName, {
                key,
                base: s.playing ? s.base + (t - s.at) / 1000 : s.base,
                at: t,
                playing
            });
    }

    function get(p: var): real {
        if (!p)
            return 0;
        const t = Math.max(root.now, Date.now());
        const real = root.reported(p);
        if (real > 0.5)
            return real;
        const s = root.tracks[p.dbusName];
        if (!s || s.key !== root.keyOf(p))
            return 0;
        return s.playing ? s.base + (t - s.at) / 1000 : s.base;
    }

    function seek(p: var, to: real): void {
        const s = root.tracks[p?.dbusName];
        if (!s)
            return;
        root.put(p.dbusName, {
            key: s.key,
            base: Math.max(0, to),
            at: Date.now(),
            playing: s.playing
        });
    }

    function sync(p: var, to: real): void {
        root.put(p.dbusName, {
            key: root.keyOf(p),
            base: to,
            at: Date.now(),
            playing: p.isPlaying
        });
    }

    Instantiator {
        model: Mpris.players

        delegate: Connections {
            id: watch

            required property MprisPlayer modelData
            property string bus: ""

            target: watch.modelData

            function onIsPlayingChanged(): void {
                root.record(watch.modelData);
            }

            function onTrackTitleChanged(): void {
                root.record(watch.modelData);
            }

            function onMetadataChanged(): void {
                root.record(watch.modelData);
            }

            Component.onCompleted: {
                watch.bus = watch.modelData?.dbusName ?? "";
                root.record(watch.modelData);
            }
            Component.onDestruction: root.put(watch.bus, null)
        }
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
        running: root.watchers > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }
}
