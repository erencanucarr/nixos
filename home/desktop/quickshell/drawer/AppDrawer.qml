import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

PanelWindow {
    id: root

    readonly property int fs: Theme.menuSize
    readonly property int wt: Theme.menuWeight

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

    readonly property var kindById: {
        const out = {};
        for (const a of root.all)
            out[a.id] = root.kindOf(a);
        return out;
    }

    readonly property var running: {
        const out = {};
        for (const t of Hyprland.toplevels.values)
            out[Windows.classOf(t)] = true;
        return out;
    }

    readonly property var shelf: {
        const counts = {};
        for (const a of root.all) {
            const k = root.kindById[a.id];
            counts[k] = (counts[k] ?? 0) + 1;
        }
        const out = [["all", "Tümü", 0xF003B, root.all.length]];
        for (const k of root.kinds)
            if (counts[k[0]])
                out.push([k[0], k[1], k[2], counts[k[0]]]);
        if (counts.other)
            out.push(["other", "Diğer", 0xF01D8, counts.other]);
        return out;
    }

    readonly property string sectionTitle: {
        if (root.query.trim() !== "")
            return `ARAMA  ·  ${root.apps.length} SONUÇ`;
        const s = root.shelf.find(k => k[0] === root.category);
        return `${(s?.[1] ?? "Tümü").toLocaleUpperCase("tr-TR")}  ·  ${root.apps.length}`;
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
            return root.category === "all" ? root.all : root.all.filter(a => root.kindById[a.id] === root.category);
        return root.all.map(a => [a, q.split(/\s+/).reduce((s, w) => Math.min(s, root.rank(a, w)), 100)]).filter(x => x[1] > 0).sort((x, y) => y[1] - x[1] || DrawerState.score(y[0].id) - DrawerState.score(x[0].id)).map(x => x[0]);
    }

    readonly property var favourites: {
        const byId = id => root.all.find(a => a.id === id);
        const pinned = DrawerState.pinned.map(byId).filter(a => !!a);
        const used = root.all.filter(a => !DrawerState.isPinned(a.id) && DrawerState.score(a.id) > 0).sort((a, b) => DrawerState.score(b.id) - DrawerState.score(a.id));
        return pinned.concat(used).slice(0, 6);
    }

    readonly property bool showFavourites: root.query === "" && root.category === "all" && root.favourites.length > 0

    function keysOf(app: var): var {
        return [app?.id, app?.startupClass, app?.name].filter(k => !!k).map(k => k.toLowerCase().replace(/\.desktop$/, ""));
    }

    function isRunning(app: var): bool {
        return root.keysOf(app).some(k => root.running[k] === true);
    }

    function iconOf(app: var): string {
        return Quickshell.iconPath(app?.icon ?? "", true) || Quickshell.iconPath("application-x-executable", true) || "";
    }

    function subtitleOf(app: var): string {
        const g = app?.genericName ?? "";
        return g && g !== app?.name ? g : (app?.comment ?? "");
    }

    function launch(app: var, fresh: bool): void {
        if (!app)
            return;
        const win = fresh ? null : Windows.forKeys(root.keysOf(app));
        if (win)
            Windows.focus(win);
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

    WlrLayershell.namespace: "ecu-drawer"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Qt.alpha(Theme.ground, 0.6)

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
        width: Math.min(parent.width - 160, 920)
        height: Math.min(parent.height - 140, 660)
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
                margins: 14
            }
            height: 52
            radius: Theme.radiusLg
            color: Theme.ground
            border.width: 1
            border.color: search.activeFocus ? Theme.rule : Theme.edge

            Tile {
                id: searchIcon
                anchors {
                    left: parent.left
                    leftMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                implicitWidth: 36
                implicitHeight: 36
                glyph: Glyph.search
                glyphSize: 16
                tone: search.text !== "" ? Theme.bright : Theme.dim
            }

            TextInput {
                id: search

                anchors {
                    left: searchIcon.right
                    leftMargin: 12
                    right: count.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                color: Theme.bright
                selectionColor: Theme.text
                selectedTextColor: Theme.ground
                font.family: "Inter Variable"
                font.variableAxes: ({
                        wght: root.wt
                    })
                font.pixelSize: root.fs + 2
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
                    text: "Uygulama ara"
                    font.pixelSize: root.fs + 2
                    weight: root.wt
                    color: Theme.dim
                }
            }

            Tag {
                id: count
                anchors {
                    right: parent.right
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                text: `${root.apps.length} uygulama`
                tone: Theme.dim
            }
        }

        ColumnLayout {
            id: side

            anchors {
                top: searchBox.bottom
                topMargin: 12
                bottom: parent.bottom
                bottomMargin: 14
                left: parent.left
                leftMargin: 14
            }
            width: 196
            spacing: 8

            Card {
                padding: 6
                spacing: 2

                Repeater {
                    model: root.shelf

                    delegate: Rectangle {
                        id: kind

                        required property var modelData
                        readonly property bool on: root.category === modelData[0] && root.query === ""

                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: Theme.radius + 1
                        color: kind.on ? Theme.selRaised : kindMa.containsMouse ? Theme.hoverRaised : "transparent"
                        border.width: kind.on ? 1 : 0
                        border.color: Theme.edge

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.anim
                            }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 6
                                rightMargin: 8
                            }
                            spacing: 10

                            Rectangle {
                                implicitWidth: 26
                                implicitHeight: 26
                                radius: Theme.radius
                                color: kind.on ? Theme.hoverRaised : "transparent"

                                BarText {
                                    anchors.centerIn: parent
                                    text: String.fromCodePoint(kind.modelData[2])
                                    font.pixelSize: root.fs + 1
                                    color: kind.on ? Theme.bright : Theme.dim
                                }
                            }

                            BarText {
                                Layout.fillWidth: true
                                text: kind.modelData[1]
                                elide: Text.ElideRight
                                font.pixelSize: root.fs - 1
                                weight: kind.on ? 650 : root.wt
                                color: kind.on ? Theme.bright : Theme.text
                            }

                            BarText {
                                text: kind.modelData[3]
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: root.fs - 4
                                color: kind.on ? Theme.text : Theme.dim
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

            Item {
                Layout.fillHeight: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                spacing: 5

                Repeater {
                    model: [["↹", "kategori değiştir"], ["↵", "aç"], ["Ctrl ↵", "yeni pencere"], ["Alt 1–6", "sık kullanılan"], ["Sağ tık", "seçenekler"]]

                    delegate: RowLayout {
                        id: hint

                        required property var modelData

                        spacing: 8

                        Rectangle {
                            implicitWidth: Math.max(22, keyText.implicitWidth + 10)
                            implicitHeight: 18
                            radius: 4
                            color: Theme.hoverRaised
                            border.width: 1
                            border.color: Theme.edge

                            BarText {
                                id: keyText
                                anchors.centerIn: parent
                                text: hint.modelData[0]
                                font.pixelSize: 9
                                weight: 650
                                color: Theme.text
                            }
                        }

                        BarText {
                            text: hint.modelData[1]
                            font.pixelSize: root.fs - 4
                            weight: root.wt
                            color: Theme.dim
                        }
                    }
                }
            }
        }

        Item {
            id: content

            anchors {
                top: searchBox.bottom
                topMargin: 12
                left: side.right
                leftMargin: 12
                right: parent.right
                rightMargin: 14
                bottom: parent.bottom
                bottomMargin: 14
            }

            Card {
                id: favs

                visible: root.showFavourites
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                padding: 10
                spacing: 8

                Caption {
                    Layout.leftMargin: 2
                    text: "SIK KULLANILANLAR"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: root.favourites

                        delegate: Rectangle {
                            id: fav

                            required property var modelData
                            required property int index
                            readonly property string icon: root.iconOf(fav.modelData)
                            readonly property bool running: root.isRunning(fav.modelData)

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 92
                            radius: Theme.radius + 2
                            color: favMa.containsMouse ? Theme.selRaised : Theme.hoverRaised
                            border.width: 1
                            border.color: Theme.edge

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.anim
                                }
                            }

                            IconImage {
                                id: favIcon
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: 12
                                implicitSize: 38
                                source: fav.icon
                                scale: favMa.pressed ? 0.92 : favMa.containsMouse ? 1.06 : 1

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 140
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            BarText {
                                anchors.top: favIcon.bottom
                                anchors.topMargin: 7
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                horizontalAlignment: Text.AlignHCenter
                                text: fav.modelData?.name ?? ""
                                elide: Text.ElideRight
                                font.pixelSize: root.fs - 3
                                weight: 600
                                color: Theme.text
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.margins: 6
                                width: altText.implicitWidth + 8
                                height: 15
                                radius: 4
                                color: "transparent"
                                border.width: 1
                                border.color: Theme.edge

                                BarText {
                                    id: altText
                                    anchors.centerIn: parent
                                    text: `Alt ${fav.index + 1}`
                                    font.pixelSize: 8
                                    weight: 650
                                    color: Theme.dim
                                }
                            }

                            Rectangle {
                                visible: fav.running
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 9
                                width: 6
                                height: 6
                                radius: 3
                                color: Theme.green
                            }

                            BarText {
                                visible: DrawerState.isPinned(fav.modelData?.id ?? "") && !fav.running
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.topMargin: 5
                                anchors.rightMargin: 7
                                text: Glyph.pin
                                font.pixelSize: root.fs - 4
                                color: Theme.dim
                            }

                            MouseArea {
                                id: favMa
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: e => {
                                    if (e.button === Qt.RightButton)
                                        root.openMenu(fav.modelData, mapToItem(null, e.x, e.y));
                                    else
                                        root.launch(fav.modelData, e.button === Qt.MiddleButton);
                                }
                            }
                        }
                    }

                    Repeater {
                        model: Math.max(0, 6 - root.favourites.length)

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                        }
                    }
                }
            }

            Caption {
                id: section
                anchors {
                    top: root.showFavourites ? favs.bottom : parent.top
                    topMargin: root.showFavourites ? 14 : 4
                    left: parent.left
                    leftMargin: 4
                }
                text: root.sectionTitle
            }

            GridView {
                id: grid

                anchors {
                    top: section.bottom
                    topMargin: 8
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                clip: true
                model: root.apps
                cellWidth: Math.floor(width / 5)
                cellHeight: 120
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

            Column {
                anchors.centerIn: grid
                visible: root.apps.length === 0
                spacing: 8

                Tile {
                    anchors.horizontalCenter: parent.horizontalCenter
                    glyph: Glyph.search
                    tone: Theme.dim
                }

                BarText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Sonuç yok"
                    font.pixelSize: root.fs
                    weight: 600
                    color: Theme.text
                }

                BarText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: `"${root.query.trim()}" ile eşleşen uygulama bulunamadı`
                    font.pixelSize: root.fs - 3
                    weight: root.wt
                    color: Theme.dim
                }
            }
        }

        Rectangle {
            id: menu

            readonly property var app: root.menuApp
            readonly property var actions: app?.actions ?? []
            readonly property point at: panel.mapFromItem(null, root.menuAt.x, root.menuAt.y)

            visible: !!app
            x: Math.min(at.x, panel.width - width - 8)
            y: Math.min(at.y, panel.height - height - 8)
            width: 250
            height: menuBody.implicitHeight + 20
            radius: Theme.radiusLg
            color: Theme.raised
            border.width: 1
            border.color: Theme.edge
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
                    margins: 10
                }
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 6
                    spacing: 10

                    IconImage {
                        implicitSize: 28
                        source: root.iconOf(menu.app)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        BarText {
                            Layout.fillWidth: true
                            text: menu.app?.name ?? ""
                            elide: Text.ElideRight
                            font.pixelSize: root.fs - 1
                            weight: 650
                            color: Theme.bright
                        }

                        BarText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: root.subtitleOf(menu.app)
                            elide: Text.ElideRight
                            font.pixelSize: root.fs - 4
                            weight: root.wt
                            color: Theme.dim
                        }
                    }
                }

                Rule {
                    Layout.bottomMargin: 4
                }

                MenuRow {
                    glyph: DrawerState.isPinned(menu.app?.id ?? "") ? Glyph.pinOff : Glyph.pin
                    label: DrawerState.isPinned(menu.app?.id ?? "") ? "Sabitlemeyi kaldır" : "Sık kullanılanlara sabitle"
                    onClicked: {
                        DrawerState.togglePin(menu.app.id);
                        root.menuApp = null;
                    }
                }

                MenuRow {
                    glyph: String.fromCodePoint(0xF0415)
                    label: root.isRunning(menu.app) ? "Yeni pencere aç" : "Aç"
                    onClicked: root.launch(menu.app, true)
                }

                Repeater {
                    model: menu.actions

                    delegate: MenuRow {
                        required property var modelData

                        glyph: Glyph.chevronRight
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

    component MenuRow: Rectangle {
        id: mrow

        property string glyph
        required property string label
        signal clicked

        Layout.fillWidth: true
        implicitHeight: 32
        radius: Theme.radius
        color: mrowMa.containsMouse ? Theme.hoverRaised : "transparent"

        BarText {
            id: mrowGlyph
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            horizontalAlignment: Text.AlignHCenter
            text: mrow.glyph
            font.pixelSize: root.fs
            color: mrowMa.containsMouse ? Theme.bright : Theme.dim
        }

        BarText {
            anchors.left: mrowGlyph.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: mrow.label
            elide: Text.ElideRight
            font.pixelSize: root.fs - 2
            weight: root.wt
            color: mrowMa.containsMouse ? Theme.bright : Theme.text
        }

        MouseArea {
            id: mrowMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mrow.clicked()
        }
    }

    component AppCell: Item {
        id: cell

        property var app
        property bool current: false
        readonly property string icon: root.iconOf(cell.app)
        readonly property bool running: root.isRunning(cell.app)
        readonly property string subtitle: root.subtitleOf(cell.app)

        Rectangle {
            id: card
            anchors.fill: parent
            anchors.margins: 4
            radius: Theme.radiusLg
            color: cell.current ? Theme.selRaised : area.containsMouse ? Theme.hoverRaised : Theme.card
            border.width: 1
            border.color: cell.current ? Qt.alpha(Theme.text, 0.35) : area.containsMouse ? Theme.edge : "transparent"

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
                topMargin: 16
            }
            width: 44
            height: 44
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

        BarText {
            id: cellName
            anchors {
                top: iconBox.bottom
                topMargin: 10
                left: parent.left
                right: parent.right
                leftMargin: 12
                rightMargin: 12
            }
            text: cell.app?.name ?? ""
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: root.fs - 2
            weight: 600
            color: cell.current ? Theme.bright : Theme.text
        }

        BarText {
            anchors {
                top: cellName.bottom
                topMargin: 2
                left: parent.left
                right: parent.right
                leftMargin: 12
                rightMargin: 12
            }
            visible: cell.subtitle !== ""
            text: cell.subtitle
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: root.fs - 5
            weight: root.wt
            color: Theme.dim
        }

        Rectangle {
            visible: cell.running
            anchors {
                top: parent.top
                right: parent.right
                topMargin: 13
                rightMargin: 13
            }
            width: 6
            height: 6
            radius: 3
            color: Theme.green
        }

        BarText {
            visible: DrawerState.isPinned(cell.app?.id ?? "")
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 9
                leftMargin: 12
            }
            text: Glyph.pin
            font.pixelSize: root.fs - 3
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
