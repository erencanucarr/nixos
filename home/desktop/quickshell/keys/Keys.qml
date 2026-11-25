import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.common

PanelWindow {
    id: root

    readonly property int fs: Theme.menuSize
    readonly property int wt: Theme.menuWeight

    readonly property var order: ["Masaüstü", "Uygulamalar", "Pencereler", "Çalışma alanları", "Ekran görüntüsü", "Oturum", "Ses ve medya"]

    property var groups: []
    property string query: ""
    property bool shown: false

    readonly property var names: ({
            "Super_L": "",
            "RETURN": "Enter",
            "ESCAPE": "Esc",
            "SPACE": "Space",
            "TAB": "Tab",
            "LEFT": "←",
            "RIGHT": "→",
            "UP": "↑",
            "DOWN": "↓",
            "Print": "PrtSc",
            "mouse:272": "Sol tık",
            "mouse:273": "Sağ tık",
            "mouse:276": "Fare yan tuşu",
            "mouse:277": "Fare yan tuşu",
            "mouse_down": "Tekerlek ↓",
            "mouse_up": "Tekerlek ↑",
            "XF86AudioRaiseVolume": "Ses +",
            "XF86AudioLowerVolume": "Ses −",
            "XF86AudioMute": "Sessiz",
            "XF86AudioMicMute": "Mikrofon",
            "XF86AudioPlay": "Oynat",
            "XF86AudioPause": "Duraklat",
            "XF86AudioNext": "Sonraki",
            "XF86AudioPrev": "Önceki"
        })

    function mods(mask: int): var {
        const out = [];
        if (mask & 64)
            out.push("Super");
        if (mask & 4)
            out.push("Ctrl");
        if (mask & 8)
            out.push("Alt");
        if (mask & 1)
            out.push("Shift");
        return out;
    }

    function keyName(k: string): string {
        if (k in root.names)
            return root.names[k];
        return k.length === 1 ? k.toUpperCase() : k;
    }

    function combos(binds: var): var {
        const byMods = new Map();
        for (const b of binds) {
            const m = root.mods(b.modmask).join("+");
            if (!byMods.has(m))
                byMods.set(m, []);
            const name = root.keyName(b.key);
            if (!byMods.get(m).includes(name))
                byMods.get(m).push(name);
        }
        const out = [];
        for (const [m, keys] of byMods) {
            const head = m ? m.split("+") : [];
            if (keys.length > 5)
                out.push(head.concat([`${keys[0]} … ${keys[keys.length - 1]}`]));
            else if (keys.length > 2 && keys.every(k => k.length === 1))
                out.push(head.concat([keys.join(" ")]));
            else
                for (const k of keys)
                    out.push(k ? head.concat([k]) : head);
        }
        return out;
    }

    function build(json: string): void {
        let binds = [];
        try {
            binds = JSON.parse(json).filter(b => b.has_description);
        } catch (e) {
            console.warn(`keys: ${e}`);
        }
        const cats = new Map();
        for (const b of binds) {
            const at = b.description.indexOf(": ");
            const cat = at > 0 ? b.description.slice(0, at) : "Diğer";
            const what = at > 0 ? b.description.slice(at + 2) : b.description;
            if (!cats.has(cat))
                cats.set(cat, new Map());
            const rows = cats.get(cat);
            if (!rows.has(what))
                rows.set(what, []);
            rows.get(what).push(b);
        }
        const out = [];
        const names = [...cats.keys()].sort((a, b) => {
            const ia = root.order.indexOf(a), ib = root.order.indexOf(b);
            return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib);
        });
        for (const cat of names)
            out.push({
                name: cat,
                rows: [...cats.get(cat)].map(([what, bs]) => ({
                            what,
                            combos: root.combos(bs)
                        }))
            });
        root.groups = out;
    }

    function matches(row: var): bool {
        const q = root.query.trim().toLocaleLowerCase("tr");
        if (!q)
            return true;
        const hay = (row.what + " " + row.combos.map(c => c.join(" ")).join(" ")).toLocaleLowerCase("tr");
        return q.split(/\s+/).every(w => hay.includes(w));
    }

    readonly property var shownGroups: root.groups.map(g => ({
                name: g.name,
                rows: g.rows.filter(r => root.matches(r))
            })).filter(g => g.rows.length > 0)

    screen: Quickshell.screens.find(s => s.name === Panels.keysScreen) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "ecu-keys"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Qt.alpha(Theme.ground, 0.65)

    Component.onCompleted: {
        reader.running = true;
        search.forceActiveFocus();
        root.shown = true;
    }

    Process {
        id: reader

        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.build(text)
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Panels.keysOpen = false
    }

    component Cap: Rectangle {
        required property string label

        implicitWidth: Math.max(implicitHeight, capText.implicitWidth + 14)
        implicitHeight: 24
        radius: 5
        color: Theme.ground
        border.width: 1
        border.color: Theme.edge

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 1
            }
            height: 2
            radius: 1
            color: Theme.ring
        }

        BarText {
            id: capText
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            text: parent.label
            font.pixelSize: root.fs - 2
            weight: 600
            color: Theme.bright
        }
    }

    Surface {
        id: panel

        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.shown ? 0 : 10
        width: Math.min(parent.width - 120, 1160)
        height: Math.min(parent.height - 120, 820)
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
        }

        RowLayout {
            id: top

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 20
            }
            spacing: 14

            BarText {
                text: "Kısayollar"
                font.pixelSize: 20
                weight: 650
                color: Theme.bright
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredWidth: 280
                implicitHeight: 34
                radius: 8
                color: Theme.ground
                border.width: 1
                border.color: search.activeFocus ? Theme.rule : Theme.line

                BarText {
                    id: glass
                    anchors {
                        left: parent.left
                        leftMargin: 11
                        verticalCenter: parent.verticalCenter
                    }
                    text: Glyph.search
                    font.pixelSize: 15
                    color: Theme.dim
                }

                TextInput {
                    id: search

                    anchors {
                        left: glass.right
                        leftMargin: 8
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    color: Theme.text
                    selectionColor: Theme.text
                    selectedTextColor: Theme.ground
                    font.family: "Inter Variable"
                    font.variableAxes: ({
                            wght: root.wt
                        })
                    font.pixelSize: root.fs
                    clip: true
                    onTextChanged: root.query = text

                    Keys.onEscapePressed: {
                        if (search.text)
                            search.text = "";
                        else
                            Panels.keysOpen = false;
                    }

                    BarText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text === ""
                        text: "İşlem ya da tuş ara"
                        font.pixelSize: root.fs
                        weight: root.wt
                        color: Theme.dim
                    }
                }
            }
        }

        Flickable {
            id: flick

            anchors {
                top: top.bottom
                topMargin: 16
                left: parent.left
                right: parent.right
                bottom: foot.top
                leftMargin: 20
                rightMargin: 20
                bottomMargin: 10
            }
            clip: true
            contentHeight: columns.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            GridLayout {
                id: columns

                width: flick.width
                columns: width > 820 ? 2 : 1
                columnSpacing: 28
                rowSpacing: 22

                Repeater {
                    model: root.shownGroups

                    delegate: ColumnLayout {
                        id: group

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 0

                        BarText {
                            Layout.bottomMargin: 8
                            text: group.modelData.name
                            font.pixelSize: root.fs + 1
                            weight: 650
                            color: Theme.bright
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.bottomMargin: 4
                            Layout.leftMargin: 10
                            Layout.rightMargin: 10

                            BarText {
                                Layout.fillWidth: true
                                text: "İşlem"
                                font.pixelSize: root.fs - 3
                                weight: 600
                                font.letterSpacing: 0.4
                                color: Theme.dim
                            }

                            BarText {
                                text: "Tuşlar"
                                font.pixelSize: root.fs - 3
                                weight: 600
                                font.letterSpacing: 0.4
                                color: Theme.dim
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Theme.edge
                        }

                        Repeater {
                            model: group.modelData.rows

                            delegate: Rectangle {
                                id: row

                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                implicitHeight: Math.max(38, caps.implicitHeight + 12)
                                color: rowMa.containsMouse ? Theme.hoverRaised : row.index % 2 ? "transparent" : Qt.rgba(1, 1, 1, 0.015)
                                radius: 4

                                MouseArea {
                                    id: rowMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }

                                BarText {
                                    anchors {
                                        left: parent.left
                                        leftMargin: 10
                                        right: caps.left
                                        rightMargin: 12
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: row.modelData.what
                                    elide: Text.ElideRight
                                    font.pixelSize: root.fs - 1
                                    weight: root.wt
                                    color: Theme.text
                                }

                                Row {
                                    id: caps

                                    anchors {
                                        right: parent.right
                                        rightMargin: 10
                                        verticalCenter: parent.verticalCenter
                                    }
                                    spacing: 6

                                    Repeater {
                                        model: row.modelData.combos

                                        delegate: Row {
                                            id: combo

                                            required property var modelData
                                            required property int index

                                            spacing: 4

                                            BarText {
                                                visible: combo.index > 0
                                                anchors.verticalCenter: parent.verticalCenter
                                                rightPadding: 2
                                                text: "ya da"
                                                font.pixelSize: root.fs - 4
                                                weight: root.wt
                                                color: Theme.dim
                                            }

                                            Repeater {
                                                model: combo.modelData

                                                delegate: Row {
                                                    id: part

                                                    required property string modelData
                                                    required property int index

                                                    spacing: 4

                                                    BarText {
                                                        visible: part.index > 0
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "+"
                                                        font.pixelSize: root.fs - 3
                                                        color: Theme.dim
                                                    }

                                                    Cap {
                                                        label: part.modelData
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

        BarText {
            anchors.centerIn: flick
            visible: root.groups.length > 0 && root.shownGroups.length === 0
            text: "Eşleşen kısayol yok"
            font.pixelSize: root.fs
            weight: root.wt
            color: Theme.dim
        }

        BarText {
            id: foot

            anchors {
                bottom: parent.bottom
                bottomMargin: 14
                horizontalCenter: parent.horizontalCenter
            }
            text: "Liste Hyprland'den canlı okunur · Esc kapatır"
            font.pixelSize: root.fs - 3
            weight: root.wt
            color: Theme.dim
        }
    }
}
