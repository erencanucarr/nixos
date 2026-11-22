pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string run: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string dir: `d="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")/Ekran Kayıtları"; mkdir -p "$d"`

    readonly property string recScript: `kind=$1 stamp=$2 run=$3 audio=$4; shift 4
        if [ "$kind" = gif ]; then
            f="$run/qs-rec-$stamp.mp4"; set -- "$@" -r 30
        else
            ${dir}; f="$d/$stamp.mp4"; set -- "$@" -r 60
            if [ "$audio" = 1 ]; then
                s=$(wpctl inspect @DEFAULT_AUDIO_SINK@ | sed -n 's/.*node.name = "\\(.*\\)"/\\1/p')
                [ -n "$s" ] && set -- "$@" --audio-backend=pipewire "--audio=$s.monitor"
            fi
        fi
        exec wf-recorder -y "$@" -c libx264 -p preset=veryfast -p crf=20 -x yuv420p -f "$f"`

    readonly property string saveScript: `kind=$1 stamp=$2 run=$3
        ${dir}
        if [ "$kind" = gif ]; then
            src="$run/qs-rec-$stamp.mp4"; f="$d/$stamp.gif"
            [ -s "$src" ] || exit 1
            ffmpeg -y -loglevel error -i "$src" -vf "fps=15,scale='min(960,iw)':-2:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4" "$f" || exit 1
            rm -f "$src"
            wl-copy -t image/gif < "$f"
        else
            f="$d/$stamp.mp4"
            [ -s "$f" ] || exit 1
            printf 'file://%s\\n' "$f" | sed 's/ /%20/g' | wl-copy -t text/uri-list
        fi
        rm -f "$run"/qs-rec-thumb-*.png
        t="$run/qs-rec-thumb-$stamp.png"
        ffmpeg -y -loglevel error -i "$f" -frames:v 1 -vf "scale=592:-2" "$t"
        printf '%s\\n%s' "$f" "$t"`

    property string kind: ""
    property string stamp: ""
    property bool audio: true
    property var target: []
    property bool recording: false
    property bool saving: false
    property int countdown: 0
    property int elapsed: 0
    property rect area

    readonly property bool busy: recording || saving || countdown > 0 || wait.running

    signal saved(string file, string thumb, string kind, int seconds, rect area)

    function clock(s: int): string {
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    function start(kind: string, target: var, delay: int, audio: bool, area: rect): void {
        if (root.busy)
            return;
        root.kind = kind;
        root.target = target;
        root.audio = audio;
        root.area = area;
        root.elapsed = 0;
        root.countdown = delay;
        if (delay > 0)
            tick.start();
        else
            wait.start();
    }

    function stop(): void {
        if (root.countdown > 0 || wait.running) {
            tick.stop();
            wait.stop();
            root.countdown = 0;
        } else if (root.recording) {
            rec.signal(2);
        }
    }

    function begin(): void {
        root.stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
        rec.exec(["sh", "-c", root.recScript, "sh", root.kind, root.stamp, root.run, root.audio ? "1" : "0", ...root.target]);
        root.recording = true;
    }

    IpcHandler {
        target: "rec"

        function stop(): void {
            root.stop();
        }
    }

    Timer {
        id: wait

        interval: 250
        onTriggered: root.begin()
    }

    Timer {
        id: tick

        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown -= 1;
            if (root.countdown <= 0) {
                tick.stop();
                root.begin();
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsed += 1
    }

    Process {
        id: rec

        onExited: {
            root.recording = false;
            root.saving = true;
            save.exec(["sh", "-c", root.saveScript, "sh", root.kind, root.stamp, root.run]);
        }
    }

    Process {
        id: save

        stdout: StdioCollector {
            onStreamFinished: {
                root.saving = false;
                const [file, thumb] = text.split("\n");
                if (file)
                    root.saved(file, thumb ?? "", root.kind, root.elapsed, root.area);
                else
                    Quickshell.execDetached(["notify-send", "-a", "Ekran kaydı", "Kayıt kaydedilemedi"]);
            }
        }
    }
}
