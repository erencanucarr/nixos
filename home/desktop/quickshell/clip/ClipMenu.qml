import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

Popup {
    id: root

    readonly property int fs: Theme.menuSize
    readonly property int wt: Theme.menuWeight

    property string query: ""
    property bool confirmWipe: false
    property bool settings: false
    property real now: Date.now()

    readonly property var dayOptions: [
        {
            name: "1 gün",
            value: 1
        },
        {
            name: "7 gün",
            value: 7
        },
        {
            name: "30 gün",
            value: 30
        },
        {
            name: "Sınırsız",
            value: 0
        }
    ]
    readonly property var countOptions: [50, 200, 500, 1000].map(n => ({
                name: String(n),
                value: n
            }))

    function ago(at: var): string {
        if (!at)
            return "";
        const mins = Math.floor((root.now / 1000 - at) / 60);
        if (mins < 1)
            return "şimdi";
        if (mins < 60)
            return `${mins} dk`;
        if (mins < 1440)
            return `${Math.floor(mins / 60)} sa`;
        return `${Math.floor(mins / 1440)} gün`;
    }
    readonly property var shown: {
        const q = root.query.trim().toLocaleLowerCase("tr");
        if (q === "")
            return ClipData.items;
        return ClipData.items.filter(i => i.kind === "image" ? "görsel resim image".includes(q) || i.ext.includes(q) : i.text.toLocaleLowerCase("tr").includes(q));
    }

    contentWidth: 400
    contentHeight: body.implicitHeight + 2 * Theme.pad + 4

    function pick(item: var): void {
        if (!item)
            return;
        ClipData.copy(item.id);
        root.close();
    }

    function focusSearch(): void {
        search.input.forceActiveFocus();
    }

    onVisibleChanged: if (visible) {
        root.query = "";
        root.confirmWipe = false;
        root.settings = false;
        root.now = Date.now();
        list.currentIndex = 0;
        ClipData.refresh();
        ClipData.loadConfig();
        Qt.callLater(root.focusSearch);
    }
    Component.onCompleted: {
        ClipData.refresh();
        ClipData.loadConfig();
        Qt.callLater(root.focusSearch);
    }

    onSettingsChanged: if (!settings)
        Qt.callLater(root.focusSearch)

    Timer {
        interval: 30000
        running: root.visible
        repeat: true
        onTriggered: root.now = Date.now()
    }

    component Option: RowLayout {
        id: option

        required property string title
        property string detail: ""
        property bool on: false

        signal toggled

        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            BarText {
                Layout.fillWidth: true
                text: option.title
                font.pixelSize: root.fs - 2
                weight: 600
                color: Theme.bright
            }

            BarText {
                visible: option.detail !== ""
                Layout.fillWidth: true
                text: option.detail
                wrapMode: Text.WordWrap
                font.pixelSize: root.fs - 4
                weight: root.wt
                color: Theme.dim
            }
        }

        Toggle {
            on: option.on
            onToggled: option.toggled()
        }
    }

    onShownChanged: list.currentIndex = Math.min(Math.max(list.currentIndex, 0), root.shown.length - 1)

    Timer {
        interval: 3000
        running: root.confirmWipe
        onTriggered: root.confirmWipe = false
    }

    ColumnLayout {
        id: body

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: Theme.pad + 2
            leftMargin: Theme.pad + 2
            rightMargin: Theme.pad + 2
        }
        spacing: 8

        Card {
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Tile {
                    glyph: Glyph.clipboard
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Caption {
                        text: "PANO"
                    }

                    BarText {
                        Layout.fillWidth: true
                        text: root.settings ? "Ayarlar" : ClipData.config.paused ? "Kayıt duraklatıldı" : ClipData.items.length > 0 ? `${ClipData.items.length} kayıt` : "Geçmiş boş"
                        font.pixelSize: root.fs - 1
                        weight: 600
                        color: !root.settings && ClipData.config.paused ? Theme.warm : root.settings || ClipData.items.length > 0 ? Theme.bright : Theme.dim
                    }
                }

                Tile {
                    implicitWidth: 30
                    implicitHeight: 30
                    glyphSize: 15
                    glyph: root.settings ? Glyph.chevronLeft : Glyph.cog
                    tone: root.settings ? Theme.bright : Theme.dim
                    lit: root.settings
                    clickable: true
                    onClicked: root.settings = !root.settings
                }

                Tag {
                    visible: !root.settings && ClipData.items.length > 0
                    text: root.confirmWipe ? "Emin misin?" : "Temizle"
                    tone: root.confirmWipe ? Theme.hot : Theme.text
                    accent: root.confirmWipe
                    clickable: true
                    onClicked: {
                        if (root.confirmWipe) {
                            root.confirmWipe = false;
                            ClipData.wipe();
                        } else {
                            root.confirmWipe = true;
                        }
                    }
                }
            }

            Field {
                id: search

                visible: !root.settings
                implicitHeight: 30
                textSize: root.fs - 2
                placeholder: `${Glyph.search}  Ara`
                onAccepted: root.pick(root.shown[list.currentIndex])

                onTextChanged: {
                    root.query = search.text;
                    list.currentIndex = 0;
                    list.positionViewAtBeginning();
                }
                onKeyPressed: e => {
                    if (e.key === Qt.Key_Escape) {
                        root.close();
                    } else if (e.key === Qt.Key_Down) {
                        list.incrementCurrentIndex();
                    } else if (e.key === Qt.Key_Up) {
                        list.decrementCurrentIndex();
                    } else if (e.key === Qt.Key_Delete && (e.modifiers & Qt.ShiftModifier)) {
                        const item = root.shown[list.currentIndex];
                        if (item)
                            ClipData.remove(item.id);
                    } else {
                        return;
                    }
                    e.accepted = true;
                }
            }
        }

        Card {
            visible: root.settings
            spacing: 10

            Caption {
                text: "KAYIT SÜRESİ"
            }

            Segments {
                options: root.dayOptions
                selected: o => ClipData.config.days === o.value
                onPicked: o => ClipData.set("days", o.value)
            }

            Caption {
                Layout.topMargin: 4
                text: "EN FAZLA KAYIT"
            }

            Segments {
                options: root.countOptions
                selected: o => ClipData.config.maxItems === o.value
                onPicked: o => ClipData.set("maxItems", o.value)
            }

            Rule {
                Layout.topMargin: 4
            }

            Option {
                title: "Görselleri kaydet"
                detail: "Ekran görüntüleri ve kopyalanan resimler"
                on: ClipData.config.images
                onToggled: ClipData.set("images", !ClipData.config.images)
            }

            Option {
                title: "Kaydı duraklat"
                detail: "Kopyaladıkların geçmişe eklenmez"
                on: ClipData.config.paused
                onToggled: ClipData.set("paused", !ClipData.config.paused)
            }

            Rule {}

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                BarText {
                    Layout.fillWidth: true
                    text: "Varsayılanlar Nix'ten gelir (ecu.clipboard)"
                    elide: Text.ElideRight
                    font.pixelSize: root.fs - 4
                    weight: root.wt
                    color: Theme.dim
                }

                Tag {
                    text: "Varsayılana dön"
                    clickable: true
                    onClicked: ClipData.reset()
                }
            }
        }

        Card {
            visible: !root.settings
            padding: 6
            spacing: 0

            BarText {
                visible: root.shown.length === 0
                Layout.fillWidth: true
                Layout.margins: 10
                horizontalAlignment: Text.AlignHCenter
                text: !ClipData.loaded ? "Yükleniyor…" : ClipData.items.length === 0 ? "Kopyaladığın metin ve görseller burada görünür" : "Eşleşen kayıt yok"
                wrapMode: Text.WordWrap
                font.pixelSize: root.fs - 3
                weight: root.wt
                color: Theme.dim
            }

            ListView {
                id: list

                visible: root.shown.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 420)
                model: root.shown
                clip: true
                spacing: 2
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                keyNavigationEnabled: false

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    readonly property bool image: row.modelData.kind === "image"
                    readonly property bool current: ListView.isCurrentItem

                    width: ListView.view.width
                    implicitHeight: row.image ? 60 : Math.max(38, label.implicitHeight + 18)
                    radius: Theme.radius
                    color: row.current ? Theme.selRaised : ma.containsMouse ? Theme.hoverRaised : "transparent"

                    MouseArea {
                        id: ma

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = row.index
                        onClicked: root.pick(row.modelData)
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 6
                        }
                        spacing: 10

                        Rectangle {
                            visible: row.image
                            Layout.preferredWidth: 72
                            Layout.preferredHeight: 44
                            radius: Theme.radius
                            color: Theme.ground
                            border.width: 1
                            border.color: Theme.edge
                            clip: true

                            Image {
                                anchors.fill: parent
                                anchors.margins: 1
                                source: row.image ? `file://${row.modelData.thumb}` : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                sourceSize.width: 144
                                sourceSize.height: 88
                            }
                        }

                        BarText {
                            id: label

                            Layout.fillWidth: true
                            text: row.image ? `Görsel  ·  ${row.modelData.ext.toUpperCase()}${row.modelData.dims ? "  ·  " + row.modelData.dims.replace("x", "×") : ""}  ·  ${row.modelData.size}` : row.modelData.text
                            textFormat: Text.PlainText
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            font.pixelSize: row.image ? root.fs - 3 : root.fs - 2
                            weight: row.image ? root.wt : 500
                            color: row.current || ma.containsMouse ? Theme.bright : row.image ? Theme.dim : Theme.text
                        }

                        BarText {
                            visible: !(row.current || ma.containsMouse) && text !== ""
                            text: root.ago(row.modelData.at)
                            font.pixelSize: root.fs - 4
                            weight: root.wt
                            color: Theme.dim
                        }

                        Rectangle {
                            visible: row.current || ma.containsMouse
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            radius: Theme.radius
                            color: del.containsMouse ? Qt.alpha(Theme.hot, 0.16) : "transparent"

                            BarText {
                                anchors.centerIn: parent
                                text: Glyph.close
                                font.pixelSize: 13
                                color: del.containsMouse ? Theme.hot : Theme.dim
                            }

                            MouseArea {
                                id: del

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ClipData.remove(row.modelData.id)
                            }
                        }
                    }
                }
            }
        }

        Caption {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 2
            text: root.settings ? "AYARLAR HEMEN UYGULANIR" : "ENTER KOPYALAR  ·  SHIFT+DEL SİLER  ·  ESC KAPATIR"
        }
    }
}
