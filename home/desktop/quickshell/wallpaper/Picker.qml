import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland
import qs.common

// The wallpaper picker, after xeome's Walls.qml: Super+Shift+W (qs ipc call
// walls toggle). Plain black and every image in ~/nixos/home/desktop/
// wallpapers as slanted slices, the focused one wide. Arrows or the wheel
// browse, Enter or a click on the wide one applies (WallState), Esc or a
// click above or below closes. xeome's "dots" bakes are left out, and the
// applying is ours (Wallpaper.qml) rather than waypaper and swaybg.
// Built while open only (shell.qml).
PanelWindow {
    id: root

    // "siyah" first, then the files by name.
    property var choices: [WallState.black]

    // The slice geometry, from the screen: tall slices, the focused one
    // wide, each leaning right by `lean` across its height.
    readonly property real sliceH: Math.round(height * 0.55)
    readonly property real wideW: Math.round(width * 0.42)
    readonly property real narrowW: Math.round(width * 0.05)
    readonly property real lean: Math.round(sliceH * 0.12)

    function apply(): void {
        const name = root.choices[list.currentIndex];
        if (name)
            WallState.set(name);
        Panels.wallsOpen = false;
    }

    function label(name: string): string {
        return name === WallState.black ? "Siyah" : name.replace(/\.[^.]*$/, "").replace(/[-_]+/g, " ");
    }

    screen: Quickshell.screens.find(s => s.name === Panels.wallsScreen) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "can-walls"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "#d9000000"

    FolderListModel {
        id: files

        folder: `file://${WallState.dir}`
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]
        showDirs: false
        onStatusChanged: if (status === FolderListModel.Ready)
            root.fill()
        onCountChanged: root.fill()
    }

    function fill(): void {
        const out = [WallState.black];
        for (let i = 0; i < files.count; i++)
            out.push(files.get(i, "fileName"));
        root.choices = out;
        list.currentIndex = Math.max(0, out.indexOf(WallState.current));
        Qt.callLater(list.recenter);
    }

    MouseArea {
        // One slice per notch (120): a touchpad sends many small deltas.
        property real travel: 0

        anchors.fill: parent
        onClicked: mouse => {
            if (mouse.y < list.y || mouse.y > list.y + list.height)
                Panels.wallsOpen = false;
        }
        onWheel: wheel => {
            travel += wheel.angleDelta.y || wheel.angleDelta.x;
            for (; travel >= 120; travel -= 120)
                list.decrementCurrentIndex();
            for (; travel <= -120; travel += 120)
                list.incrementCurrentIndex();
        }
    }

    ListView {
        id: list

        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -Math.round(root.height * 0.04)
        width: parent.width
        height: root.sliceH
        orientation: ListView.Horizontal
        model: root.choices
        // Room at both ends, so the first and last can sit in the middle
        // too (with few wallpapers the strip would otherwise hug an edge).
        leftMargin: (width - root.wideW) / 2
        rightMargin: (width - root.wideW) / 2
        // Neighbours' slanted edges are parallel, so the gap is even.
        spacing: 10
        interactive: false
        focus: true
        keyNavigationEnabled: true
        onCurrentIndexChanged: Qt.callLater(list.recenter)

        // The focused slice in the middle, redone as widths animate, since
        // the one shrinking beside it moves it too.
        function recenter(): void {
            forceLayout();
            positionViewAtIndex(currentIndex, ListView.Center);
        }

        Component.onCompleted: forceActiveFocus()

        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape)
                Panels.wallsOpen = false;
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)
                root.apply();
            else
                return;
            e.accepted = true;
        }

        delegate: Item {
            id: slice

            required property string modelData
            required property int index
            readonly property bool current: ListView.isCurrentItem
            readonly property bool black: modelData === WallState.black

            width: current ? root.wideW : root.narrowW
            height: root.sliceH

            Behavior on width {
                NumberAnimation {
                    duration: Theme.anim
                    easing.type: Theme.ease
                }
            }

            onWidthChanged: Qt.callLater(list.recenter)

            // An upright Item sheared into a parallelogram and clipped there;
            // its picture is sheared back so it stays upright.
            Item {
                id: shape

                readonly property real k: root.lean / height

                width: parent.width
                height: parent.height
                clip: true
                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(1, -shape.k, 0, root.lean, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }

                Rectangle {
                    visible: slice.black
                    anchors.fill: parent
                    color: "#000000"
                }

                Image {
                    visible: !slice.black
                    width: slice.width + root.lean
                    height: slice.height
                    source: slice.black ? "" : `file://${WallState.dir}/${slice.modelData}`
                    sourceSize.height: root.sliceH
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    transform: Matrix4x4 {
                        matrix: Qt.matrix4x4(1, shape.k, 0, -root.lean, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: slice.current ? "transparent" : "#59000000"
                    border.width: 1
                    border.color: slice.current ? Theme.bright : Theme.rule
                }

                // Inside the shear, so clicks follow the slanted edges.
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: slice.current ? root.apply() : list.currentIndex = slice.index
                }
            }
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: list.bottom
        anchors.topMargin: 28
        spacing: 8

        Surface {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: name.implicitWidth + 40
            implicitHeight: name.implicitHeight + 20

            MouseArea {
                anchors.fill: parent
            }

            BarText {
                id: name

                readonly property string file: root.choices[list.currentIndex] ?? ""

                anchors.centerIn: parent
                text: root.label(file) + (file === WallState.current ? "  · şu an" : "")
                font.pixelSize: 15
                weight: 650
                color: Theme.bright
            }
        }

        Surface {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: keys.implicitWidth + Theme.pad * 2
            implicitHeight: keys.implicitHeight + 10
            radius: Theme.radius

            BarText {
                id: keys

                anchors.centerIn: parent
                text: "←→  gez     ↵  uygula     esc  kapat"
                font.pixelSize: Theme.small
                weight: 550
                color: Theme.dim
            }
        }
    }
}
