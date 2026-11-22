import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.common

Popup {
    id: root

    property string page: "main"
    property bool renaming: false
    property string askingFor: ""
    property bool showMac: false

    property string formUuid: ""
    property bool formManual: false

    readonly property var link: NetData.link
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
        root.loadForm(root.link.uuid ?? (NetData.connections[0]?.uuid ?? ""));
        root.page = "ip";
    }

    function loadForm(uuid: string): void {
        root.formUuid = uuid;
        formReader.command = ["nmcli", "-t", "-g", "ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns", "connection", "show", uuid];
        formReader.running = true;
    }

    alignRight: true
    contentWidth: 340
    contentHeight: (page === "main" ? main.implicitHeight : ipPage.implicitHeight) + 2 * Theme.pad + 4

    onVisibleChanged: {
        NetData.watching = visible;
        if (!visible) {
            root.page = "main";
            root.renaming = false;
            root.askingFor = "";
            root.showMac = false;
        }
    }
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

    component Info: RowLayout {
        id: info

        required property string label
        required property string value
        property bool copyable: false

        Layout.fillWidth: true
        spacing: 8

        BarText {
            text: info.label
            font.pixelSize: Theme.small
            color: Theme.dim
        }

        BarText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: info.value || "—"
            elide: Text.ElideLeft
            font.pixelSize: Theme.small
            color: infoMa.containsMouse ? Theme.bright : Theme.text

            MouseArea {
                id: infoMa
                anchors.fill: parent
                enabled: info.copyable && info.value !== ""
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NetData.copy(info.value)
            }
        }
    }

    component Link: BarText {
        id: link

        signal clicked

        font.pixelSize: Theme.small
        color: linkMa.containsMouse ? Theme.bright : Theme.dim

        MouseArea {
            id: linkMa
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: link.clicked()
        }
    }

    component Heading: BarText {
        font.pixelSize: Theme.small - 1
        font.weight: Font.Medium
        font.letterSpacing: 0.4
        color: Theme.dim
    }

    component Traffic: ColumnLayout {
        required property string glyph
        required property string label
        required property real rate
        required property real total

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.maximumWidth: Number.POSITIVE_INFINITY
        spacing: 1

        BarText {
            text: parent.label
            font.pixelSize: Theme.small - 1
            color: Theme.dim
        }

        BarText {
            text: `${parent.glyph} ${NetData.human(parent.rate, true)}`
            font.weight: Font.Medium
            font.wordSpacing: Theme.glyphGap
            color: Theme.bright
        }

        BarText {
            text: `toplam ${NetData.human(parent.total, false)}`
            font.pixelSize: Theme.small - 1
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
            leftMargin: Theme.pad + 4
            rightMargin: Theme.pad + 4
        }
        spacing: 9

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            BarText {
                text: root.link.type === "wifi" ? Glyph.wifi[4] : Glyph.wired
                font.pixelSize: 22
                color: root.link.state?.startsWith("100") ? Theme.bright : Theme.dim
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                BarText {
                    visible: !root.renaming
                    Layout.fillWidth: true
                    text: root.link.name || "Bağlantı yok"
                    elide: Text.ElideRight
                    font.weight: Font.Medium
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

                BarText {
                    Layout.fillWidth: true
                    text: [root.typeName(root.link.type), root.speedName(root.link.speed), root.link.device].filter(s => s).join(" · ")
                    elide: Text.ElideRight
                    font.pixelSize: Theme.small - 1
                    color: Theme.dim
                }
            }

            Link {
                visible: !!root.link.uuid
                text: root.renaming ? "vazgeç" : Glyph.pencil
                font.pixelSize: root.renaming ? Theme.small : Theme.size + 2
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

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Traffic {
                glyph: Glyph.down
                label: "İndirme"
                rate: NetData.rxRate
                total: NetData.rxTotal
            }
            Traffic {
                glyph: Glyph.up
                label: "Yükleme"
                rate: NetData.txRate
                total: NetData.txTotal
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Info {
                label: "IP adresi"
                value: root.link.ip ?? ""
                copyable: true
            }
            Info {
                label: "Ağ geçidi"
                value: root.link.gateway ?? ""
                copyable: true
            }
            Info {
                label: "DNS"
                value: root.link.dns ?? ""
                copyable: true
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                BarText {
                    text: "MAC"
                    font.pixelSize: Theme.small
                    color: Theme.dim
                }
                BarText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: root.showMac ? (root.link.mac || "—") : ""
                    font.pixelSize: Theme.small
                    color: macMa.containsMouse ? Theme.bright : Theme.text

                    MouseArea {
                        id: macMa
                        anchors.fill: parent
                        enabled: root.showMac && !!root.link.mac
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetData.copy(root.link.mac)
                    }
                }
                Link {
                    text: root.showMac ? "gizle" : "göster"
                    onClicked: root.showMac = !root.showMac
                }
            }
            Info {
                label: "Adres alma · MTU"
                value: `${root.link.method === "manual" ? "Elle" : "DHCP"} · ${root.link.mtu ?? "—"}`
            }
        }

        Rule {}

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            BarText {
                text: "Ping"
                font.pixelSize: Theme.small
                color: Theme.dim
            }
            BarText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: NetData.pingBusy ? "ölçülüyor…" : NetData.ping
                font.pixelSize: Theme.small
                color: Theme.text
            }
            Link {
                text: NetData.ping ? "yenile" : "ölç"
                onClicked: NetData.measurePing()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            BarText {
                text: "Genel IP"
                font.pixelSize: Theme.small
                color: Theme.dim
            }
            BarText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: NetData.publicIpBusy ? "soruluyor…" : NetData.publicIp
                font.pixelSize: Theme.small
                color: pubMa.containsMouse ? Theme.bright : Theme.text

                MouseArea {
                    id: pubMa
                    anchors.fill: parent
                    enabled: /^[\d.]+$/.test(NetData.publicIp)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NetData.copy(NetData.publicIp)
                }
            }
            Link {
                text: NetData.publicIp ? "yenile" : "göster"
                onClicked: NetData.lookupPublicIp()
            }
        }

        Rule {}

        Heading {
            text: "DNS SUNUCUSU"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: NetData.dnsPresets

                delegate: Pick {
                    required property var modelData

                    Layout.preferredWidth: 1
                    label: modelData.name
                    align: Text.AlignHCenter
                    current: NetData.dnsPreset === modelData.name
                    onClicked: NetData.setDns(modelData.servers)
                }
            }
        }

        Rule {
            visible: !!root.wifiDevice
        }

        RowLayout {
            visible: !!root.wifiDevice
            Layout.fillWidth: true
            spacing: 8

            Heading {
                Layout.fillWidth: true
                text: "WI-FI"
            }

            Pick {
                Layout.fillWidth: false
                implicitWidth: 64
                label: Networking.wifiEnabled ? "açık" : "kapalı"
                align: Text.AlignHCenter
                current: Networking.wifiEnabled
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }

        BarText {
            visible: !!root.wifiDevice && Networking.wifiEnabled && root.wifiNetworks.length === 0
            text: "Ağ aranıyor…"
            font.pixelSize: Theme.small
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

                Pick {
                    label: `${Glyph.wifi[Math.min(4, Math.floor(net.modelData.signalStrength * 5))]}  ${net.modelData.name}`
                    suffix: net.modelData.stateChanging ? "···" : net.modelData.connected ? "bağlı · kes" : net.open ? "" : Glyph.padlock
                    current: net.modelData.connected
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

        Rule {}

        BarText {
            visible: NetData.status !== ""
            Layout.fillWidth: true
            text: NetData.status
            wrapMode: Text.Wrap
            font.pixelSize: Theme.small
            color: NetData.statusError ? Theme.hot : Theme.text
        }

        RowLayout {
            Layout.fillWidth: true

            Link {
                text: `IP ayarları ${Glyph.chevronRight}`
                onClicked: root.openIpPage()
            }
            Item {
                Layout.fillWidth: true
            }
            Link {
                text: `Gelişmiş ${Glyph.chevronRight}`
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
            leftMargin: Theme.pad + 4
            rightMargin: Theme.pad + 4
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Link {
                text: `${Glyph.chevronLeft} Ağ`
                onClicked: root.page = "main"
            }
            Item {
                Layout.fillWidth: true
            }
            BarText {
                text: "IP ayarları"
                font.weight: Font.Medium
                color: Theme.bright
            }
        }

        Heading {
            Layout.topMargin: 2
            text: "BAĞLANTI"
        }

        Repeater {
            model: NetData.connections

            delegate: Pick {
                required property var modelData

                label: modelData.name
                suffix: modelData.type === "802-11-wireless" ? "Wi-Fi" : "Ethernet"
                current: root.formUuid === modelData.uuid
                onClicked: root.loadForm(modelData.uuid)
            }
        }

        Heading {
            Layout.topMargin: 2
            text: "ADRES ALMA"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Pick {
                Layout.preferredWidth: 1
                label: "Otomatik (DHCP)"
                align: Text.AlignHCenter
                current: !root.formManual
                onClicked: root.formManual = false
            }
            Pick {
                Layout.preferredWidth: 1
                label: "Elle"
                align: Text.AlignHCenter
                current: root.formManual
                onClicked: root.formManual = true
            }
        }

        RowLayout {
            visible: root.formManual
            Layout.fillWidth: true

            Heading {
                Layout.fillWidth: true
                text: "ADRES / ÖNEK"
            }
            Link {
                visible: root.formUuid === root.link.uuid
                text: "şimdikini kullan"
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
            placeholder: "192.168.0.50/24"
        }

        Heading {
            visible: root.formManual
            text: "AĞ GEÇİDİ"
        }

        Field {
            id: gatewayField
            visible: root.formManual
            placeholder: "192.168.0.1"
        }

        Heading {
            text: root.formManual ? "DNS" : "EK DNS (İSTEĞE BAĞLI)"
        }

        Field {
            id: dnsField
            placeholder: "1.1.1.1 1.0.0.1"
        }

        BarText {
            Layout.fillWidth: true
            Layout.topMargin: 2
            visible: NetData.status === ""
            text: "Kaydedince bağlantı bir an kopup yeniden kurulur."
            wrapMode: Text.Wrap
            font.pixelSize: Theme.small - 1
            color: Theme.dim
        }

        BarText {
            visible: NetData.status !== ""
            Layout.fillWidth: true
            text: NetData.status
            wrapMode: Text.Wrap
            font.pixelSize: Theme.small
            color: NetData.statusError ? Theme.hot : Theme.text
        }

        Pick {
            label: NetData.busy ? "kaydediliyor…" : "Kaydet"
            align: Text.AlignHCenter
            selectable: !NetData.busy && root.formUuid !== ""
            onClicked: NetData.saveIp(root.formUuid, root.formManual, addressField.text, gatewayField.text, dnsField.text)
        }
    }
}
