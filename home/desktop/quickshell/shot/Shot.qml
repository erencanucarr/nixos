import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "Calc.mjs" as Calc
import qs.common

Scope {
    id: root

    readonly property var modes: ["alan", "pencere", "ekran"]
    readonly property var delays: [0, 3, 10]
    property var features: ({
            ocr: false,
            qr: false
        })
    readonly property var kinds: ["foto", "video", "gif", "yazı", "qr"].filter(k => k === "yazı" ? root.features.ocr : k === "qr" ? root.features.qr : true)
    readonly property string kindName: root.kinds[root.kind] ?? "foto"
    readonly property bool recKind: root.kindName === "video" || root.kindName === "gif"
    readonly property bool scanning: root.kindName === "yazı" || root.kindName === "qr"
    readonly property string run: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    property int mode: 0
    property int delay: 0
    property int kind: 0
    property bool audio: true
    property string frozen: ""
    property var scr: null
    readonly property var wins: aim.visible ? root.windows(root.scr) : []
    property rect drag: Qt.rect(0, 0, 0, 0)
    property real mx: 0
    property real my: 0
    readonly property var hover: wins.find(w => mx >= w.x && mx < w.x + w.width && my >= w.y && my < w.y + w.height) ?? null
    readonly property rect sel: mode === 2 ? Qt.rect(0, 0, aim.width, aim.height) : mode === 1 ? (hover ?? Qt.rect(0, 0, 0, 0)) : drag
    readonly property real k: frozenImg.sourceSize.width / Math.max(1, aim.width)

    property string shot: ""
    property string shotWhat: ""
    property string shotDims: ""
    property rect shotRect
    property string shotFile: ""
    property string shotKind: "foto"
    property string shotText: ""
    property bool shotEmpty: false

    function focusedScreen(): var {
        return Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
    }

    function windows(screen: var): var {
        const ws = Hyprland.monitorFor(screen)?.activeWorkspace;
        return [...Hyprland.toplevels.values]
            .map(t => t.lastIpcObject)
            .filter(o => o?.size && o.workspace?.id === ws?.id)
            .sort((a, b) => (b.fullscreen ? 2 : b.floating ? 1 : 0) - (a.fullscreen ? 2 : a.floating ? 1 : 0) || a.focusHistoryID - b.focusHistoryID)
            .map(o => Qt.rect(o.at[0] - screen.x, o.at[1] - screen.y, o.size[0], o.size[1]));
    }

    function open(name: string): void {
        if (Recorder.busy)
            return Recorder.stop();
        if (aim.visible || freeze.running)
            return;
        const i = root.kinds.indexOf(name);
        if (i < 0)
            return Quickshell.execDetached(["ecu-shot", "notify", "Ekran görüntüsü", name === "qr" ? "QR okuma kapalı" : "Yazı okuma kapalı"]);
        root.kind = i;
        root.scr = root.focusedScreen();
        Hyprland.refreshToplevels();
        freeze.next = `${root.run}/ecu-shot-${Date.now()}.ppm`;
        freeze.exec(["ecu-shot", "freeze", root.scr.name, freeze.next]);
    }

    function screenNow(): void {
        if (aim.visible || Recorder.busy)
            return;
        root.scr = root.focusedScreen();
        const d = root.scr.devicePixelRatio ?? 1;
        root.shotRect = Qt.rect(0, 0, root.scr.width, root.scr.height);
        root.shotWhat = `ekran · ${Qt.formatTime(new Date(), "HH:mm")}`;
        root.shotDims = `${Math.round(root.scr.width * d)} × ${Math.round(root.scr.height * d)}`;
        root.shotKind = "foto";
        root.shotEmpty = false;
        capture.createObject(root, {
            command: ["ecu-shot", "screen", root.scr.name]
        });
    }

    function close(): void {
        aim.visible = false;
        picker.unloadImage(frozenImg.source);
        root.frozen = "";
    }

    function cancel(): void {
        editor.close();
        if (!aim.visible)
            return;
        Quickshell.execDetached(["rm", "-f", root.frozen]);
        root.close();
    }

    function fire(): void {
        if (root.mode === 1 && !root.hover)
            return;
        const r = root.sel.width > 2 && root.sel.height > 2 ? root.sel : Qt.rect(0, 0, aim.width, aim.height);
        const c = Calc.crop(r, aim.width, aim.height, frozenImg.sourceSize.width, frozenImg.sourceSize.height);
        if (!c)
            return;
        if (root.recKind)
            return root.record(r, c);
        root.shotRect = r;
        root.shotWhat = `${root.modes[root.mode]} · ${Qt.formatTime(new Date(), "HH:mm")}`;
        root.shotEmpty = false;
        root.shotText = "";
        const frame = root.frozen;
        const box = [String(c.x), String(c.y), String(c.w), String(c.h)];
        if (root.scanning) {
            root.shotKind = root.kindName;
            scan.exec(["ecu-shot", root.kindName === "yazı" ? "ocr" : "qr", frame, ...box]);
            root.close();
            return;
        }
        root.shotKind = "foto";
        root.shotDims = `${c.w} × ${c.h}`;
        const g = `${Math.round(root.scr.x + c.x / root.k)},${Math.round(root.scr.y + c.y / root.k)} ${Math.round(c.w / root.k)}x${Math.round(c.h / root.k)}`;
        capture.createObject(root, {
            command: ["ecu-shot", "photo", String(root.delays[root.delay]), frame, ...box, g]
        });
        root.close();
    }

    function record(r: rect, c: var): void {
        const x = Math.round(root.scr.x + c.x / root.k), y = Math.round(root.scr.y + c.y / root.k);
        const w = Math.round(c.w / root.k) & ~1, h = Math.round(c.h / root.k) & ~1;
        const target = root.mode === 2 ? ["-o", root.scr.name] : ["-g", `${x},${y} ${w}x${h}`];
        Quickshell.execDetached(["rm", "-f", root.frozen]);
        root.close();
        Recorder.start(root.kindName, target, root.delays[root.delay], root.audio, r);
    }

    FileView {
        path: "/etc/ecu/shot.json"
        printErrors: false
        onLoaded: {
            try {
                root.features = JSON.parse(text());
            } catch (e) {
                root.features = {
                    ocr: false,
                    qr: false
                };
            }
        }
    }

    Connections {
        target: Recorder

        function onSaved(file: string, thumb: string, kind: string, seconds: int, area: rect): void {
            root.shot = thumb;
            root.shotFile = file;
            root.shotKind = kind;
            root.shotRect = area;
            root.shotDims = Recorder.clock(seconds);
            root.shotWhat = `${kind} · ${Qt.formatTime(new Date(), "HH:mm")}`;
            fx.restart();
        }
    }

    IpcHandler {
        target: "shot"

        function open(): void {
            root.open("foto");
        }

        function record(): void {
            root.open("video");
        }

        function gif(): void {
            root.open("gif");
        }

        function text(): void {
            root.open("yazı");
        }

        function qr(): void {
            root.open("qr");
        }

        function stop(): void {
            Recorder.stop();
        }

        function screen(): void {
            root.screenNow();
        }

        function cancel(): void {
            root.cancel();
        }

        function mode(m: int): void {
            root.mode = Math.max(0, Math.min(2, m));
        }

        function capture(): void {
            if (aim.visible)
                root.fire();
        }

        function edit(): void {
            if (!root.shot || aim.visible || root.shotKind !== "foto")
                return;
            fx.stop();
            fired.visible = false;
            editor.open(root.shot, root.scr);
        }
    }

    Process {
        id: freeze

        property string next

        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim())
                    return;
                root.frozen = freeze.next;
                root.mode = 0;
                root.drag = Qt.rect(0, 0, 0, 0);
                aim.visible = true;
                stage.forceActiveFocus();
            }
        }
    }

    Component {
        id: capture

        Process {
            id: proc

            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    if (text) {
                        root.shot = text;
                        fx.restart();
                    }
                    proc.destroy();
                }
            }
        }
    }

    Process {
        id: scan

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const status = lines[0] ?? "";
                if (status !== "ok" && status !== "empty") {
                    Quickshell.execDetached(["ecu-shot", "notify", "Ekran görüntüsü", root.shotKind === "qr" ? "QR kod okunamadı" : "Yazı okunamadı"]);
                    return;
                }
                const body = lines.slice(2).join("\n");
                root.shot = lines[1] ?? "";
                root.shotEmpty = status === "empty";
                root.shotText = body;
                if (root.shotEmpty)
                    root.shotDims = root.shotKind === "qr" ? "QR kod yok" : "Yazı yok";
                else
                    root.shotDims = root.shotKind === "qr" ? "QR kod" : `${body.split("\n").length} satır · ${body.length} karakter`;
                fx.restart();
            }
        }
    }

    LazyLoader {
        id: editor

        function open(path: string, screen: var): void {
            editor.active = true;
            editor.item.open(path, screen);
        }

        function close(): void {
            editor.item?.close();
        }

        ShotEditor {
            onClosed: Qt.callLater(() => editor.active = false)
        }
    }

    PanelWindow {
        id: aim

        screen: root.scr
        visible: false
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-shot"

        Item {
            id: stage

            anchors.fill: parent
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape)
                    root.cancel();
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                    root.fire();
                else if (e.key === Qt.Key_Space)
                    root.mode = 1;
                else if (e.key === Qt.Key_Tab)
                    root.mode = (root.mode + 1) % 3;
                else if (e.key === Qt.Key_Backtab)
                    root.mode = (root.mode + 2) % 3;
                else if (e.key === Qt.Key_T && !root.scanning)
                    root.delay = (root.delay + 1) % 3;
                else if (e.key === Qt.Key_R)
                    root.kind = (root.kind + 1) % root.kinds.length;
                else if (e.key === Qt.Key_A && root.kindName === "video")
                    root.audio = !root.audio;
                else
                    return;
                e.accepted = true;
            }

            Image {
                id: frozenImg

                anchors.fill: parent
                source: root.frozen ? "file://" + root.frozen : ""
            }

            Item {
                anchors.fill: parent

                readonly property color c: root.sel.width ? "#B8000000" : "#59000000"
                readonly property rect r: root.sel.width ? root.sel : Qt.rect(0, 0, 0, 0)

                Rectangle {
                    width: parent.width
                    height: parent.r.y
                    color: parent.c
                }
                Rectangle {
                    y: parent.r.y + parent.r.height
                    width: parent.width
                    height: parent.height - y
                    color: parent.c
                }
                Rectangle {
                    y: parent.r.y
                    width: parent.r.x
                    height: parent.r.height
                    color: parent.c
                }
                Rectangle {
                    x: parent.r.x + parent.r.width
                    y: parent.r.y
                    width: parent.width - x
                    height: parent.r.height
                    color: parent.c
                }
            }

            Rectangle {
                y: Math.round(root.my)
                width: parent.width
                height: 1
                color: "#40FFFFFF"
            }
            Rectangle {
                x: Math.round(root.mx)
                width: 1
                height: parent.height
                color: "#40FFFFFF"
            }

            Item {
                id: vf

                visible: root.sel.width > 0
                x: root.sel.x
                y: root.sel.y
                width: root.sel.width
                height: root.sel.height

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: "#FFFFFF"
                }

                Repeater {
                    model: 4

                    Rectangle {
                        required property int index

                        x: (index % 2 ? vf.width : 0) - 3
                        y: (index > 1 ? vf.height : 0) - 3
                        width: 7
                        height: 7
                        color: "#FFFFFF"
                    }
                }

                Surface {
                    y: vf.y > 40 ? -height - 8 : 8
                    width: dims.implicitWidth + Theme.pad * 2
                    height: dims.implicitHeight + 8
                    radius: Theme.radius

                    BarText {
                        id: dims

                        anchors.centerIn: parent
                        text: `${root.kind ? root.kindName + " · " : ""}${root.modes[root.mode]}  ${Math.round(root.sel.width * root.k)} × ${Math.round(root.sel.height * root.k)}`
                        color: Theme.bright
                    }
                }
            }

            Item {
                id: loupe

                readonly property int px: Math.max(0, Math.min(frozenImg.sourceSize.width - 1, Math.floor(root.mx * root.k)))
                readonly property int py: Math.max(0, Math.min(frozenImg.sourceSize.height - 1, Math.floor(root.my * root.k)))
                readonly property int zoom: 12
                readonly property int cells: 13

                x: root.mx + 24 + width > stage.width ? root.mx - 24 - width : root.mx + 24
                y: root.my + 24 + height > stage.height ? root.my - 24 - height : root.my + 24
                width: cells * zoom + 2
                height: width + readout.height + 6

                Canvas {
                    id: picker

                    property string hex: "#000000"

                    width: 1
                    height: 1
                    onImageLoaded: requestPaint()
                    onPaint: {
                        const g = getContext("2d"), src = frozenImg.source.toString();
                        if (!src)
                            return;
                        if (!isImageLoaded(src))
                            return loadImage(src);
                        g.drawImage(src, loupe.px, loupe.py, 1, 1, 0, 0, 1, 1);
                        const d = g.getImageData(0, 0, 1, 1).data;
                        hex = "#" + [d[0], d[1], d[2]].map(v => v.toString(16).padStart(2, "0")).join("").toUpperCase();
                    }

                    Connections {
                        target: loupe

                        function onPxChanged(): void {
                            picker.requestPaint();
                        }

                        function onPyChanged(): void {
                            picker.requestPaint();
                        }
                    }
                }

                ClippingRectangle {
                    width: loupe.width
                    height: loupe.width
                    radius: Theme.radiusLg
                    color: "#000000"
                    border.width: 1
                    border.color: "#59FFFFFF"

                    Image {
                        source: frozenImg.source
                        smooth: false
                        width: frozenImg.sourceSize.width * loupe.zoom
                        height: frozenImg.sourceSize.height * loupe.zoom
                        x: 1 + (Math.floor(loupe.cells / 2) - loupe.px) * loupe.zoom
                        y: 1 + (Math.floor(loupe.cells / 2) - loupe.py) * loupe.zoom
                    }

                    Rectangle {
                        x: 1 + Math.floor(loupe.cells / 2) * loupe.zoom - 1
                        y: x
                        width: loupe.zoom + 2
                        height: width
                        color: "transparent"
                        border.width: 1
                        border.color: "#FFFFFF"
                    }
                }

                Surface {
                    id: readout

                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: row.implicitHeight + 10
                    radius: Theme.radius

                    RowLayout {
                        id: row

                        anchors.centerIn: parent
                        spacing: 8

                        BarText {
                            text: `${loupe.px}, ${loupe.py}`
                            color: Theme.bright
                        }

                        Rectangle {
                            implicitWidth: 10
                            implicitHeight: 10
                            radius: 2
                            color: picker.hex
                            border.width: 1
                            border.color: Theme.edge
                        }

                        BarText {
                            text: picker.hex
                            color: Theme.dim
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.CrossCursor

                property point from

                function clampX(x: real): real {
                    return Math.max(0, Math.min(width, x));
                }
                function clampY(y: real): real {
                    return Math.max(0, Math.min(height, y));
                }

                onPositionChanged: e => {
                    root.mx = clampX(e.x);
                    root.my = clampY(e.y);
                    if (pressed && root.mode === 0)
                        root.drag = Qt.rect(Math.min(from.x, root.mx), Math.min(from.y, root.my), Math.abs(root.mx - from.x), Math.abs(root.my - from.y));
                }
                onPressed: e => {
                    root.mx = clampX(e.x);
                    root.my = clampY(e.y);
                    if (root.mode !== 0)
                        return root.fire();
                    from = Qt.point(root.mx, root.my);
                    root.drag = Qt.rect(from.x, from.y, 0, 0);
                }
                onReleased: if (root.mode === 0 && root.drag.width > 2 && root.drag.height > 2)
                    root.fire()
            }

            ColumnLayout {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 40
                }
                spacing: 8

                Surface {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: chips.implicitWidth + 12
                    implicitHeight: chips.implicitHeight + 12

                    MouseArea {
                        anchors.fill: parent
                    }

                    RowLayout {
                        id: chips

                        anchors.centerIn: parent
                        spacing: 4

                        Repeater {
                            model: root.kinds

                            Chip {
                                required property string modelData
                                required property int index

                                text: modelData
                                on: index === root.kind
                                onClicked: root.kind = index
                            }
                        }

                        Rule {
                            vertical: true
                        }

                        Repeater {
                            model: root.modes

                            Chip {
                                required property string modelData
                                required property int index

                                text: modelData
                                on: index === root.mode
                                onClicked: root.mode = index
                            }
                        }

                        Rule {
                            vertical: true
                        }

                        Chip {
                            visible: !root.scanning
                            text: root.delay ? `${root.delays[root.delay]} sn` : "gecikme"
                            on: root.delay > 0
                            onClicked: root.delay = (root.delay + 1) % 3
                        }

                        Chip {
                            visible: root.kindName === "video"
                            text: root.audio ? "ses açık" : "ses kapalı"
                            on: root.audio
                            onClicked: root.audio = !root.audio
                        }
                    }
                }

                Surface {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: keys.implicitWidth + Theme.pad * 2
                    implicitHeight: keys.implicitHeight + 10
                    radius: Theme.radius

                    BarText {
                        id: keys

                        anchors.centerIn: parent
                        text: root.scanning ? `sürükle  alan     boşluk  pencere     tab  kip     r  tür     ↵  ${root.kindName === "qr" ? "QR oku" : "yazıyı oku"}     esc  iptal` : root.recKind ? `sürükle  alan     boşluk  pencere     r  tür     t  gecikme${root.kindName === "video" ? "     a  ses" : ""}     ↵  kaydı başlat     esc  iptal` : "sürükle  alan     boşluk  pencere     tab  kip     r  tür     t  gecikme     ↵  çek     esc  iptal"
                        color: Theme.dim
                        font.pixelSize: Theme.size - 1
                    }
                }
            }
        }
    }

    PanelWindow {
        id: fired

        screen: root.scr
        visible: false
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        mask: Region {
            item: card
        }
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-shot"

        Rectangle {
            id: flash

            x: root.shotRect.x
            y: root.shotRect.y
            width: root.shotRect.width
            height: root.shotRect.height
            color: "#1FFFFFFF"
            border.width: 1
            border.color: "#FFFFFF"
        }

        Surface {
            id: card

            property real t: 0

            x: parent.width - 24 - width + 48 * (1 - t)
            y: parent.height - 24 - height
            opacity: t
            width: 320
            height: cardBody.implicitHeight + 24

            ColumnLayout {
                id: cardBody

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 10

                ClippingRectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 168
                    radius: Theme.radius
                    color: Theme.ground

                    Image {
                        anchors.fill: parent
                        source: root.shot ? "file://" + root.shot : ""
                        sourceSize: Qt.size(592, 336)
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    BarText {
                        Layout.fillWidth: true
                        text: root.shotDims
                        color: Theme.bright
                        font.weight: Font.DemiBold
                    }

                    BarText {
                        text: root.shotWhat
                        color: Theme.dim
                    }
                }

                BarText {
                    Layout.fillWidth: true
                    visible: root.shotKind === "yazı" && !root.shotEmpty && root.shotText !== ""
                    text: root.shotText
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Theme.size - 1
                    color: Theme.text
                }

                BarText {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: {
                        if (root.shotKind === "yazı")
                            return root.shotEmpty ? "Bu alanda okunabilir bir yazı bulunamadı" : "Yazı panoya kopyalandı";
                        if (root.shotKind === "qr")
                            return root.shotEmpty ? "Bu alanda okunabilir bir QR kod bulunamadı" : "QR kod panoya kopyalandı · içerik güvenlik için gösterilmiyor";
                        if (root.shotKind === "gif")
                            return "GIF kaydedildi ve kopyalandı · açmak için tıkla";
                        if (root.shotKind === "video")
                            return "Video kaydedildi, dosya kopyalandı · açmak için tıkla";
                        return "Kaydedildi ve kopyalandı · düzenlemek için tıkla";
                    }
                    color: root.shotEmpty ? Theme.hot : Theme.dim
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    fx.stop();
                    fired.visible = false;
                    if (root.shotKind === "foto")
                        editor.open(root.shot, root.scr);
                    else if (root.shotKind === "video" || root.shotKind === "gif")
                        Qt.openUrlExternally("file://" + root.shotFile);
                }
            }
        }

        SequentialAnimation {
            id: fx

            PropertyAction {
                target: fired
                property: "visible"
                value: true
            }
            ParallelAnimation {
                NumberAnimation {
                    target: flash
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 700
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: card
                    property: "t"
                    from: 0
                    to: 1
                    duration: Theme.anim
                    easing.type: Theme.ease
                }
            }
            PauseAnimation {
                duration: 2200
            }
            NumberAnimation {
                target: card
                property: "t"
                to: 0
                duration: Theme.anim
                easing.type: Easing.InCubic
            }
            PropertyAction {
                target: fired
                property: "visible"
                value: false
            }
        }
    }
}
