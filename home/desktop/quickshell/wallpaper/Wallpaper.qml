import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

Scope {
    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: win

            required property var modelData

            screen: modelData
            WlrLayershell.namespace: "can-wallpaper"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: WallState.current === WallState.black ? "#000000" : Theme.ground

            Behavior on color {
                ColorAnimation {
                    duration: 400
                }
            }

            property bool useA: true

            function show(): void {
                const src = WallState.current === WallState.black ? "" : `file://${WallState.dir}/${WallState.current}`;
                const next = win.useA ? b : a;
                if ((win.useA ? a : b).source.toString() === src)
                    return;
                next.source = src;
                win.useA = !win.useA;
            }

            Component.onCompleted: show()

            Connections {
                target: WallState
                function onCurrentChanged(): void {
                    win.show();
                }
            }

            component Layer: Image {
                required property bool front
                required property Image partner

                anchors.fill: parent
                sourceSize: Qt.size(win.width, win.height)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                smooth: true
                z: front ? 1 : 0
                opacity: front ? (status === Image.Ready ? 1 : 0) : (partner.source.toString() === "" || partner.opacity === 1 ? 0 : 1)

                Behavior on opacity {
                    NumberAnimation {
                        duration: 400
                    }
                }

                onOpacityChanged: if (!front && opacity === 0)
                    source = ""
            }

            Layer {
                id: a
                front: win.useA
                partner: b
            }

            Layer {
                id: b
                front: !win.useA
                partner: a
            }
        }
    }
}
