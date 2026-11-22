import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

Popup {
    id: root

    readonly property var ts: TailscaleData
    readonly property string stateText: ts.running ? (ts.tailnet || "Bağlı") : ts.needsLogin ? "Giriş gerekli" : ts.state === "Stopped" ? "Bağlantı kapalı" : ts.state === "Starting" ? "Bağlanıyor…" : "Servis çalışmıyor"

    contentWidth: 340
    contentHeight: body.implicitHeight + 2 * Theme.pad + 4

    onVisibleChanged: TailscaleData.watching = visible
    Component.onCompleted: TailscaleData.watching = visible
    Component.onDestruction: TailscaleData.watching = false

    component Heading: RowLayout {
        id: heading

        required property string title
        property string extra: ""

        Layout.fillWidth: true
        Layout.topMargin: 2

        BarText {
            text: heading.title
            font.pixelSize: Theme.small - 1
            font.weight: Font.Medium
            font.letterSpacing: 0.4
            color: Theme.dim
        }

        Item {
            Layout.fillWidth: true
        }

        BarText {
            visible: heading.extra !== ""
            text: heading.extra
            font.pixelSize: Theme.small - 1
            color: Theme.dim
        }
    }

    component Info: RowLayout {
        id: info

        required property string label
        required property string value

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
                enabled: info.value !== ""
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: TailscaleData.copy(info.value)
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
            leftMargin: Theme.pad + 4
            rightMargin: Theme.pad + 4
        }
        spacing: 9

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            TailscaleIcon {
                dot: 5
                lit: root.ts.running
                color: root.ts.running ? Theme.bright : Theme.dim
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                BarText {
                    text: "Tailscale"
                    font.weight: Font.Medium
                    color: Theme.bright
                }

                BarText {
                    Layout.fillWidth: true
                    text: root.stateText
                    elide: Text.ElideRight
                    font.pixelSize: Theme.small
                    color: Theme.dim
                }
            }

            Rectangle {
                id: toggle

                readonly property bool on: root.ts.running

                implicitWidth: 40
                implicitHeight: 22
                radius: height / 2
                opacity: root.ts.busy ? 0.5 : 1
                color: on ? Theme.text : "transparent"
                border.width: 1
                border.color: on ? Theme.text : Theme.edge

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.anim
                    }
                }

                Rectangle {
                    x: toggle.on ? toggle.width - width - 4 : 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    radius: 7
                    color: toggle.on ? Theme.ground : Theme.dim

                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.anim
                            easing.type: Theme.ease
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !root.ts.busy
                    onClicked: TailscaleData.setUp(!toggle.on)
                }
            }
        }

        Pick {
            visible: root.ts.needsLogin
            label: "Giriş yap"
            suffix: "tarayıcıda açılır"
            onClicked: TailscaleData.login()
        }

        ColumnLayout {
            visible: root.ts.running
            Layout.fillWidth: true
            spacing: 5

            Info {
                label: "Bu cihaz"
                value: root.ts.self.name ?? ""
            }

            Info {
                label: "IPv4"
                value: root.ts.self.ip4 ?? ""
            }

            Info {
                label: "MagicDNS"
                value: root.ts.self.dns ?? ""
            }
        }

        Rule {
            visible: root.ts.running
        }

        Heading {
            visible: root.ts.running
            title: "CİHAZLAR"
            extra: `${root.ts.onlineCount} / ${root.ts.peers.length} çevrimiçi`
        }

        BarText {
            visible: root.ts.running && root.ts.peers.length === 0
            text: "Bu tailnet'te başka cihaz yok"
            font.pixelSize: Theme.small
            color: Theme.dim
        }

        Flickable {
            visible: root.ts.running && root.ts.peers.length > 0
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
                        implicitHeight: 38
                        radius: Theme.radius
                        color: peerMa.containsMouse ? Theme.hoverRaised : "transparent"

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 8
                                rightMargin: 8
                            }
                            spacing: 9

                            Dot {
                                color: peer.modelData.online ? Theme.green : Theme.rule
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    BarText {
                                        Layout.fillWidth: true
                                        text: peer.modelData.name
                                        elide: Text.ElideRight
                                        font.pixelSize: Theme.small + 1
                                        color: peer.modelData.online ? Theme.bright : Theme.dim
                                    }

                                    BarText {
                                        visible: peer.modelData.exitActive
                                        text: "çıkış"
                                        font.pixelSize: Theme.small - 1
                                        color: Theme.warm
                                    }

                                    BarText {
                                        text: peerMa.containsMouse ? "kopyala" : peer.modelData.ip4
                                        font.pixelSize: Theme.small
                                        color: peerMa.containsMouse ? Theme.bright : Theme.dim
                                    }
                                }

                                BarText {
                                    Layout.fillWidth: true
                                    text: [peer.modelData.os, peer.modelData.online ? (peer.modelData.active ? (peer.modelData.direct ? "doğrudan" : peer.modelData.relay ? `relay · ${peer.modelData.relay}` : "") : "") : (peer.modelData.seen ? `son görülme ${peer.modelData.seen}` : "çevrimdışı")].filter(s => s).join("  ·  ")
                                    elide: Text.ElideRight
                                    font.pixelSize: Theme.small - 1
                                    color: Theme.dim
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

        Heading {
            visible: root.ts.running && root.ts.exitNodes.length > 0
            title: "ÇIKIŞ DÜĞÜMÜ"
            extra: root.ts.exitNode ? "trafik bu cihazdan çıkıyor" : ""
        }

        Flow {
            visible: root.ts.running && root.ts.exitNodes.length > 0
            Layout.fillWidth: true
            spacing: 4

            Pick {
                width: implicitWidth
                implicitWidth: 74
                label: "Kapalı"
                align: Text.AlignHCenter
                current: root.ts.exitNode === ""
                onClicked: if (!current)
                    TailscaleData.useExit("")
            }

            Repeater {
                model: root.ts.exitNodes

                Pick {
                    required property var modelData

                    width: implicitWidth
                    implicitWidth: Math.max(74, exitLabel.implicitWidth + 22)
                    label: modelData.name
                    align: Text.AlignHCenter
                    current: modelData.exitActive
                    selectable: modelData.online
                    opacity: modelData.online ? 1 : 0.45
                    onClicked: if (!current)
                        TailscaleData.useExit(modelData.ip4 || modelData.name)

                    TextMetrics {
                        id: exitLabel
                        font.pixelSize: Theme.small
                        text: modelData.name
                    }
                }
            }
        }

        Heading {
            visible: root.ts.running && root.ts.services.length > 0
            title: "SERVİSLER"
            extra: root.ts.probing ? "kontrol ediliyor…" : `${root.ts.servicesUp} / ${root.ts.services.length} yanıt veriyor`
        }

        Repeater {
            model: root.ts.running ? root.ts.services : []

            Rectangle {
                id: svc

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 30
                radius: Theme.radius
                color: svcMa.containsMouse ? Theme.hoverRaised : "transparent"

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 8
                    }
                    spacing: 9

                    Dot {
                        color: svc.modelData.code < 0 ? Theme.rule : svc.modelData.reachable ? Theme.green : Theme.hot
                    }

                    BarText {
                        text: svc.modelData.name
                        font.pixelSize: Theme.small + 1
                        color: Theme.bright
                    }

                    BarText {
                        Layout.fillWidth: true
                        text: svc.modelData.host
                        elide: Text.ElideRight
                        font.pixelSize: Theme.small - 1
                        color: Theme.dim
                    }

                    BarText {
                        text: svc.modelData.code < 0 ? "" : svc.modelData.reachable ? `${svc.modelData.ms} ms` : svc.modelData.code ? `HTTP ${svc.modelData.code}` : "yanıt yok"
                        font.pixelSize: Theme.small
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

        BarText {
            visible: root.ts.status !== ""
            Layout.fillWidth: true
            text: root.ts.status
            wrapMode: Text.Wrap
            font.pixelSize: Theme.small
            color: root.ts.statusError ? Theme.hot : Theme.dim
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 2
            spacing: 14

            Link {
                text: "Yönetim paneli"
                onClicked: {
                    Qt.openUrlExternally("https://login.tailscale.com/admin/machines");
                    Panels.popup = "";
                }
            }

            Link {
                visible: root.ts.running && root.ts.services.length > 0
                text: "Servisleri yenile"
                onClicked: TailscaleData.probe()
            }

            Item {
                Layout.fillWidth: true
            }

            Link {
                visible: root.ts.running
                text: "Çıkış yap"
                onClicked: TailscaleData.run(["logout"], "Oturum kapatıldı")
            }
        }
    }
}
