import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.common

Popup {
    id: root

    readonly property int fs: Theme.menuSize
    readonly property int wt: Theme.menuWeight

    readonly property var ts: TailscaleData
    property bool taildrop: false
    readonly property string stateText: ts.running ? (ts.tailnet || "Bağlı") : ts.needsLogin ? "Giriş gerekli" : ts.state === "Stopped" ? "Bağlantı kapalı" : ts.state === "Starting" ? "Bağlanıyor…" : "Servis çalışmıyor"

    contentWidth: 360
    contentHeight: body.implicitHeight + 2 * Theme.pad + 4

    FileView {
        path: "/etc/ecu/taildrop.json"
        printErrors: false
        onLoaded: {
            try {
                root.taildrop = JSON.parse(text()).enable === true;
            } catch (e) {
                root.taildrop = false;
            }
        }
    }

    onVisibleChanged: TailscaleData.watching = visible
    Component.onCompleted: TailscaleData.watching = visible
    Component.onDestruction: TailscaleData.watching = false

    component Header: RowLayout {
        id: header

        required property string title
        property string extra: ""
        property color extraTone: Theme.dim

        Layout.fillWidth: true
        Layout.bottomMargin: 2

        Caption {
            Layout.fillWidth: true
            text: header.title
        }

        Tag {
            visible: header.extra !== ""
            implicitHeight: 20
            text: header.extra
            tone: header.extraTone
        }
    }

    component Dot: Rectangle {
        implicitWidth: 7
        implicitHeight: 7
        radius: 3.5
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
                    glyph: ""
                    lit: root.ts.running

                    TailscaleIcon {
                        anchors.centerIn: parent
                        dot: 4.2
                        lit: root.ts.running
                        color: root.ts.running ? Theme.bright : Theme.dim
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Caption {
                        text: "TAILSCALE"
                    }

                    BarText {
                        Layout.fillWidth: true
                        text: root.stateText
                        elide: Text.ElideRight
                        font.pixelSize: root.fs - 1
                        weight: 600
                        color: root.ts.running ? Theme.bright : Theme.dim
                    }
                }

                Toggle {
                    on: root.ts.running
                    opacity: root.ts.busy ? 0.5 : 1
                    enabled: !root.ts.busy
                    onToggled: TailscaleData.setUp(!root.ts.running)
                }
            }

            ActionButton {
                visible: root.ts.needsLogin
                text: "Giriş yap  ·  tarayıcıda açılır"
                primary: true
                onClicked: TailscaleData.login()
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.ts.running
                spacing: 0

                Rule {
                    Layout.bottomMargin: 6
                }

                Value {
                    label: "Bu cihaz"
                    value: root.ts.self.name ?? ""
                    copier: TailscaleData.copy
                }

                Value {
                    label: "IPv4"
                    value: root.ts.self.ip4 ?? ""
                    copier: TailscaleData.copy
                }

                Value {
                    label: "MagicDNS"
                    value: root.ts.self.dns ?? ""
                    copier: TailscaleData.copy
                }
            }
        }

        Card {
            visible: root.ts.running
            padding: 10
            spacing: 2

            Header {
                title: "CİHAZLAR"
                extra: `${root.ts.onlineCount} / ${root.ts.peers.length} çevrimiçi`
                extraTone: root.ts.onlineCount > 0 ? Theme.green : Theme.dim
            }

            BarText {
                visible: root.ts.peers.length === 0
                Layout.leftMargin: 2
                text: "Bu tailnet'te başka cihaz yok"
                font.pixelSize: root.fs - 3
                weight: root.wt
                color: Theme.dim
            }

            Flickable {
                visible: root.ts.peers.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(peerList.implicitHeight, 236)
                contentHeight: peerList.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: peerList

                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.ts.peers

                        Rectangle {
                            id: peer

                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: Theme.radius
                            color: peerMa.containsMouse ? Theme.hoverRaised : "transparent"

                            RowLayout {
                                z: 1
                                anchors {
                                    fill: parent
                                    leftMargin: 8
                                    rightMargin: 8
                                }
                                spacing: 10

                                Dot {
                                    color: peer.modelData.online ? Theme.green : Theme.rule
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        BarText {
                                            Layout.fillWidth: true
                                            text: peer.modelData.name
                                            elide: Text.ElideRight
                                            font.pixelSize: root.fs - 2
                                            weight: peer.modelData.online ? 600 : root.wt
                                            color: peer.modelData.online ? Theme.bright : Theme.dim
                                        }

                                        Tag {
                                            visible: peer.modelData.exitActive
                                            implicitHeight: 18
                                            text: "exit node"
                                            tone: Theme.warm
                                            accent: true
                                        }

                                        BarText {
                                            text: peerMa.containsMouse ? "kopyala" : peer.modelData.ip4
                                            font.family: peerMa.containsMouse ? Theme.family : "JetBrainsMono Nerd Font"
                                            font.pixelSize: root.fs - 4
                                            color: peerMa.containsMouse ? Theme.bright : Theme.dim
                                        }
                                    }

                                    BarText {
                                        Layout.fillWidth: true
                                        text: [peer.modelData.os, peer.modelData.online ? (peer.modelData.active ? (peer.modelData.direct ? "doğrudan" : peer.modelData.relay ? `relay · ${peer.modelData.relay}` : "") : "") : (peer.modelData.seen ? `son görülme ${peer.modelData.seen}` : "çevrimdışı")].filter(s => s).join("  ·  ")
                                        elide: Text.ElideRight
                                        font.pixelSize: root.fs - 4
                                        weight: root.wt
                                        color: Theme.dim
                                    }
                                }

                                Tile {
                                    visible: root.taildrop && peer.modelData.mine
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    glyphSize: 14
                                    glyph: String.fromCodePoint(0xF048A)
                                    lit: false
                                    tone: peer.modelData.online ? Theme.text : Theme.dim
                                    border.color: "transparent"
                                    clickable: true
                                    onClicked: {
                                        Panels.popup = "";
                                        Quickshell.execDetached(["ecu-taildrop", "send", peer.modelData.name]);
                                    }
                                }
                            }

                            MouseArea {
                                id: peerMa

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: TailscaleData.copy(peer.modelData.ip4)
                            }
                        }
                    }
                }
            }
        }

        Card {
            visible: root.ts.running && root.ts.exitNodes.length > 0
            padding: 10
            spacing: 8

            Header {
                title: "EXIT NODE"
                extra: root.ts.exitNode ? "trafik dışarı çıkıyor" : ""
                extraTone: Theme.warm
            }

            Segments {
                options: [
                    {
                        name: "Kapalı",
                        ip4: "",
                        online: true,
                        off: true
                    }
                ].concat(root.ts.exitNodes)
                selected: o => o.off ? root.ts.exitNode === "" : o.exitActive === true
                onPicked: o => {
                    if (!o.online || selected(o))
                        return;
                    TailscaleData.useExit(o.off ? "" : (o.ip4 || o.name));
                }
            }
        }

        Card {
            visible: root.ts.running && root.ts.services.length > 0
            padding: 10
            spacing: 2

            Header {
                title: "SERVİSLER"
                extra: root.ts.probing ? "kontrol ediliyor…" : `${root.ts.servicesUp} / ${root.ts.services.length} yanıt veriyor`
                extraTone: root.ts.probing ? Theme.dim : root.ts.servicesUp === root.ts.services.length ? Theme.green : Theme.hot
            }

            Repeater {
                model: root.ts.services

                Rectangle {
                    id: svc

                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: Theme.radius
                    color: svcMa.containsMouse ? Theme.hoverRaised : "transparent"

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 8
                        }
                        spacing: 10

                        Dot {
                            color: svc.modelData.code < 0 ? Theme.rule : svc.modelData.reachable ? Theme.green : Theme.hot
                        }

                        BarText {
                            text: svc.modelData.name
                            font.pixelSize: root.fs - 2
                            weight: 600
                            color: Theme.bright
                        }

                        BarText {
                            Layout.fillWidth: true
                            text: svc.modelData.host
                            elide: Text.ElideRight
                            font.pixelSize: root.fs - 4
                            weight: root.wt
                            color: Theme.dim
                        }

                        BarText {
                            text: svc.modelData.code < 0 ? "" : svc.modelData.reachable ? `${svc.modelData.ms} ms` : svc.modelData.code ? `HTTP ${svc.modelData.code}` : "yanıt yok"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: root.fs - 4
                            color: svc.modelData.reachable ? Theme.dim : Theme.hot
                        }
                    }

                    MouseArea {
                        id: svcMa

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(svc.modelData.url)
                    }
                }
            }
        }

        BarText {
            visible: root.ts.status !== ""
            Layout.fillWidth: true
            Layout.leftMargin: 2
            text: root.ts.status
            wrapMode: Text.Wrap
            font.pixelSize: root.fs - 3
            weight: root.wt
            color: root.ts.statusError ? Theme.hot : Theme.dim
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Tag {
                text: `Yönetim paneli  ${Glyph.chevronRight}`
                tone: Theme.text
                clickable: true
                onClicked: {
                    Qt.openUrlExternally("https://login.tailscale.com/admin/machines");
                    Panels.popup = "";
                }
            }

            Tag {
                visible: root.ts.running && root.ts.services.length > 0
                text: "Servisleri yenile"
                tone: Theme.text
                clickable: true
                onClicked: TailscaleData.probe()
            }

            Item {
                Layout.fillWidth: true
            }

            Tag {
                visible: root.ts.running
                text: "Çıkış yap"
                tone: Theme.hot
                accent: true
                clickable: true
                onClicked: TailscaleData.run(["logout"], "Oturum kapatıldı")
            }
        }
    }
}
