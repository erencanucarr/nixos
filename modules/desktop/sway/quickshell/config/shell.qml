//@ pragma UseQApplication

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.I3
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    // ---- palette ---------------------------------------------------------
    readonly property color bg:        "#000000"
    readonly property color chip:      "#0a0a0a"
    readonly property color chipHover: "#161616"
    readonly property color chipOn:    "#1e1e22"
    readonly property color fg:        "#A0A0A0"   // primary text (muted silver)
    readonly property color muted:     "#333333"   // inactive text (deep charcoal)
    readonly property color line:      "#1f1f22"
    readonly property color accent:    "#FFFFFF"   // stark white — toggled/active
    readonly property color warn:      "#666666"   // mid gray — battery low (blinks)
    readonly property color danger:    "#e46876"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    // ---- state -----------------------------------------------------------
    property bool idleInhibited: false
    property string netIface: ""
    property string netKind: ""
    property string netLabel: ""
    property string netIcon:  "\u{F0C9B}"   // md-network-off (default)
    property string netIp: "—"
    property string netPublicIp: "—"
    property string netGateway: "—"
    property string netDns: "—"
    property string netRxRate: "—"
    property string netTxRate: "—"
    property string netRxTotal: "—"
    property string netTxTotal: "—"
    property string netPing: "—"
    property string netLoss: "—"
    property real netRxPrev: 0
    property real netTxPrev: 0
    property real netLastAt: 0
    property bool networkOpen: false
    property bool calendarOpen: false
    property bool audioOpen: false
    property var audioSinks: []
    property var audioSources: []
    property var audioStreams: []
    property string audioDefaultSinkName: "—"
    property string audioDefaultSinkVol: "—"
    property bool audioDefaultSinkMuted: false
    readonly property var mediaPlayer: {
        const list = Mpris.players ? Mpris.players.values : []
        for (const p of list) {
            if (p && (p.canControl === undefined || p.canControl)) return p
        }
        return null
    }
    readonly property string mediaTitle: mediaPlayer && mediaPlayer.trackTitle ? mediaPlayer.trackTitle : ""
    readonly property string mediaArtists: {
        if (!mediaPlayer) return ""
        const artists = mediaPlayer.trackArtists
        if (Array.isArray(artists)) return artists.join(", ")
        return artists || ""
    }
    readonly property bool mediaPlaying: mediaPlayer && (mediaPlayer.isPlaying === true
        || (mediaPlayer.playbackState !== undefined && mediaPlayer.playbackState === MprisPlaybackState.Playing))

    function formatBytes(bytes, suffix) {
        let n = Number(bytes) || 0
        const units = ["B", "KB", "MB", "GB", "TB"]
        let i = 0
        while (n >= 1024 && i < units.length - 1) { n /= 1024; i++ }
        const value = i === 0 ? String(Math.round(n)) : n.toFixed(n >= 100 ? 0 : n >= 10 ? 1 : 2)
        return value + " " + units[i] + suffix
    }

    function updateNetCounters(rx, tx) {
        const now = Date.now()
        root.netRxTotal = root.formatBytes(rx, "")
        root.netTxTotal = root.formatBytes(tx, "")
        if (root.netLastAt > 0 && rx >= root.netRxPrev && tx >= root.netTxPrev) {
            const seconds = Math.max(1, (now - root.netLastAt) / 1000)
            root.netRxRate = root.formatBytes((rx - root.netRxPrev) / seconds, "/s")
            root.netTxRate = root.formatBytes((tx - root.netTxPrev) / seconds, "/s")
        }
        root.netRxPrev = rx
        root.netTxPrev = tx
        root.netLastAt = now
    }

    function daysInMonth(date) {
        return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate()
    }

    function firstDayOffset(date) {
        const day = new Date(date.getFullYear(), date.getMonth(), 1).getDay()
        return day === 0 ? 6 : day - 1
    }

    function audioPercent(vol) {
        return Math.round((Number(vol) || 0) * 100) + "%"
    }

    function closePopupsExcept(name) {
        if (name !== "audio") root.audioOpen = false
        if (name !== "network") root.networkOpen = false
        if (name !== "calendar") root.calendarOpen = false
        if (name !== "notif") root.notifOpen = false
    }

    function refreshAudio() {
        audioProc.running = true
    }

    function bumpPercentText(text, delta) {
        const current = parseInt(text) || 0
        const step = parseInt(delta) || 5
        const next = delta.indexOf("-") >= 0 ? Math.max(0, current - step) : Math.min(150, current + step)
        return next + "%"
    }

    function patchStream(id, fn) {
        let next = []
        for (const s of root.audioStreams) {
            let copy = {
                kind: s.kind,
                id: s.id,
                active: s.active,
                name: s.name,
                vol: s.vol,
                muted: s.muted,
            }
            if (String(copy.id) === String(id)) fn(copy)
            next.push(copy)
        }
        root.audioStreams = next
    }

    function setAudioDefault(id) {
        Quickshell.execDetached(["wpctl", "set-default", String(id)])
        audioRefreshTimer.restart()
    }

    function changeAudioVolume(target, delta) {
        Quickshell.execDetached(["wpctl", "set-volume", String(target), delta])
        if (String(target) === "@DEFAULT_AUDIO_SINK@") {
            root.audioDefaultSinkMuted = false
            root.audioDefaultSinkVol = root.bumpPercentText(root.audioDefaultSinkVol, delta)
        } else {
            root.patchStream(target, s => {
                s.muted = false
                const pct = root.bumpPercentText(root.audioPercent(s.vol), delta)
                s.vol = String((parseInt(pct) || 0) / 100)
            })
        }
        audioRefreshTimer.restart()
    }

    function toggleAudioMute(target) {
        Quickshell.execDetached(["wpctl", "set-mute", String(target), "toggle"])
        if (String(target) === "@DEFAULT_AUDIO_SINK@") {
            root.audioDefaultSinkMuted = !root.audioDefaultSinkMuted
        } else {
            root.patchStream(target, s => s.muted = !s.muted)
        }
        audioRefreshTimer.restart()
    }

    function toggleMedia() {
        if (!root.mediaPlayer) return
        if (root.mediaPlayer.togglePlaying) root.mediaPlayer.togglePlaying()
        else if (root.mediaPlaying && root.mediaPlayer.pause) root.mediaPlayer.pause()
        else if (root.mediaPlayer.play) root.mediaPlayer.play()
    }

    function stopMedia() {
        if (root.mediaPlayer && root.mediaPlayer.stop) root.mediaPlayer.stop()
        else if (root.mediaPlayer && root.mediaPlayer.pause) root.mediaPlayer.pause()
    }

    // ---- notifications ---------------------------------------------------
    // IPC-driven state (super+k / DND toggle in center / bar chip).
    property bool notifOpen: false
    property bool dnd:       false
    // Short-lived toast queue. Each entry = { n: Notification, expiresAt: ms }.
    property var activeToasts: []
    function removeToast(target) {
        root.activeToasts = root.activeToasts.filter(t => t && t.n && t.n !== target)
    }

    NotificationServer {
        id: notifServer
        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: true
        persistenceSupported: true
        onNotification: n => {
            if (root.dnd) { n.dismiss(); return }
            n.tracked = true
            const to = (n.expireTimeout && n.expireTimeout > 0) ? n.expireTimeout : 5000
            root.activeToasts = root.activeToasts.concat([{ n: n, expiresAt: Date.now() + to }])
        }
    }
    Timer {
        interval: 500; running: true; repeat: true
        onTriggered: {
            const now = Date.now()
            const kept = root.activeToasts.filter(t => t && t.n && t.expiresAt > now)
            if (kept.length !== root.activeToasts.length) root.activeToasts = kept
        }
    }

    // IPC: `qs ipc call notif toggle | open | close | toggleDnd | dismissAll`
    IpcHandler {
        target: "notif"
        function toggle():     void { root.closePopupsExcept("notif"); root.notifOpen = !root.notifOpen }
        function open():       void { root.closePopupsExcept("notif"); root.notifOpen = true }
        function close():      void { root.notifOpen = false }
        function toggleDnd():  void { root.dnd = !root.dnd }
        function dismissAll(): void {
            for (const n of notifServer.trackedNotifications.values.slice()) n.dismiss()
        }
    }

    // ---- network poller (nmcli) ------------------------------------------
    Process {
        id: netProc
        running: true
        command: ["bash", "-lc",
            "entry=$(nmcli -t -f DEVICE,STATE,CONNECTION,TYPE device status 2>/dev/null | awk -F: '$2==\"connected\" && $4!=\"loopback\" {print $1\"\\t\"$4\"\\t\"$3; exit}'); " +
            "[ -z \"$entry\" ] && exit 0; " +
            "iface=$(printf '%s' \"$entry\" | cut -f1); " +
            "kind=$(printf '%s' \"$entry\" | cut -f2); " +
            "name=$(printf '%s' \"$entry\" | cut -f3-); " +
            "ipaddr=$(ip -o -4 addr show dev \"$iface\" scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1); " +
            "gw=$(ip route show default dev \"$iface\" 2>/dev/null | awk 'NR==1 {print $3}'); " +
            "dns=$(resolvectl dns \"$iface\" 2>/dev/null | sed 's/.*: //;q'); " +
            "rx=$(cat /sys/class/net/\"$iface\"/statistics/rx_bytes 2>/dev/null || echo 0); " +
            "tx=$(cat /sys/class/net/\"$iface\"/statistics/tx_bytes 2>/dev/null || echo 0); " +
            "printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$iface\" \"$kind\" \"$name\" \"${ipaddr:-—}\" \"${gw:-—}\" \"${dns:-—}\" \"$rx\" \"$tx\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim()
                if (!line) {
                    root.netIface = ""; root.netKind = ""; root.netLabel = ""; root.netIcon = "\u{F0C9B}"
                    root.netIp = "—"; root.netGateway = "—"; root.netDns = "—"
                    root.netRxRate = "—"; root.netTxRate = "—"; root.netRxTotal = "—"; root.netTxTotal = "—"
                    root.netRxPrev = 0; root.netTxPrev = 0; root.netLastAt = 0
                    return
                }
                const parts = line.split("\t")
                const iface = parts[0] || ""
                const kind = parts[1] || ""
                const name = parts[2] || ""
                root.netIface = iface
                root.netKind = kind
                root.netLabel = name || ""
                root.netIp = parts[3] || "—"
                root.netGateway = parts[4] || "—"
                root.netDns = parts[5] || "—"
                root.updateNetCounters(Number(parts[6] || 0), Number(parts[7] || 0))
                if (kind === "wifi" || kind === "wireless")     root.netIcon = ""  // wifi
                else if (kind === "ethernet" || kind === "tun") root.netIcon = "󰈀"  // ethernet
                else                                            root.netIcon = "󰇨"  // globe/off
            }
        }
    }
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: netProc.running = true
    }

    Process {
        id: pingProc
        running: true
        command: ["sh", "-c",
            "out=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null); " +
            "loss=$(printf '%s\\n' \"$out\" | awk -F', ' '/packet loss/ {print $3}'); " +
            "rtt=$(printf '%s\\n' \"$out\" | awk -F'/' '/min\\/avg\\/max/ {printf \"%.1f ms\", $3}'); " +
            "printf '%s\\t%s\\n' \"${rtt:-—}\" \"${loss:-100%}\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("\t")
                root.netPing = parts[0] || "—"
                root.netLoss = parts[1] || "—"
            }
        }
    }
    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: pingProc.running = true
    }

    Process {
        id: publicIpProc
        running: true
        command: ["sh", "-c", "curl -fsS --max-time 3 ifconfig.me 2>/dev/null || printf '—'"]
        stdout: StdioCollector {
            onStreamFinished: root.netPublicIp = text.trim() || "—"
        }
    }
    Timer {
        interval: 300000; running: true; repeat: true
        onTriggered: publicIpProc.running = true
    }

    // ---- idle inhibit (systemd-inhibit) ----------------------------------
    Process {
        id: inhibitProc
        running: root.idleInhibited
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=quickshell",
                  "--why=user-toggled", "--mode=block", "sleep", "infinity"]
    }

    // ---- audio tracker ---------------------------------------------------
    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }

    Process {
        id: audioProc
        running: true
        command: ["sh", "-c",
            "tmp=$(mktemp); " +
            "wpctl status 2>/dev/null | awk '" +
            "/^[[:space:]]*├─ Sinks:/ {sec=\"sink\"; next} " +
            "/^[[:space:]]*├─ Sources:/ {sec=\"source\"; next} " +
            "/^[[:space:]]*└─ Streams:/ {sec=\"stream\"; next} " +
            "/^[[:space:]]*├─/ {sec=\"\"; next} " +
            "(sec==\"sink\" || sec==\"source\") && match($0, /([* ]) *([0-9]+)\\. (.*) \\[vol: ([0-9.]+)( MUTED)?\\]/, m) { " +
            "active=(index($0, \"*\") ? \"1\" : \"0\"); name=m[3]; sub(/[[:space:]]+$/, \"\", name); " +
            "print sec \"\\t\" m[2] \"\\t\" active \"\\t\" name \"\\t\" m[4] \"\\t\" (m[5] ? \"1\" : \"0\"); next } " +
            "sec==\"stream\" && $0 !~ />/ && match($0, /^[[:space:]]*([0-9]+)\\. (.*[^[:space:]])[[:space:]]*$/, m) { " +
            "name=m[2]; sub(/[[:space:]]+$/, \"\", name); print \"stream\\t\" m[1] \"\\t0\\t\" name \"\\t0\\t0\" }' > \"$tmp\"; " +
            "while IFS=$'\\t' read -r kind id active name vol muted; do " +
            "if [ \"$kind\" = stream ]; then gv=$(wpctl get-volume \"$id\" 2>/dev/null); vol=$(printf '%s' \"$gv\" | awk '{print $2}'); printf '%s' \"$gv\" | grep -q MUTED && muted=1; fi; " +
            "printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$kind\" \"$id\" \"$active\" \"$name\" \"${vol:-0}\" \"${muted:-0}\"; " +
            "done < \"$tmp\"; rm -f \"$tmp\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().length > 0 ? text.trim().split("\n") : []
                let sinks = []
                let sources = []
                let streams = []
                for (const line of lines) {
                    const p = line.split("\t")
                    if (p.length < 6) continue
                    const item = {
                        kind: p[0],
                        id: p[1],
                        active: p[2] === "1",
                        name: p[3],
                        vol: p[4],
                        muted: p[5] === "1",
                    }
                    if (item.kind === "sink") sinks.push(item)
                    else if (item.kind === "source") sources.push(item)
                    else if (item.kind === "stream") streams.push(item)
                }
                root.audioSinks = sinks
                root.audioSources = sources
                root.audioStreams = streams
                const activeSink = sinks.find(s => s.active) || sinks[0]
                root.audioDefaultSinkName = activeSink ? activeSink.name : "—"
                root.audioDefaultSinkVol = activeSink ? root.audioPercent(activeSink.vol) : "—"
                root.audioDefaultSinkMuted = activeSink ? activeSink.muted : false
            }
        }
    }

    Timer {
        interval: 3000; running: true; repeat: true
        onTriggered: audioProc.running = true
    }

    Timer {
        id: audioRefreshTimer
        interval: 350; repeat: false
        onTriggered: audioProc.running = true
    }

    // ---- system clock ----------------------------------------------------
    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ---- one bar per screen ----------------------------------------------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData
            WlrLayershell.namespace: "quickshell-bar"

            anchors { top: true; left: true; right: true }
            implicitHeight: 34
            color: root.bg


            // ---- layout --------------------------------------------------
            // Anchor-positioned so the title is truly centered on the bar,
            // not centered between left and right groups (which are unequal).
            Item {
                anchors.fill: parent

                Row {
                    id: leftRow
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 20
                    Workspaces { rootRef: root }
                    MprisChip { rootRef: root }
                }

                Text {
                    id: titleText
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(
                        implicitWidth,
                        parent.width - 2 * Math.max(leftRow.width, rightRow.width) - 24)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    color: root.fg
                    font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold }
                    text: {
                        const t = ToplevelManager.activeToplevel
                        return t && t.title ? t.title : ""
                    }
                }

                Row {
                    id: rightRow
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    Chip { rootRef: root; props: idleInhibitorC }
                    Chip { rootRef: root; props: soundC }
                    Chip { rootRef: root; props: networkC }
                    Chip { rootRef: root; props: dateC }
                    Chip { rootRef: root; props: batteryC }
                    Chip { rootRef: root; props: notifC }
                    SystemTrayChip { rootRef: root; barRef: bar }
                }
            }

            // ---- module property bags -----------------------------------
            // All MDI codepoints; SFPro Nerd Font renders them via the
            // Material Design set. Written as \u{XXXXX} escapes.
            QtObject {
                id: idleInhibitorC
                readonly property string icon: root.idleInhibited
                    ? "\u{F0176}"   // md-coffee
                    : "\u{F0FAA}"   // md-power-sleep
                readonly property string text: ""
                readonly property string tone: root.idleInhibited ? "on" : "normal"
                property var onClick: () => root.idleInhibited = !root.idleInhibited
                property var onClickRight: null
            }

            QtObject {
                id: soundC
                readonly property var sink: Pipewire.defaultAudioSink
                readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
                readonly property bool muted: !sink || !sink.audio || sink.audio.muted
                readonly property string icon: muted        ? "\u{F075F}"   // volume-off
                                              : vol > 0.66  ? "\u{F057E}"   // volume-high
                                              :               "\u{F0580}"   // volume-medium
                readonly property string text: muted ? "muted" : Math.round(vol * 100) + "%"
                readonly property string tone: muted ? "on" : "normal"
                property var onClick: () => {
                    root.closePopupsExcept("audio")
                    root.audioOpen = !root.audioOpen
                    root.refreshAudio()
                }
                property var onClickRight: () => {
                    root.toggleAudioMute("@DEFAULT_AUDIO_SINK@")
                }
            }

            QtObject {
                id: batteryC
                readonly property var dev: {
                    const list = UPower.devices ? UPower.devices.values : []
                    for (const d of list) {
                        if (d && d.nativePath && d.nativePath.indexOf("battery_") === 0)
                            return d
                    }
                    return UPower.displayDevice
                }
                readonly property bool ok: dev && dev.isPresent
                readonly property int pct: ok ? Math.round(dev.percentage * 100) : 0
                readonly property bool charging: ok && (
                    dev.state === UPowerDeviceState.Charging ||
                    dev.state === UPowerDeviceState.FullyCharged)
                readonly property string icon: !ok ? "\u{F008E}"   // battery-outline (unknown)
                    : charging   ? "\u{F0084}"   // battery-charging
                    : pct <= 10  ? "\u{F0083}"   // battery-alert
                    : pct <= 20  ? "\u{F007B}"   // battery-20
                    : pct <= 40  ? "\u{F007D}"   // battery-40
                    : pct <= 60  ? "\u{F007F}"   // battery-60
                    : pct <= 80  ? "\u{F0081}"   // battery-80
                    :              "\u{F0079}"   // battery (full)
                readonly property string text: ok ? pct + "%" : "—"
                readonly property string tone:
                    !ok            ? "normal"
                    : charging     ? "on"
                    : pct <= 15    ? "danger"
                    : pct <= 30    ? "warn"
                    :                "normal"
                property var onClick: null
                property var onClickRight: null
            }

            QtObject {
                id: networkC
                readonly property string icon: root.netIcon
                readonly property string text: root.netLabel
                readonly property string tone: "normal"
                property var onClick: () => {
                    root.closePopupsExcept("network")
                    root.networkOpen = !root.networkOpen
                }
                property var onClickRight: () => {
                    root.closePopupsExcept("network")
                    root.networkOpen = !root.networkOpen
                }
            }

            QtObject {
                id: dateC
                readonly property string icon: "\u{F00ED}"   // md-calendar-today
                readonly property string text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
                readonly property string tone: "normal"
                property var onClick: () => {
                    root.closePopupsExcept("calendar")
                    root.calendarOpen = !root.calendarOpen
                }
                property var onClickRight: () => {
                    root.closePopupsExcept("calendar")
                    root.calendarOpen = !root.calendarOpen
                }
            }

            QtObject {
                id: notifC
                readonly property int count: notifServer.trackedNotifications.values.length
                readonly property string icon: root.dnd
                    ? "\u{F009B}"   // md-bell-off
                    : "\u{F009A}"   // md-bell
                readonly property string text: count > 0 ? String(count) : ""
                readonly property string tone: (root.dnd || count > 0) ? "on" : "normal"
                property var onClick:      () => root.notifOpen = !root.notifOpen
                property var onClickRight: () => root.dnd = !root.dnd
            }
        }
    }

    // ---- toast popups (one panel per screen, overlay, non-exclusive) ----
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: toastWin
            required property var modelData
            screen: modelData
            WlrLayershell.namespace: "quickshell-toasts"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: 0
            anchors { top: true; right: true }
            margins { top: 40; right: 12 }
            color: "transparent"
            implicitWidth: 380
            implicitHeight: Math.max(1, toastCol.implicitHeight + 4)
            // Suppress toasts while the notification center is open — the
            // same entry already renders in the shade list.
            visible: root.activeToasts.length > 0 && !root.notifOpen

            Column {
                id: toastCol
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.activeToasts
                    delegate: Rectangle {
                        id: toastCard
                        required property var modelData
                        readonly property var n: modelData ? modelData.n : null
                        width: parent.width
                        implicitHeight: Math.max(60, tLayout.implicitHeight + 20)
                        color: root.chip
                        border { color: root.line; width: 1 }
                        visible: n !== null
                        opacity: 0
                        Component.onCompleted: opacity = 1
                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        RowLayout {
                            id: tLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Item {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.alignment: Qt.AlignTop
                                visible: tImg.status === Image.Ready && tImg.source != ""
                                Image {
                                    id: tImg
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                    source: {
                                        const nn = toastCard.n
                                        if (!nn || nn.summary === "Screenshot" || nn.appName === "Screenshot") return ""
                                        if (nn.image) return nn.image
                                        const a = nn.appIcon || ""
                                        if (!a) return ""
                                        if (a.charAt(0) === "/" || a.indexOf("file:") === 0) return a
                                        return Quickshell.iconPath(a, true)
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text {
                                        Layout.fillWidth: true
                                        text: toastCard.n
                                            ? (toastCard.n.summary || toastCard.n.appName || "")
                                            : ""
                                        color: root.accent
                                        font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold }
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: "×"
                                        color: closeMa.containsMouse ? root.accent : root.fg
                                        font { family: root.fontFamily; pixelSize: 16; weight: Font.Bold }
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        MouseArea {
                                            id: closeMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (toastCard.n) root.removeToast(toastCard.n)
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: toastCard.n && toastCard.n.body ? toastCard.n.body : ""
                                    color: root.fg
                                    font { family: root.fontFamily; pixelSize: 11; weight: Font.Bold }
                                    wrapMode: Text.WordWrap
                                    textFormat: Text.RichText
                                    visible: text.length > 0
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    visible: toastCard.n && toastCard.n.actions && toastCard.n.actions.length > 0
                                    Repeater {
                                        model: toastCard.n ? toastCard.n.actions : []
                                        delegate: Rectangle {
                                            required property var modelData
                                            property bool hover: false
                                            implicitHeight: 22
                                            implicitWidth: aLbl2.implicitWidth + 14
                                            color: hover ? root.chipHover : root.chipOn
                                            border { color: root.line; width: 1 }
                                            radius: 2
                                            Text {
                                                id: aLbl2
                                                anchors.centerIn: parent
                                                text: modelData.text || modelData.identifier || "action"
                                                color: hover ? root.accent : root.fg
                                                font { family: root.fontFamily; pixelSize: 11; weight: Font.Bold }
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onEntered: parent.hover = true
                                                onExited:  parent.hover = false
                                                onClicked: {
                                                    modelData.invoke()
                                                    if (toastCard.n) root.removeToast(toastCard.n)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- audio popup -----------------------------------------------------
    Variants {
        model: Quickshell.screens
        AudioPopup { rootRef: root }
    }

    // ---- calendar popup --------------------------------------------------
    Variants {
        model: Quickshell.screens
        CalendarPopup { rootRef: root; clockRef: clock }
    }

    // ---- network details popup ------------------------------------------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: networkShade
            required property var modelData
            screen: modelData
            WlrLayershell.namespace: "quickshell-network-shade"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: 0
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors { top: true; left: true; right: true; bottom: true }
            margins { top: 34 }
            color: "transparent"
            visible: root.networkOpen

            MouseArea {
                anchors.fill: parent
                onClicked: root.networkOpen = false
            }

            Rectangle {
                id: networkBox
                x: parent.width - width - 12
                y: 8
                width: 460
                height: 300
                color: root.chip
                border { color: "#8A8A8A"; width: 2 }
                radius: 7
                MouseArea { anchors.fill: parent; onClicked: {} }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            color: root.chipOn
                            border { color: root.line; width: 1 }
                            radius: 3
                            Text {
                                anchors.centerIn: parent
                                text: root.netIcon
                                color: root.accent
                                font { family: root.fontFamily; pixelSize: 18; weight: Font.Bold }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: root.netKind === "wifi" || root.netKind === "wireless" ? "Wi-Fi" : "Ethernet"
                                color: root.accent
                                font { family: root.fontFamily; pixelSize: 20; weight: Font.Bold }
                            }
                            Text {
                                text: root.netLabel.length > 0 ? root.netLabel.toUpperCase() : "ROUTING CRUMBS"
                                color: root.fg
                                font { family: root.fontFamily; pixelSize: 11; weight: Font.Bold }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: speedLabel.implicitWidth + 18
                            Layout.preferredHeight: 28
                            color: "transparent"
                            border { color: "#6A6A6A"; width: 1 }
                            radius: 8
                            Text {
                                id: speedLabel
                                anchors.centerIn: parent
                                text: root.netIface.length > 0 ? root.netIface : "offline"
                                color: root.fg
                                font { family: root.fontFamily; pixelSize: 14; weight: Font.Bold }
                            }
                        }

                        Rectangle {
                            property bool hover: false
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 28
                            color: hover ? root.chipHover : "transparent"
                            border { color: "#6A6A6A"; width: 1 }
                            radius: 8
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: root.accent
                                font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: parent.hover = true
                                onExited: parent.hover = false
                                onClicked: {
                                    root.networkOpen = false
                                    Quickshell.execDetached(["nm-connection-editor"])
                                }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        rowSpacing: 7
                        columnSpacing: 16

                        Text { text: "Ping"; color: root.fg; font { family: root.fontFamily; pixelSize: 13 } }
                        Text { text: root.netPing; color: root.accent; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold } }
                        Text { text: "Loss"; color: root.fg; font { family: root.fontFamily; pixelSize: 13 } }
                        Text { text: root.netLoss; color: root.accent; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold } }

                        Text { text: "Down"; color: root.fg; font { family: root.fontFamily; pixelSize: 13 } }
                        Text { text: root.netRxRate; color: root.accent; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold } }
                        Text { text: "Up"; color: root.fg; font { family: root.fontFamily; pixelSize: 13 } }
                        Text { text: root.netTxRate; color: root.accent; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold } }

                        Text { text: "Total ↓"; color: root.fg; font { family: root.fontFamily; pixelSize: 13 } }
                        Text { text: root.netRxTotal; color: root.accent; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold } }
                        Text { text: "Total ↑"; color: root.fg; font { family: root.fontFamily; pixelSize: 13 } }
                        Text { text: root.netTxTotal; color: root.accent; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold } }

                        Text { text: "LAN"; color: root.fg; font { family: root.fontFamily; pixelSize: 13 } }
                        Text { text: root.netIp; color: root.accent; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold } }
                        Text { text: "WAN"; color: root.fg; font { family: root.fontFamily; pixelSize: 13 } }
                        Text { text: root.netPublicIp; color: root.accent; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold } }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: root.line }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "SPEED TEST"
                            color: root.fg
                            font { family: root.fontFamily; pixelSize: 12; weight: Font.Bold }
                        }
                        Rectangle {
                            Layout.preferredWidth: 58
                            Layout.preferredHeight: 32
                            color: "transparent"
                            border { color: "#6A6A6A"; width: 1 }
                            radius: 8
                            Text {
                                anchors.centerIn: parent
                                text: "Run"
                                color: root.accent
                                font { family: root.fontFamily; pixelSize: 13 }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        columnSpacing: 8
                        Text {
                            Layout.columnSpan: 2
                            text: "DNS PROVIDER"
                            color: root.fg
                            font { family: root.fontFamily; pixelSize: 12; weight: Font.Bold }
                        }
                        Text {
                            Layout.columnSpan: 2
                            Layout.alignment: Qt.AlignRight
                            text: root.netDns
                            color: root.fg
                            elide: Text.ElideMiddle
                            font { family: root.fontFamily; pixelSize: 11; weight: Font.Bold }
                        }

                        Repeater {
                            model: ["DHCP", "Cloudflare", "Google", "Custom"]
                            delegate: Rectangle {
                                required property string modelData
                                property bool hover: false
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                color: modelData === "Cloudflare" ? root.chipOn : (hover ? root.chipHover : "transparent")
                                border { color: "#6A6A6A"; width: 1 }
                                radius: 7
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: root.accent
                                    font { family: root.fontFamily; pixelSize: 12 }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: parent.hover = true
                                    onExited: parent.hover = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- notification center: fullscreen click-catch overlay ----------
    Variants {
        model: Quickshell.screens
        NotificationCenter { rootRef: root; notificationServer: notifServer }
    }
}
