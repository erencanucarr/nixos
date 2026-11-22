import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// The wallpaper on every screen: WallState's choice, picked with
// Super+Shift+W (Picker). Decoded at the screen's size, not the photo's,
// so each screen costs about 8 MB however large the file. A new choice
// fades in over the old one.
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

            // Two images taking turns, so the old one stays until the new
            // one is decoded and has faded in over it.
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
                // In front: in once decoded. Behind: out once the front one
                // is fully in, or at once when the front is plain black.
                opacity: front ? (status === Image.Ready ? 1 : 0) : (partner.source.toString() === "" || partner.opacity === 1 ? 0 : 1)

                Behavior on opacity {
                    NumberAnimation {
                        duration: 400
                    }
                }

                // The one behind lets go of its picture once hidden.
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
