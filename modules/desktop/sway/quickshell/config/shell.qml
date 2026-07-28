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
        function toggle():     void { root.networkOpen = false; root.calendarOpen = false; root.notifOpen = !root.notifOpen }
        function open():       void { root.networkOpen = false; root.calendarOpen = false; root.notifOpen = true }
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
        command: ["sh", "-c",
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
                    Workspaces { }
                    MprisChip { }
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

                    Chip { props: idleInhibitorC }
                    Chip { props: soundC }
                    Chip { props: networkC }
                    Chip { props: dateC }
                    Chip { props: batteryC }
                    Chip { props: notifC }
                    SystemTrayChip { }
                }
            }

            // ---- workspaces (sway = i3ipc) -------------------------------
            // Bare text with an accent-color animated underline for focused.
            component Workspaces: Row {
                spacing: 16
                Repeater {
                    model: I3.workspaces
                    delegate: Item {
                        required property I3Workspace modelData
                        readonly property bool focused: modelData.focused
                        readonly property bool urgent:  modelData.urgent

                        implicitWidth: Math.max(wsLabel.implicitWidth, 8)
                        implicitHeight: 20

                        Text {
                            id: wsLabel
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            color: urgent                ? root.danger
                                 : focused               ? root.accent
                                 : wsMouse.containsMouse ? root.accent
                                 :                         "#6A6A6A"   // brighter than palette muted for legibility
                            font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold }
                            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        Rectangle {
                            id: wsUnderline
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: -2
                            width: focused ? Math.max(wsLabel.implicitWidth, 6) : 0
                            height: 2
                            radius: 1
                            color: urgent ? root.danger : root.accent
                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: wsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.activate()
                        }
                    }
                }
            }

            // ---- shared chip component -----------------------------------
            // Bare text, no box. Tone drives color; hover fades muted -> fg.
            // `props` = QtObject { icon, text, tone, onClick, onClickRight }
            component Chip: Item {
                id: c
                required property var props
                property bool hover: false
                readonly property bool blink: props.tone === "warn" || props.tone === "danger"

                implicitHeight: 20
                implicitWidth: chipRow.implicitWidth

                // Default = primary silver; hover fades to white. On/warn/
                // danger override with their palette color.
                readonly property color activeColor:
                    props.tone === "on"     ? root.accent
                  : props.tone === "warn"   ? root.warn
                  : props.tone === "danger" ? root.danger
                  : hover                    ? root.accent
                  :                            root.fg

                Row {
                    id: chipRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    property real blinkAlpha: 1.0
                    opacity: c.blink ? blinkAlpha : 1.0
                    SequentialAnimation on blinkAlpha {
                        running: c.blink
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.30; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
                    }
                    Text {
                        text: c.props.icon || ""
                        color: c.activeColor
                        font { family: root.fontFamily; pixelSize: 14; weight: Font.Bold }
                        visible: text.length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }
                    Text {
                        text: c.props.text || ""
                        color: c.activeColor
                        font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold }
                        visible: text.length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onEntered: c.hover = true
                    onExited:  c.hover = false
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton && c.props.onClickRight)
                            c.props.onClickRight()
                        else if (c.props.onClick)
                            c.props.onClick()
                    }
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
                property var onClick: () => Quickshell.execDetached(["pavucontrol"])
                property var onClickRight: () => {
                    if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
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
                    root.notifOpen = false
                    root.calendarOpen = false
                    root.networkOpen = !root.networkOpen
                }
                property var onClickRight: () => {
                    root.notifOpen = false
                    root.calendarOpen = false
                    root.networkOpen = !root.networkOpen
                }
            }

            QtObject {
                id: dateC
                readonly property string icon: "\u{F00ED}"   // md-calendar-today
                readonly property string text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
                readonly property string tone: "normal"
                property var onClick: () => {
                    root.notifOpen = false
                    root.networkOpen = false
                    root.calendarOpen = !root.calendarOpen
                }
                property var onClickRight: () => {
                    root.notifOpen = false
                    root.networkOpen = false
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
            // ---- collapsible system tray --------------------------------
            component SystemTrayChip: Item {
                id: tray
                property bool expanded: false

                implicitHeight: 20
                implicitWidth: trayRow.implicitWidth
                Behavior on implicitWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onEntered: tray.expanded = true
                    onExited:  tray.expanded = false
                }

                Row {
                    id: trayRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Text {
                        text: tray.expanded ? "\u{203A}" : "\u{2039}"   // › / ‹
                        color: hoverArea.containsMouse ? root.accent : "#8A8A8A"   // brighter than palette muted
                        font { family: root.fontFamily; pixelSize: 15; weight: Font.Bold }
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }

                    Row {
                        spacing: 10
                        visible: tray.expanded
                        opacity: tray.expanded ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        Repeater {
                            model: SystemTray.items
                            delegate: Item {
                                required property SystemTrayItem modelData
                                implicitWidth: 18; implicitHeight: 18
                                anchors.verticalCenter: parent.verticalCenter
                                Image {
                                    anchors.fill: parent
                                    source: modelData.icon
                                    smooth: true
                                    fillMode: Image.PreserveAspectFit
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                                            modelData.display(bar, mouse.x, mouse.y)
                                        } else {
                                            modelData.activate()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- mpris (music player) -----------------------------------
            component MprisChip: Item {
                id: m
                readonly property var player: {
                    const list = Mpris.players ? Mpris.players.values : []
                    for (const p of list) {
                        if (p && (p.canControl === undefined || p.canControl)) return p
                    }
                    return null
                }
                readonly property string _title:   player && player.trackTitle ? player.trackTitle : ""
                readonly property string _artists: {
                    if (!player) return ""
                    const a = player.trackArtists
                    if (Array.isArray(a)) return a.join(", ")
                    return a || ""
                }
                readonly property bool _playing: player && (player.isPlaying === true
                    || (player.playbackState !== undefined && player.playbackState === MprisPlaybackState.Playing))

                visible: player !== null && (_title.length > 0 || _artists.length > 0)
                implicitHeight: 20
                implicitWidth: mprisRow.implicitWidth

                Row {
                    id: mprisRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        text: m._playing ? "\u{F03E4}" : "\u{F040A}"   // md-pause / md-play
                        color: root.accent
                        font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold }
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: m._artists ? (m._artists + "  —  " + m._title) : m._title
                        color: root.accent
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 260)
                        font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: mMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (!m.player) return
                        if (mouse.button === Qt.RightButton) {
                            if (m.player.next) m.player.next()
                        } else if (m.player.togglePlaying) {
                            m.player.togglePlaying()
                        } else if (m._playing && m.player.pause) {
                            m.player.pause()
                        } else if (m.player.play) {
                            m.player.play()
                        }
                    }
                }
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

    // ---- calendar popup --------------------------------------------------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: calendarShade
            required property var modelData
            screen: modelData
            WlrLayershell.namespace: "quickshell-calendar-shade"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: 0
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors { top: true; left: true; right: true; bottom: true }
            margins { top: 34 }
            color: "transparent"
            visible: root.calendarOpen

            MouseArea {
                anchors.fill: parent
                onClicked: root.calendarOpen = false
            }

            Rectangle {
                id: calendarBox
                x: parent.width - width - 12
                y: 8
                width: 300
                height: 286
                color: root.chip
                border { color: "#8A8A8A"; width: 2 }
                radius: 7
                MouseArea { anchors.fill: parent; onClicked: {} }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            Layout.fillWidth: true
                            text: Qt.formatDateTime(clock.date, "MMMM yyyy")
                            color: root.accent
                            font { family: root.fontFamily; pixelSize: 19; weight: Font.Bold }
                        }

                        Text {
                            text: Qt.formatDateTime(clock.date, "HH:mm")
                            color: root.fg
                            font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                        color: root.fg
                        font { family: root.fontFamily; pixelSize: 12; weight: Font.Bold }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: root.line }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 7
                        rowSpacing: 6
                        columnSpacing: 6

                        Repeater {
                            model: ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
                            delegate: Text {
                                required property string modelData
                                Layout.preferredWidth: 32
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                color: root.fg
                                font { family: root.fontFamily; pixelSize: 10; weight: Font.Bold }
                            }
                        }

                        Repeater {
                            model: 42
                            delegate: Rectangle {
                                required property int index
                                readonly property int first: root.firstDayOffset(clock.date)
                                readonly property int day: index - first + 1
                                readonly property bool valid: day > 0 && day <= root.daysInMonth(clock.date)
                                readonly property bool today: valid && day === clock.date.getDate()
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 26
                                color: today ? root.chipOn : "transparent"
                                border { color: today ? root.accent : "transparent"; width: 1 }
                                radius: 5

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.valid ? String(parent.day) : ""
                                    color: parent.today ? root.accent : root.fg
                                    font { family: root.fontFamily; pixelSize: 12; weight: parent.today ? Font.Bold : Font.Normal }
                                }
                            }
                        }
                    }

                }
            }
        }
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
    // Overlay layer + top-margin so it sits below the bar; background
    // MouseArea closes on any outside click. Popup box is anchored to
    // the top-right; child interactions bubble through inner MouseAreas.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: notifShade
            required property var modelData
            screen: modelData
            WlrLayershell.namespace: "quickshell-notif-shade"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: 0
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors { top: true; left: true; right: true; bottom: true }
            margins { top: 34 }   // clear the bar so bar chips remain clickable
            color: "transparent"
            visible: root.notifOpen

            // Background dismiss
            MouseArea {
                anchors.fill: parent
                onClicked: root.notifOpen = false
            }

            // Popup box anchored top-right
            Rectangle {
                id: notifBox
                x: parent.width - width - 12
                y: 6
                width: 380
                height: Math.min(parent.height - 20, 100 + notifCol.implicitHeight)
                color: root.chip
                border { color: root.line; width: 1 }
                MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Text {
                                Layout.fillWidth: true
                                text: "Notifications"
                                color: root.accent
                                font { family: root.fontFamily; pixelSize: 14; weight: Font.Bold }
                            }
                            // DND toggle button — clearly framed so it's easy to spot.
                            Rectangle {
                                id: dndBtn
                                property bool hover: false
                                implicitHeight: 24
                                implicitWidth: dndLbl.implicitWidth + 18
                                color: root.dnd
                                    ? root.accent
                                    : (hover ? root.chipHover : root.chipOn)
                                border { color: root.dnd ? root.accent : root.line; width: 1 }
                                radius: 3
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text {
                                    id: dndLbl
                                    anchors.centerIn: parent
                                    text: root.dnd ? "DND ON" : "DND"
                                    color: root.dnd ? root.bg : root.fg
                                    font { family: root.fontFamily; pixelSize: 11; weight: Font.Bold }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: parent.hover = true
                                    onExited:  parent.hover = false
                                    onClicked: root.dnd = !root.dnd
                                }
                            }
                            Text {
                                text: "clear"
                                color: root.fg
                                font { family: root.fontFamily; pixelSize: 11; weight: Font.Bold }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: parent.color = root.accent
                                    onExited:  parent.color = root.fg
                                    onClicked: {
                                        for (const n of notifServer.trackedNotifications.values.slice())
                                            n.dismiss()
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: root.line }

                        ColumnLayout {
                            id: notifCol
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: notifServer.trackedNotifications
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: Math.max(60, nCol.implicitHeight + 20)
                                    color: root.chip
                                    border { color: root.line; width: 1 }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 10

                                        Item {
                                            Layout.preferredWidth: 32
                                            Layout.preferredHeight: 32
                                            Layout.alignment: Qt.AlignTop
                                            visible: iconImg.status === Image.Ready && iconImg.source != ""
                                            Image {
                                                id: iconImg
                                                anchors.fill: parent
                                                fillMode: Image.PreserveAspectFit
                                                smooth: true
                                                sourceSize.width: 32
                                                sourceSize.height: 32
                                                source: {
                                                    const md = parent.parent.parent.modelData
                                                    if (!md || md.summary === "Screenshot" || md.appName === "Screenshot") return ""
                                                    if (md.image) return md.image
                                                    const a = md.appIcon || ""
                                                    if (!a) return ""
                                                    if (a.charAt(0) === "/" || a.indexOf("file:") === 0) return a
                                                    return Quickshell.iconPath(a, true)
                                                }
                                            }
                                        }

                                    ColumnLayout {
                                        id: nCol
                                        Layout.fillWidth: true
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.summary || modelData.appName || ""
                                                color: root.accent
                                                font { family: root.fontFamily; pixelSize: 13; weight: Font.Bold }
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                text: "×"
                                                color: root.fg
                                                font { family: root.fontFamily; pixelSize: 14; weight: Font.Bold }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onEntered: parent.color = root.accent
                                                    onExited:  parent.color = root.fg
                                                    onClicked: modelData.dismiss()
                                                }
                                            }
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.body || ""
                                            color: root.fg
                                            font { family: root.fontFamily; pixelSize: 11; weight: Font.Bold }
                                            wrapMode: Text.WordWrap
                                            textFormat: Text.RichText
                                            visible: text.length > 0
                                        }
                                        // Action buttons — freedesktop notification actions.
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6
                                            visible: modelData.actions && modelData.actions.length > 0
                                            Repeater {
                                                model: modelData.actions
                                                delegate: Rectangle {
                                                    required property var modelData
                                                    property bool hover: false
                                                    implicitHeight: 22
                                                    implicitWidth: aLabel.implicitWidth + 14
                                                    color: hover ? root.chipHover : root.chipOn
                                                    border { color: root.line; width: 1 }
                                                    Text {
                                                        id: aLabel
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
                                                        onClicked: modelData.invoke()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "no notifications"
                                color: root.muted
                                font { family: root.fontFamily; pixelSize: 11; weight: Font.Bold }
                                visible: notifServer.trackedNotifications.values.length === 0
                                Layout.margins: 12
                            }
                        }
                    }
                }
        }
    }
}
