import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland
import qs.common

PanelWindow {
    id: root

    property var choices: [WallState.black]

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
        leftMargin: (width - root.wideW) / 2
        rightMargin: (width - root.wideW) / 2
        spacing: 10
        interactive: false
        focus: true
        keyNavigationEnabled: true
        onCurrentIndexChanged: Qt.callLater(list.recenter)

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
