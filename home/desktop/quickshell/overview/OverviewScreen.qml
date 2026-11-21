import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common

// The overview on one screen (see Overview.qml): a blurred, darkened
// backdrop (Hyprland's layer rule for can-overview blurs it), the screen's
// workspaces along the top and the shown workspace's windows below, laid
// out to fill the space as large as they fit.
PanelWindow {
    id: root

    required property var modelData

    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === root.modelData.name) ?? null
    // Five workspaces per screen (hyprland.lua: 1-5 left, 6-10 right): the
    // block holding the screen's active one.
    readonly property int base: Math.floor(((monitor?.activeWorkspace?.id ?? 1) - 1) / 5) * 5 + 1
    readonly property var workspaceIds: [0, 1, 2, 3, 4].map(i => root.base + i)

    // The workspace whose windows are spread out below; set on open.
    property int shownId: 1
    // Only the focused screen takes the keyboard, decided on open.
    property bool keyboard: false
    property int selected: -1
    // The workspace a dragged window is over, or -1.
    property int dropId: -1

    readonly property var windows: Hyprland.toplevels.values.filter(t => t.workspace?.id === root.shownId && t.lastIpcObject?.size).sort((a, b) => (a.lastIpcObject.at[1] - b.lastIpcObject.at[1]) || (a.lastIpcObject.at[0] - b.lastIpcObject.at[0]))
    readonly property var rects: arrange(windows, stage.width, stage.height)

    // The largest uniform layout: try every column count, scale each window
    // into its cell (never above 85% of its real size), keep the one that
    // covers the most area, then centre each row and the whole block.
    function arrange(wins: var, W: real, H: real): var {
        const n = wins.length;
        if (n === 0 || W <= 0 || H <= 0)
            return [];
        const gap = 32;
        const title = 28;
        let best = null;
        for (let cols = 1; cols <= n; cols++) {
            const rows = Math.ceil(n / cols);
            const cw = (W - gap * (cols - 1)) / cols;
            const ch = (H - gap * (rows - 1)) / rows - title;
            if (cw <= 0 || ch <= 0)
                continue;
            let area = 0;
            const sizes = wins.map(w => {
                const [ww, wh] = w.lastIpcObject.size;
                const s = Math.min(cw / ww, ch / wh, 0.85);
                area += ww * s * wh * s;
                return [ww * s, wh * s];
            });
            if (!best || area > best.area)
                best = {
                    cols,
                    rows,
                    sizes,
                    area
                };
        }
        if (!best)
            return [];
        const out = [];
        const rowHeights = [];
        for (let r = 0; r < best.rows; r++)
            rowHeights.push(Math.max(...best.sizes.slice(r * best.cols, (r + 1) * best.cols).map(s => s[1])));
        const total = rowHeights.reduce((a, h) => a + h + title, 0) + gap * (best.rows - 1);
        let y = (H - total) / 2;
        for (let r = 0; r < best.rows; r++) {
            const row = best.sizes.slice(r * best.cols, (r + 1) * best.cols);
            const rowWidth = row.reduce((a, s) => a + s[0], 0) + gap * (row.length - 1);
            let x = (W - rowWidth) / 2;
            for (const [w, h] of row) {
                out.push({
                    x,
                    y: y + (rowHeights[r] - h) / 2,
                    w,
                    h: h + title
                });
                x += w + gap;
            }
            y += rowHeights[r] + title + gap;
        }
        return out;
    }

    function dispatch(cmd: string): void {
        Hyprland.dispatch(cmd);
        refresh.restart();
    }

    function show(id: int): void {
        root.shownId = id;
        root.selected = -1;
        root.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    function activate(t: var): void {
        Panels.overviewOpen = false;
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${t.address}" })`);
    }

    function closeWindow(t: var): void {
        root.dispatch(`hl.dsp.window.close({ window = "address:0x${t.address}" })`);
    }

    function cardAt(p: point): int {
        for (let i = 0; i < cards.count; i++) {
            const c = cards.itemAt(i);
            const q = c.mapFromItem(null, p.x, p.y);
            if (q.x >= 0 && q.y >= 0 && q.x <= c.width && q.y <= c.height)
                return c.workspaceId;
        }
        return -1;
    }

    function moveWindow(t: var, id: int): void {
        if (id < 0 || id === t.workspace?.id)
            return;
        root.dispatch(`hl.dsp.window.move({ workspace = ${id}, window = "address:0x${t.address}", follow = false })`);
    }

    screen: modelData
    visible: Panels.overviewOpen

    WlrLayershell.namespace: "can-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.keyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "#a60a0a0c"

    // Built on open and freed on close (shell.qml's LazyLoader), so this
    // runs once per open.
    property bool shown: false

    Component.onCompleted: {
        Hyprland.refreshToplevels();
        root.shownId = root.monitor?.activeWorkspace?.id ?? root.base;
        root.keyboard = root.monitor?.focused ?? false;
        root.selected = -1;
        if (root.keyboard)
            keys.forceActiveFocus();
        root.shown = true;
    }

    // Positions arrive with the next IPC reply, a moment after a change.
    Timer {
        id: refresh
        interval: 120
        onTriggered: Hyprland.refreshToplevels()
    }

    // The backdrop: a click on it closes the overview.
    MouseArea {
        anchors.fill: parent
        onClicked: Panels.overviewOpen = false
    }

    Item {
        id: keys

        focus: true
        Keys.onPressed: e => {
            const n = root.windows.length;
            if (e.key === Qt.Key_Escape) {
                Panels.overviewOpen = false;
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                if (n > 0)
                    root.activate(root.windows[Math.max(0, root.selected)]);
            } else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down || e.key === Qt.Key_Tab) {
                if (n > 0)
                    root.selected = (root.selected + 1) % n;
            } else if (e.key === Qt.Key_Left || e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) {
                if (n > 0)
                    root.selected = (root.selected - 1 + n) % n;
            } else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_5) {
                root.show(root.base + e.key - Qt.Key_1);
            } else
                return;
            e.accepted = true;
        }
    }

    // Fades and settles in on open.
    Item {
        id: content

        anchors.fill: parent
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.97

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: strip

            anchors {
                top: parent.top
                topMargin: 36
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 16

            Repeater {
                id: cards

                model: root.workspaceIds

                delegate: WorkspaceCard {
                    required property int modelData

                    workspaceId: modelData
                    monitor: root.monitor
                    width: Math.min(200, (root.width - 200) / 5)
                    height: width * (root.monitor?.height ?? 1080) / Math.max(1, root.monitor?.width ?? 1920)
                    shown: root.shownId === modelData
                    current: root.monitor?.activeWorkspace?.id === modelData
                    dropTarget: root.dropId === modelData
                    onClicked: root.show(modelData)
                }
            }
        }

        // The shown workspace's windows.
        Item {
            id: stage

            anchors {
                top: strip.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: 48
                bottomMargin: 56
                leftMargin: 72
                rightMargin: 72
            }

            Repeater {
                model: root.windows

                delegate: WindowTile {
                    required property var modelData
                    required property int index

                    readonly property var rect: root.rects[index] ?? {
                        x: 0,
                        y: 0,
                        w: 0,
                        h: 0
                    }

                    toplevel: modelData
                    x: rect.x
                    y: rect.y
                    width: rect.w
                    height: rect.h
                    selected: root.selected === index

                    onActivated: root.activate(modelData)
                    onCloseRequested: root.closeWindow(modelData)
                    onDragMoved: at => root.dropId = root.cardAt(at)
                    onDropped: at => {
                        root.dropId = -1;
                        root.moveWindow(modelData, root.cardAt(at));
                    }
                }
            }

            BarText {
                visible: root.windows.length === 0
                anchors.centerIn: parent
                text: "Bu çalışma alanında pencere yok"
                font.pixelSize: Theme.size + 2
                color: Theme.dim
            }
        }
    }
}
