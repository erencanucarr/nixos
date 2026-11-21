import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

// The app drawer: a search box over a grid of every installed app, on the
// focused screen. Super (or the mouse's side button) or the bar's apps
// button opens it. Type to filter, arrows to move, Enter to launch, Esc or a
// click outside to close.
PanelWindow {
    id: root

    property string query: ""

    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay && root.matches(a)).sort((a, b) => a.name.localeCompare(b.name))

    function matches(app: var): bool {
        if (root.query === "")
            return true;
        const hay = [app.name, app.genericName, app.comment, ...(app.keywords ?? [])].join(" ").toLowerCase();
        return root.query.toLowerCase().split(/\s+/).every(w => hay.includes(w));
    }

    function launch(app: var): void {
        if (!app)
            return;
        app.execute();
        Panels.drawerOpen = false;
    }

    visible: Panels.drawerOpen
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "can-drawer"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "#990a0a0c"

    onVisibleChanged: {
        if (visible) {
            search.text = "";
            grid.currentIndex = 0;
            search.forceActiveFocus();
        }
    }

    // A click outside the panel closes the drawer.
    MouseArea {
        anchors.fill: parent
        onClicked: Panels.drawerOpen = false
    }

    Rectangle {
        id: panel

        anchors.centerIn: parent
        width: Math.min(parent.width - 160, 820)
        height: Math.min(parent.height - 160, 600)
        radius: 12
        color: Theme.raised
        border.width: 1
        border.color: Theme.edge

        // Clicks on the panel itself stay here.
        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            id: searchBox

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
            }
            height: 40
            radius: 8
            color: Theme.ground
            border.width: 1
            border.color: search.activeFocus ? Theme.rule : Theme.line

            Text {
                id: searchIcon
                anchors {
                    left: parent.left
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                text: Glyph.search
                color: Theme.dim
                font.family: Theme.family
                font.pixelSize: 16
            }

            TextInput {
                id: search

                anchors {
                    left: searchIcon.right
                    leftMargin: 10
                    right: parent.right
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                color: Theme.text
                selectionColor: Theme.text
                selectedTextColor: Theme.ground
                font.family: Theme.family
                font.pixelSize: 14
                clip: true

                onTextChanged: {
                    root.query = text;
                    grid.currentIndex = 0;
                }

                Keys.onPressed: e => {
                    switch (e.key) {
                    case Qt.Key_Escape:
                        Panels.drawerOpen = false;
                        break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.launch(root.apps[grid.currentIndex]);
                        break;
                    case Qt.Key_Left:
                        grid.moveCurrentIndexLeft();
                        break;
                    case Qt.Key_Right:
                        grid.moveCurrentIndexRight();
                        break;
                    case Qt.Key_Up:
                        grid.moveCurrentIndexUp();
                        break;
                    case Qt.Key_Down:
                        grid.moveCurrentIndexDown();
                        break;
                    default:
                        return;
                    }
                    e.accepted = true;
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: "Uygulama ara"
                    color: Theme.dim
                    font: search.font
                }
            }
        }

        GridView {
            id: grid

            anchors {
                top: searchBox.bottom
                topMargin: 12
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 12
            }
            clip: true
            model: root.apps
            cellWidth: Math.floor(width / 6)
            cellHeight: 104
            boundsBehavior: Flickable.StopAtBounds
            highlightFollowsCurrentItem: false

            delegate: Item {
                id: cell

                required property var modelData
                required property int index

                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 10
                    color: grid.currentIndex === cell.index ? Theme.selRaised : area.containsMouse ? Theme.hoverRaised : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.anim
                        }
                    }
                }

                // The app's icon, else a generic one, else its initial on a
                // tile: an icon the theme lacks would draw Qt's checkerboard.
                readonly property string iconSource: Quickshell.iconPath(cell.modelData.icon, true) || Quickshell.iconPath("application-x-executable", true) || Quickshell.iconPath("applications-other", true)

                Item {
                    id: icon
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: 16
                    }
                    width: 44
                    height: 44

                    IconImage {
                        anchors.fill: parent
                        visible: cell.iconSource !== ""
                        source: cell.iconSource
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        visible: cell.iconSource === ""
                        radius: 10
                        color: Theme.rule
                        border.width: 1
                        border.color: Theme.edge

                        Text {
                            anchors.centerIn: parent
                            text: cell.modelData.name.charAt(0).toUpperCase()
                            color: Theme.text
                            font.family: Theme.family
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Text {
                    anchors {
                        top: icon.bottom
                        topMargin: 8
                        left: parent.left
                        right: parent.right
                        leftMargin: 10
                        rightMargin: 10
                    }
                    text: cell.modelData.name
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: grid.currentIndex === cell.index ? Theme.bright : Theme.text
                    font.family: Theme.family
                    font.pixelSize: 12
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.launch(cell.modelData)
                }
            }
        }

        Text {
            anchors.centerIn: grid
            visible: root.apps.length === 0
            text: "Sonuç yok"
            color: Theme.dim
            font.family: Theme.family
            font.pixelSize: 13
        }
    }
}
