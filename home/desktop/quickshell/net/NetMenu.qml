import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.common

Popup {
    id: root

    readonly property int fs: Theme.menuSize
    readonly property int wt: Theme.menuWeight

    property string page: "main"
    property bool renaming: false
    property string askingFor: ""
    property bool showMac: false

    property string formUuid: ""
    property bool formManual: false

    readonly property var link: NetData.link
    readonly property bool online: root.link.state?.startsWith("100") ?? false
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetworks: wifiDevice ? wifiDevice.networks.values.filter(n => n.name).sort((a, b) => b.connected - a.connected || b.known - a.known || b.signalStrength - a.signalStrength).slice(0, 6) : []

    function typeName(t: string): string {
        return t === "wifi" ? "Wi-Fi" : t === "ethernet" ? "Ethernet" : t || "—";
    }

    function speedName(mbit: string): string {
        const n = Number(mbit);
        if (!n || n < 0)
            return "";
        return n >= 1000 ? `${n / 1000} Gb/s` : `${n} Mb/s`;
    }

    function openIpPage(): void {
        NetData.loadConnections();
        root.loadForm(root.link.uuid ?? (NetData.connections[0]?.uuid ?? ""));
        root.page = "ip";
    }

    function loadForm(uuid: string): void {
        root.formUuid = uuid;
        formReader.command = ["nmcli", "-t", "-g", "ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns", "connection", "show", uuid];
        formReader.running = true;
    }

    alignRight: true
    contentWidth: 360
    contentHeight: (page === "main" ? main.implicitHeight : ipPage.implicitHeight) + 2 * Theme.pad + 4

    onVisibleChanged: NetData.watching = visible
    Component.onCompleted: NetData.watching = visible
    Component.onDestruction: NetData.watching = false

    Process {
        id: formReader

        stdout: StdioCollector {
            onStreamFinished: {
                const [method, address, gateway, dns] = text.split("\n");
                root.formManual = method === "manual";
                addressField.text = address ?? "";
                gatewayField.text = gateway ?? "";
                dnsField.text = dns ?? "";
            }
        }
    }

    component Stat: ColumnLayout {
        id: stat

        required property string caption
        required property string glyph
        required property real rate
        required property real total

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        spacing: 3

        Caption {
            text: stat.caption
        }

        BarText {
            text: `${stat.glyph} ${NetData.human(stat.rate, true)}`
            font.pixelSize: 18
            weight: 350
            color: Theme.bright
        }

        BarText {
            text: `toplam ${NetData.human(stat.total, false)}`
            font.pixelSize: root.fs - 4
            weight: root.wt
            color: Theme.dim
        }
    }

    ColumnLayout {
        id: main

        visible: root.page === "main"
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
                    glyph: root.link.type === "wifi" ? Glyph.wifi[4] : Glyph.wired
                    lit: root.online
                    tone: root.online ? Theme.bright : Theme.dim
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Caption {
                        Layout.fillWidth: true
                        text: [root.typeName(root.link.type), root.speedName(root.link.speed), root.link.device].filter(s => s).join("  ·  ").toLocaleUpperCase("tr-TR")
                        elide: Text.ElideRight
                    }

                    BarText {
                        visible: !root.renaming
                        Layout.fillWidth: true
                        text: root.link.name || "Bağlantı yok"
                        elide: Text.ElideRight
                        font.pixelSize: root.fs - 1
                        weight: 600
                        color: Theme.bright
                    }

                    Field {
                        id: renameField
                        visible: root.renaming
                        onAccepted: {
                            NetData.rename(text);
                            root.renaming = false;
                        }
                        input.Keys.onEscapePressed: root.renaming = false
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: 4

                    Tag {
                        Layout.alignment: Qt.AlignRight
                        implicitHeight: 20
                        text: root.online ? "Bağlı" : "Bağlantı yok"
                        dot: true
                        accent: true
                        tone: root.online ? Theme.green : Theme.hot
                    }

                    Tile {
                        Layout.alignment: Qt.AlignRight
                        visible: !!root.link.uuid
                        implicitWidth: 30
                        implicitHeight: 30
                        glyphSize: root.renaming ? 14 : 15
                        glyph: root.renaming ? Glyph.close : Glyph.pencil
                        lit: false
                        tone: Theme.dim
                        border.color: "transparent"
                        clickable: true
                        onClicked: {
                            root.renaming = !root.renaming;
                            if (root.renaming) {
                                renameField.text = root.link.name;
                                renameField.input.forceActiveFocus();
                                renameField.input.selectAll();
                            }
                        }
                    }
                }
            }

            Rule {}

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Stat {
                    caption: "İNDİRME"
                    glyph: Glyph.down
                    rate: NetData.rxRate
                    total: NetData.rxTotal
                }

                Rectangle {
                    Layout.fillHeight: true
                    implicitWidth: 1
                    color: Theme.edge
                }

                Stat {
                    caption: "YÜKLEME"
                    glyph: Glyph.up
                    rate: NetData.txRate
                    total: NetData.txTotal
                }
            }
        }

        Card {
            spacing: 0
            padding: 10

            Caption {
                Layout.bottomMargin: 4
                text: "ADRESLER"
            }

            Value {
                label: "IP adresi"
                value: root.link.ip ?? ""
                copier: NetData.copy
            }
            Value {
                label: "Ağ geçidi"
                value: root.link.gateway ?? ""
                copier: NetData.copy
            }
            Value {
                label: "DNS"
                value: root.link.dns ?? ""
                copier: NetData.copy
            }
            Value {
                label: "MAC"
                value: root.showMac ? (root.link.mac || "—") : "••:••:••:••:••:••"
                copier: NetData.copy
                copyable: root.showMac
                action: root.showMac ? "gizle" : "göster"
                onActed: root.showMac = !root.showMac
            }
            Value {
                label: "Adres alma · MTU"
                value: `${root.link.method === "manual" ? "Elle" : "DHCP"} · ${root.link.mtu ?? "—"}`
            }
            Value {
                label: "Genel IP"
                value: NetData.publicIpBusy ? "soruluyor…" : NetData.publicIp
                copier: NetData.copy
                copyable: /^[\d.]+$/.test(NetData.publicIp)
                action: NetData.publicIp ? "yenile" : "göster"
                onActed: NetData.lookupPublicIp()
            }
            Value {
                label: "Ping"
                value: NetData.pingBusy ? "ölçülüyor…" : NetData.ping
                action: NetData.ping ? "yenile" : "ölç"
                onActed: NetData.measurePing()
            }
        }

        Card {
            padding: 10
            spacing: 8

            Caption {
                text: "DNS SUNUCUSU"
            }

            Segments {
                options: NetData.dnsPresets
                selected: o => NetData.dnsPreset === o.name
                onPicked: o => NetData.setDns(o.servers)
            }
        }

        Card {
            visible: !!root.wifiDevice
            padding: 10
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                spacing: 10

                BarText {
                    text: Networking.wifiEnabled ? Glyph.wifi[4] : Glyph.wifiOff
                    font.pixelSize: root.fs + 2
                    color: Networking.wifiEnabled ? Theme.bright : Theme.dim
                }

                BarText {
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                    font.pixelSize: root.fs - 1
                    weight: 600
                    color: Networking.wifiEnabled ? Theme.text : Theme.dim
                }

                Toggle {
                    on: Networking.wifiEnabled
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            BarText {
                visible: Networking.wifiEnabled && root.wifiNetworks.length === 0
                Layout.leftMargin: 2
                text: "Ağ aranıyor…"
                font.pixelSize: root.fs - 3
                weight: root.wt
                color: Theme.dim
            }

            Repeater {
                model: Networking.wifiEnabled ? root.wifiNetworks : []

                delegate: ColumnLayout {
                    id: net

                    required property var modelData
                    readonly property bool open: modelData.security === WifiSecurityType.Open || modelData.security === WifiSecurityType.Owe

                    Layout.fillWidth: true
                    spacing: 4

                    Connections {
                        target: net.modelData

                        function onConnectedChanged(): void {
                            NetData.refresh();
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: Theme.radius
                        color: net.modelData.connected ? Theme.sel : netMa.containsMouse ? Theme.hoverRaised : "transparent"

                        BarText {
                            id: netSignal
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: Glyph.wifi[Math.min(4, Math.floor(net.modelData.signalStrength * 5))]
                            font.pixelSize: root.fs
                            color: net.modelData.connected ? Theme.bright : Theme.text
                        }

                        BarText {
                            anchors.left: netSignal.right
                            anchors.leftMargin: 10
                            anchors.right: netState.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: net.modelData.name
                            elide: Text.ElideRight
                            font.pixelSize: root.fs - 2
                            weight: net.modelData.connected ? 650 : root.wt
                            color: net.modelData.connected ? Theme.bright : Theme.text
                        }

                        BarText {
                            id: netState
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: net.modelData.stateChanging ? "···" : net.modelData.connected ? (netMa.containsMouse ? "kes" : "bağlı") : net.open ? "" : Glyph.lock
                            font.pixelSize: root.fs - 3
                            weight: root.wt
                            color: net.modelData.connected && !netMa.containsMouse ? Theme.green : Theme.dim
                        }

                        MouseArea {
                            id: netMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (net.modelData.connected)
                                    net.modelData.disconnect();
                                else if (net.modelData.known || net.open)
                                    net.modelData.connect();
                                else {
                                    root.askingFor = root.askingFor === net.modelData.name ? "" : net.modelData.name;
                                    if (root.askingFor)
                                        psk.input.forceActiveFocus();
                                }
                            }
                        }
                    }

                    Field {
                        id: psk
                        visible: root.askingFor === net.modelData.name
                        secret: true
                        placeholder: "Şifre, Enter ile bağlan"
                        onAccepted: {
                            net.modelData.connectWithPsk(text);
                            text = "";
                            root.askingFor = "";
                        }
                        input.Keys.onEscapePressed: root.askingFor = ""
                    }
                }
            }
        }

        BarText {
            visible: NetData.status !== ""
            Layout.fillWidth: true
            text: NetData.status
            wrapMode: Text.Wrap
            font.pixelSize: root.fs - 3
            weight: root.wt
            color: NetData.statusError ? Theme.hot : Theme.text
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Tag {
                text: `IP ayarları  ${Glyph.chevronRight}`
                tone: Theme.text
                clickable: true
                onClicked: root.openIpPage()
            }

            Item {
                Layout.fillWidth: true
            }

            Tag {
                text: `Gelişmiş  ${Glyph.chevronRight}`
                tone: Theme.text
                clickable: true
                onClicked: {
                    Panels.popup = "";
                    Quickshell.execDetached(["nm-connection-editor"]);
                }
            }
        }
    }

    ColumnLayout {
        id: ipPage

        visible: root.page === "ip"
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: Theme.pad + 2
            leftMargin: Theme.pad + 2
            rightMargin: Theme.pad + 2
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 10

            Tag {
                text: `${Glyph.chevronLeft}  Ağ`
                tone: Theme.text
                clickable: true
                onClicked: root.page = "main"
            }

            BarText {
                Layout.fillWidth: true
                text: "IP ayarları"
                font.pixelSize: root.fs + 2
                weight: 680
                color: Theme.bright
            }
        }

        Card {
            padding: 10
            spacing: 4

            Caption {
                Layout.bottomMargin: 2
                text: "BAĞLANTI"
            }

            Repeater {
                model: NetData.connections

                delegate: Rectangle {
                    id: conn

                    required property var modelData
                    readonly property bool current: root.formUuid === modelData.uuid

                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: Theme.radius
                    color: connMa.containsMouse ? Theme.hoverRaised : "transparent"

                    Rectangle {
                        id: connDot
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12
                        height: 12
                        radius: 6
                        color: "transparent"
                        border.width: conn.current ? 4 : 1.5
                        border.color: conn.current ? Theme.bright : Theme.edge
                    }

                    BarText {
                        anchors.left: connDot.right
                        anchors.leftMargin: 10
                        anchors.right: connType.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: conn.modelData.name
                        elide: Text.ElideRight
                        font.pixelSize: root.fs - 2
                        weight: conn.current ? 600 : root.wt
                        color: conn.current ? Theme.bright : Theme.text
                    }

                    BarText {
                        id: connType
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: conn.modelData.type === "802-11-wireless" ? "Wi-Fi" : "Ethernet"
                        font.pixelSize: root.fs - 4
                        weight: root.wt
                        color: Theme.dim
                    }

                    MouseArea {
                        id: connMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.loadForm(conn.modelData.uuid)
                    }
                }
            }
        }

        Card {
            padding: 10
            spacing: 8

            Caption {
                text: "ADRES ALMA"
            }

            Segments {
                options: [
                    {
                        name: "Otomatik (DHCP)",
                        manual: false
                    },
                    {
                        name: "Elle",
                        manual: true
                    }
                ]
                selected: o => root.formManual === o.manual
                onPicked: o => root.formManual = o.manual
            }

            RowLayout {
                visible: root.formManual
                Layout.fillWidth: true
                Layout.topMargin: 2

                Caption {
                    Layout.fillWidth: true
                    text: "ADRES / ÖNEK"
                }

                Tag {
                    visible: root.formUuid === root.link.uuid
                    implicitHeight: 20
                    text: "şimdikini kullan"
                    tone: Theme.text
                    clickable: true
                    onClicked: {
                        addressField.text = (root.link.ip ?? "").split(" | ")[0];
                        gatewayField.text = root.link.gateway ?? "";
                        if (!dnsField.text)
                            dnsField.text = (root.link.dns ?? "").replace(/, /g, " ");
                    }
                }
            }

            Field {
                id: addressField
                visible: root.formManual
                implicitHeight: 30
                placeholder: "192.168.0.50/24"
            }

            Caption {
                visible: root.formManual
                Layout.topMargin: 2
                text: "AĞ GEÇİDİ"
            }

            Field {
                id: gatewayField
                visible: root.formManual
                implicitHeight: 30
                placeholder: "192.168.0.1"
            }

            Caption {
                Layout.topMargin: 2
                text: root.formManual ? "DNS" : "EK DNS (İSTEĞE BAĞLI)"
            }

            Field {
                id: dnsField
                implicitHeight: 30
                placeholder: "1.1.1.1 1.0.0.1"
            }
        }

        BarText {
            Layout.fillWidth: true
            text: NetData.status !== "" ? NetData.status : "Kaydedince bağlantı bir an kopup yeniden kurulur."
            wrapMode: Text.Wrap
            font.pixelSize: root.fs - 4
            weight: root.wt
            color: NetData.status !== "" ? (NetData.statusError ? Theme.hot : Theme.text) : Theme.dim
        }

        ActionButton {
            text: NetData.busy ? "kaydediliyor…" : "Kaydet"
            primary: true
            enabled: !NetData.busy && root.formUuid !== ""
            onClicked: NetData.saveIp(root.formUuid, root.formManual, addressField.text, gatewayField.text, dnsField.text)
        }
    }
}
