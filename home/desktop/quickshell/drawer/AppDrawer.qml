import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

PanelWindow {
    id: root

    readonly property int fs: 14
    readonly property int wt: 550

    property string query: ""
    property string category: "all"
    property var menuApp: null
    property point menuAt

    readonly property var kinds: [
        ["web", "İnternet", 0xF059F, ["Network", "WebBrowser", "Email", "Chat"]],
        ["dev", "Geliştirme", 0xF0169, ["Development", "IDE", "TerminalEmulator"]],
        ["office", "Ofis", 0xF0219, ["Office", "TextEditor", "WordProcessor"]],
        ["media", "Ses ve video", 0xF075A, ["AudioVideo", "Audio", "Video", "Player"]],
        ["graphics", "Grafik", 0xF03D8, ["Graphics", "Photography", "Viewer"]],
        ["game", "Oyunlar", 0xF0297, ["Game"]],
        ["system", "Sistem", 0xF0493, ["System", "Settings", "Monitor", "HardwareSettings", "PackageManager"]],
        ["tools", "Araçlar", 0xF1064, ["Utility", "Accessories", "FileManager", "Archiving", "Calculator", "Education", "Science"]]
    ]

    readonly property var all: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name, "tr"))

    function kindOf(app: var): string {
        const cats = app.categories ?? [];
        return root.kinds.find(k => k[3].some(c => cats.includes(c)))?.[0] ?? "other";
    }

    readonly property var shelf: {
        const counts = {};
        for (const a of root.all)
            counts[root.kindOf(a)] = (counts[root.kindOf(a)] ?? 0) + 1;
        const out = [["all", "Tümü", 0xF003B, root.all.length]];
        for (const k of root.kinds)
            if (counts[k[0]])
                out.push([k[0], k[1], k[2], counts[k[0]]]);
        if (counts.other)
            out.push(["other", "Diğer", 0xF01D8, counts.other]);
        return out;
    }

    function fold(s: string): string {
        return (s ?? "").toLocaleLowerCase("tr").replace(/ı/g, "i").replace(/ş/g, "s").replace(/ğ/g, "g").replace(/ü/g, "u").replace(/ö/g, "o").replace(/ç/g, "c").replace(/[̀-ͯ]/g, "");
    }

    function rank(app: var, q: string): real {
        const name = root.fold(app.name);
        if (name.startsWith(q))
            return 100;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 80;
        if (name.includes(q))
            return 60;
        const rest = root.fold([app.genericName, app.comment, ...(app.keywords ?? [])].join(" "));
        if (rest.split(/[\s,;]+/).some(w => w.startsWith(q)))
            return 40;
        if (rest.includes(q))
            return 25;
        let i = 0;
        for (const c of name)
            if (c === q[i])
                i++;
        return i === q.length ? 10 : 0;
    }

    readonly property var apps: {
        const q = root.fold(root.query.trim());
        if (q === "")
            return root.category === "all" ? root.all : root.all.filter(a => root.kindOf(a) === root.category);
        return root.all.map(a => [a, q.split(/\s+/).reduce((s, w) => Math.min(s, root.rank(a, w)), 100)]).filter(x => x[1] > 0).sort((x, y) => y[1] - x[1] || DrawerState.score(y[0].id) - DrawerState.score(x[0].id)).map(x => x[0]);
    }

    readonly property var favourites: {
        const byId = id => root.all.find(a => a.id === id);
        const pinned = DrawerState.pinned.map(byId).filter(a => !!a);
        const used = root.all.filter(a => !DrawerState.isPinned(a.id) && DrawerState.score(a.id) > 0).sort((a, b) => DrawerState.score(b.id) - DrawerState.score(a.id));
        return pinned.concat(used).slice(0, 6);
    }

    readonly property bool showFavourites: root.query === "" && root.category === "all" && root.favourites.length > 0

    function windowOf(app: var): var {
        const keys = [app.id, app.startupClass, app.name].filter(k => !!k).map(k => k.toLowerCase().replace(/\.desktop$/, ""));
        return Hyprland.toplevels.values.find(t => keys.includes((t.lastIpcObject?.class ?? "").toLowerCase())) ?? null;
    }

    function iconOf(app: var): string {
        return Quickshell.iconPath(app?.icon ?? "", true) || Quickshell.iconPath("application-x-executable", true) || "";
    }

    function launch(app: var, fresh: bool): void {
        if (!app)
            return;
        const win = fresh ? null : root.windowOf(app);
        if (win)
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${win.address}" })`);
        else {
            app.execute();
            DrawerState.launched(app.id);
        }
        Panels.drawerOpen = false;
    }

    function openMenu(app: var, at: point): void {
        root.menuApp = app;
        root.menuAt = at;
    }

    function stepCategory(by: int): void {
        const i = root.shelf.findIndex(s => s[0] === root.category);
        root.category = root.shelf[(i + by + root.shelf.length) % root.shelf.length][0];
        grid.currentIndex = 0;
    }

    screen: Quickshell.screens.find(s => s.name === Panels.drawerScreen) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "can-drawer"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Theme.alpha(Theme.ground, 0.6)

    property bool shown: false

    Component.onCompleted: {
        Hyprland.refreshToplevels();
        search.forceActiveFocus();
        root.shown = true;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Panels.drawerOpen = false
    }

    Surface {
        id: panel

        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.shown ? 0 : 10
        width: Math.min(parent.width - 160, 900)
        height: Math.min(parent.height - 140, 640)
        opacity: root.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: root.menuApp = null
        }

        Rectangle {
            id: searchBox

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
            }
            height: 42
            radius: 8
            color: Theme.ground
            border.width: 1
            border.color: search.activeFocus ? Theme.rule : Theme.line

            BarText {
                id: searchIcon
                anchors {
                    left: parent.left
                    leftMargin: 13
                    verticalCenter: parent.verticalCenter
                }
                text: Glyph.search
                font.pixelSize: 17
                color: Theme.dim
            }

            TextInput {
                id: search

                anchors {
                    left: searchIcon.right
                    leftMargin: 10
                    right: count.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                color: Theme.text
                selectionColor: Theme.text
                selectedTextColor: Theme.ground
                font.family: "Inter Variable"
                font.variableAxes: ({
                        wght: root.wt
                    })
                font.pixelSize: root.fs + 1
                clip: true

                onTextChanged: {
                    root.query = text;
                    root.menuApp = null;
                    grid.currentIndex = 0;
                }

                Keys.onPressed: e => {
                    if (e.modifiers & Qt.AltModifier && e.key >= Qt.Key_1 && e.key <= Qt.Key_6) {
                        root.launch(root.favourites[e.key - Qt.Key_1], false);
                    } else if (e.key === Qt.Key_Escape) {
                        if (root.menuApp)
                            root.menuApp = null;
                        else if (search.text)
                            search.text = "";
                        else
                            Panels.drawerOpen = false;
                    } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        root.launch(root.apps[grid.currentIndex], (e.modifiers & Qt.ControlModifier) !== 0);
                    } else if (e.key === Qt.Key_Tab) {
                        root.stepCategory(1);
                    } else if (e.key === Qt.Key_Backtab) {
                        root.stepCategory(-1);
                    } else if (e.key === Qt.Key_Left) {
                        grid.moveCurrentIndexLeft();
                    } else if (e.key === Qt.Key_Right) {
                        grid.moveCurrentIndexRight();
                    } else if (e.key === Qt.Key_Up) {
                        grid.moveCurrentIndexUp();
                    } else if (e.key === Qt.Key_Down) {
                        grid.moveCurrentIndexDown();
                    } else
                        return;
                    e.accepted = true;
                }

                BarText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: "Uygulama ara — ya da soldan bir kategori seç"
                    font.pixelSize: root.fs + 1
                    weight: root.wt
                    color: Theme.dim
                }
            }

            BarText {
                id: count
                anchors {
                    right: parent.right
                    rightMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                text: `${root.apps.length} uygulama`
                font.pixelSize: root.fs - 2
                weight: root.wt
                color: Theme.dim
            }
        }

        ColumnLayout {
            id: side

            anchors {
                top: searchBox.bottom
                topMargin: 14
                left: parent.left
                leftMargin: 14
            }
            width: 178
            spacing: 2

            Repeater {
                model: root.shelf

                delegate: Rectangle {
                    id: kind

                    required property var modelData
                    readonly property bool on: root.category === modelData[0] && root.query === ""

                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Theme.radius
                    color: kind.on ? Theme.sel : kindMa.containsMouse ? Theme.hoverRaised : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.anim
                        }
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 10

                        BarText {
                            Layout.preferredWidth: 18
                            horizontalAlignment: Text.AlignHCenter
                            text: String.fromCodePoint(kind.modelData[2])
                            font.pixelSize: root.fs + 2
                            color: kind.on ? Theme.bright : Theme.dim
                        }

                        BarText {
                            Layout.fillWidth: true
                            text: kind.modelData[1]
                            font.pixelSize: root.fs - 1
                            weight: root.wt
                            color: kind.on ? Theme.bright : Theme.text
                        }

                        BarText {
                            text: kind.modelData[3]
                            font.pixelSize: root.fs - 3
                            weight: root.wt
                            color: Theme.dim
                        }
                    }

                    MouseArea {
                        id: kindMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            search.text = "";
                            root.category = kind.modelData[0];
                            grid.currentIndex = 0;
                            search.forceActiveFocus();
                        }
                    }
                }
            }
        }

        Rectangle {
            id: divider
            anchors {
                top: searchBox.bottom
                topMargin: 14
                bottom: parent.bottom
                bottomMargin: 16
                left: side.right
                leftMargin: 12
            }
            width: 1
            color: Theme.edge
        }

        Item {
            id: content

            anchors {
                top: searchBox.bottom
                topMargin: 10
                left: divider.right
                leftMargin: 10
                right: parent.right
                rightMargin: 12
                bottom: parent.bottom
                bottomMargin: 12
            }

            ColumnLayout {
                id: favs

                visible: root.showFavourites
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                spacing: 6

                BarText {
                    Layout.leftMargin: 6
                    Layout.topMargin: 4
                    text: "Sık kullanılanlar"
                    font.pixelSize: root.fs - 3
                    weight: 600
                    color: Theme.dim
                }

                Row {
                    spacing: 0

                    Repeater {
                        model: root.favourites

                        delegate: AppCell {
                            required property var modelData
                            required property int index

                            app: modelData
                            width: grid.cellWidth
                            height: 96
                            hint: `Alt+${index + 1}`
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    Layout.bottomMargin: 2
                    implicitHeight: 1
                    color: Theme.edge
                }
            }

            GridView {
                id: grid

                anchors {
                    top: root.showFavourites ? favs.bottom : parent.top
                    topMargin: root.showFavourites ? 6 : 4
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                clip: true
                model: root.apps
                cellWidth: Math.floor(width / 6)
                cellHeight: 104
                boundsBehavior: Flickable.StopAtBounds
                highlightFollowsCurrentItem: false

                delegate: AppCell {
                    required property var modelData
                    required property int index

                    app: modelData
                    width: grid.cellWidth
                    height: grid.cellHeight
                    current: grid.currentIndex === index
                }
            }

            BarText {
                anchors.centerIn: grid
                visible: root.apps.length === 0
                text: "Sonuç yok"
                font.pixelSize: root.fs
                weight: root.wt
                color: Theme.dim
            }
        }

        Surface {
            id: menu

            readonly property var app: root.menuApp
            readonly property var actions: app?.actions ?? []
            readonly property point at: panel.mapFromItem(null, root.menuAt.x, root.menuAt.y)

            visible: !!app
            x: Math.min(at.x, panel.width - width - 8)
            y: Math.min(at.y, panel.height - height - 8)
            width: 236
            height: menuBody.implicitHeight + 16
            radius: Theme.radius + 2
            z: 10

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: menuBody

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 2

                BarText {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.bottomMargin: 4
                    text: menu.app?.name ?? ""
                    elide: Text.ElideRight
                    font.pixelSize: root.fs - 2
                    weight: 650
                    color: Theme.bright
                }

                MenuRow {
                    label: DrawerState.isPinned(menu.app?.id ?? "") ? "Sabitlemeyi kaldır" : "Sık kullanılanlara sabitle"
                    onClicked: {
                        DrawerState.togglePin(menu.app.id);
                        root.menuApp = null;
                    }
                }

                MenuRow {
                    label: root.windowOf(menu.app ?? {}) ? "Yeni pencere aç" : "Aç"
                    onClicked: root.launch(menu.app, true)
                }

                Repeater {
                    model: menu.actions

                    delegate: MenuRow {
                        required property var modelData

                        label: modelData.name
                        onClicked: {
                            modelData.execute();
                            DrawerState.launched(menu.app.id);
                            Panels.drawerOpen = false;
                        }
                    }
                }
            }
        }
    }

    component MenuRow: Pick {
        implicitHeight: 30
        textSize: root.fs - 2
        weight: root.wt
    }

    component AppCell: Item {
        id: cell

        property var app
        property bool current: false
        property string hint: ""
        readonly property string icon: root.iconOf(cell.app)
        readonly property bool running: !!root.windowOf(cell.app ?? {})

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 10
            color: cell.current ? Theme.selRaised : area.containsMouse ? Theme.hoverRaised : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Theme.anim
                }
            }
        }

        Item {
            id: iconBox

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 14
            }
            width: 46
            height: 46
            scale: area.pressed ? 0.92 : area.containsMouse ? 1.06 : 1

            Behavior on scale {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            IconImage {
                anchors.fill: parent
                visible: cell.icon !== ""
                source: cell.icon
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                visible: cell.icon === ""
                radius: 10
                color: Theme.rule
                border.width: 1
                border.color: Theme.edge

                BarText {
                    anchors.centerIn: parent
                    text: (cell.app?.name ?? "?").charAt(0).toUpperCase()
                    font.pixelSize: 18
                    weight: 650
                }
            }
        }

        Rectangle {
            visible: cell.running
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: iconBox.bottom
                topMargin: 4
            }
            width: 4
            height: 4
            radius: 2
            color: Theme.bright
        }

        BarText {
            anchors {
                top: iconBox.bottom
                topMargin: 12
                left: parent.left
                right: parent.right
                leftMargin: 8
                rightMargin: 8
            }
            text: cell.app?.name ?? ""
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: root.fs - 2
            weight: root.wt
            color: cell.current ? Theme.bright : Theme.text
        }

        BarText {
            visible: DrawerState.isPinned(cell.app?.id ?? "")
            anchors {
                top: parent.top
                right: parent.right
                topMargin: 8
                rightMargin: 10
            }
            text: String.fromCodePoint(0xF0403)
            font.pixelSize: root.fs - 3
            color: Theme.dim
        }

        BarText {
            visible: cell.hint !== "" && area.containsMouse
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 8
                leftMargin: 10
            }
            text: cell.hint
            font.pixelSize: root.fs - 5
            weight: root.wt
            color: Theme.dim
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: e => {
                if (e.button === Qt.RightButton)
                    root.openMenu(cell.app, mapToItem(null, e.x, e.y));
                else
                    root.launch(cell.app, e.button === Qt.MiddleButton);
            }
        }
    }
}
