import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

Menu {
    id: root

    readonly property int fs: 14
    readonly property int wt: 550
    readonly property var tr: Qt.locale("tr_TR")

    property date month: firstOf(clock.date)
    property var picked: null
    property bool adding: false
    readonly property date focusDay: picked ?? clock.date

    readonly property var holidays: ({
            "01-01": "Yılbaşı",
            "04-23": "Ulusal Egemenlik ve Çocuk Bayramı",
            "05-01": "Emek ve Dayanışma Günü",
            "05-19": "Atatürk'ü Anma, Gençlik ve Spor Bayramı",
            "07-15": "Demokrasi ve Millî Birlik Günü",
            "08-30": "Zafer Bayramı",
            "10-29": "Cumhuriyet Bayramı"
        })

    readonly property var days: {
        const first = root.month;
        const start = new Date(first.getFullYear(), first.getMonth(), 1 - (first.getDay() + 6) % 7);
        return Array.from({
            length: 42
        }, (_, i) => new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
    }

    function firstOf(d: date): date {
        return new Date(d.getFullYear(), d.getMonth(), 1);
    }

    function shift(months: int): void {
        root.month = new Date(root.month.getFullYear(), root.month.getMonth() + months, 1);
    }

    function sameDay(a: var, b: var): bool {
        return !!a && !!b && a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function holiday(d: date): string {
        const key = `${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
        return root.holidays[key] ?? "";
    }

    function isoWeek(d: date): int {
        const t = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 3 - (d.getDay() + 6) % 7);
        const jan4 = new Date(t.getFullYear(), 0, 4);
        return 1 + Math.round(((t - jan4) / 86400000 - 3 + (jan4.getDay() + 6) % 7) / 7);
    }

    function dayOfYear(d: date): int {
        return Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - new Date(d.getFullYear(), 0, 1)) / 86400000) + 1;
    }

    function distance(d: date): string {
        const today = new Date(clock.date.getFullYear(), clock.date.getMonth(), clock.date.getDate());
        const n = Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - today) / 86400000);
        if (n === 0)
            return "bugün";
        if (n === 1)
            return "yarın";
        if (n === -1)
            return "dün";
        const a = Math.abs(n);
        return `${a} gün ${n > 0 ? "sonra" : "önce"}`;
    }

    contentWidth: 324
    rowSpacing: 8

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        BarText {
            text: root.tr.toString(clock.date, "dddd")
            font.pixelSize: root.fs - 2
            weight: root.wt
            color: Theme.dim
        }

        BarText {
            text: root.tr.toString(clock.date, "d MMMM yyyy")
            font.pixelSize: 22
            weight: 600
            color: Theme.bright
        }
    }

    Rule {}

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        BarText {
            Layout.fillWidth: true
            text: root.tr.toString(root.month, "MMMM yyyy")
            font.pixelSize: root.fs
            weight: 600
            color: Theme.text
        }

        component Nav: BarText {
            id: nav

            signal clicked

            font.pixelSize: root.fs
            weight: root.wt
            color: navMa.containsMouse ? Theme.bright : Theme.dim

            MouseArea {
                id: navMa
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: nav.clicked()
            }
        }

        Nav {
            visible: !root.sameDay(root.month, root.firstOf(clock.date))
            Layout.rightMargin: 6
            text: "bugün"
            font.pixelSize: root.fs - 2
            onClicked: {
                root.month = root.firstOf(clock.date);
                root.picked = null;
            }
        }

        Nav {
            Layout.preferredWidth: 22
            horizontalAlignment: Text.AlignHCenter
            text: Glyph.chevronLeft
            onClicked: root.shift(-1)
        }

        Nav {
            Layout.preferredWidth: 22
            horizontalAlignment: Text.AlignHCenter
            text: Glyph.chevronRight
            onClicked: root.shift(1)
        }
    }

    ColumnLayout {
        id: grid

        Layout.fillWidth: true
        spacing: 2

        readonly property int columnSpacing: 2
        readonly property real cell: (width - 26 - 6 * columnSpacing) / 7

        Item {
            Layout.fillWidth: true
            implicitHeight: 18

            Repeater {
                model: ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]

                delegate: BarText {
                    required property string modelData
                    required property int index

                    x: 26 + index * (grid.cell + grid.columnSpacing)
                    width: grid.cell
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pixelSize: root.fs - 3
                    weight: root.wt
                    color: index >= 5 ? Theme.dim : Theme.text
                    opacity: 0.8
                }
            }
        }

        Repeater {
            model: 6

            delegate: Item {
                id: week

                required property int index
                readonly property var days: root.days.slice(index * 7, index * 7 + 7)

                Layout.fillWidth: true
                implicitHeight: 30

                BarText {
                    width: 24
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.isoWeek(week.days[0])
                    font.pixelSize: root.fs - 4
                    weight: root.wt
                    color: Theme.dim
                    opacity: 0.6
                }

                Repeater {
                    model: week.days

                    delegate: Rectangle {
                        id: day

                        required property var modelData
                        required property int index
                        readonly property bool inMonth: modelData.getMonth() === root.month.getMonth()
                        readonly property bool today: root.sameDay(modelData, clock.date)
                        readonly property bool picked: root.sameDay(modelData, root.picked)
                        readonly property string holiday: root.holiday(modelData)

                        x: 26 + index * (grid.cell + grid.columnSpacing)
                        width: grid.cell
                        height: 30
                        radius: Theme.radius
                        color: day.today ? Theme.text : day.picked ? Theme.sel : dayMa.containsMouse ? Theme.hoverRaised : "transparent"
                        border.width: day.picked && !day.today ? 1 : 0
                        border.color: Theme.dim

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.anim
                            }
                        }

                        BarText {
                            anchors.centerIn: parent
                            text: day.modelData.getDate()
                            font.pixelSize: root.fs - 1
                            weight: day.today ? 650 : root.wt
                            color: day.today ? Theme.ground : !day.inMonth ? Theme.rule : day.holiday ? Theme.warm : day.index >= 5 ? Theme.dim : Theme.text
                        }

                        Row {
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                bottom: parent.bottom
                                bottomMargin: 3
                            }
                            spacing: 3

                            Rectangle {
                                visible: day.holiday !== "" && day.inMonth
                                width: 4
                                height: 4
                                radius: 2
                                color: day.today ? Theme.ground : Theme.warm
                            }

                            Rectangle {
                                visible: Notes.list(day.modelData).length > 0
                                width: 4
                                height: 4
                                radius: 2
                                color: day.today ? Theme.ground : Theme.bright
                            }
                        }

                        MouseArea {
                            id: dayMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: e => {
                                const right = e.button === Qt.RightButton;
                                root.picked = !right && root.sameDay(day.modelData, root.picked) ? null : day.modelData;
                                root.adding = right;
                                if (!day.inMonth)
                                    root.month = root.firstOf(day.modelData);
                            }
                        }
                    }
                }
            }
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: e => root.shift(e.angleDelta.y > 0 ? -1 : 1)
        }
    }

    Rule {}

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        BarText {
            Layout.fillWidth: true
            text: root.picked ? `${root.tr.toString(root.picked, "d MMMM yyyy, dddd")}` : `Yılın ${root.dayOfYear(clock.date)}. günü · ${root.isoWeek(clock.date)}. hafta`
            elide: Text.ElideRight
            font.pixelSize: root.fs - 2
            weight: root.wt
            color: Theme.text
        }

        BarText {
            readonly property string what: root.picked ? root.holiday(root.picked) : root.holiday(clock.date)

            Layout.fillWidth: true
            visible: text !== ""
            text: root.picked ? [root.distance(root.picked), what].filter(s => s).join(" · ") : what
            elide: Text.ElideRight
            font.pixelSize: root.fs - 3
            weight: root.wt
            color: what ? Theme.warm : Theme.dim
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: Notes.list(root.focusDay)

            delegate: Rectangle {
                id: note

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: noteRow.implicitHeight + 14
                radius: Theme.radius
                color: noteMa.containsMouse ? Theme.hoverRaised : "transparent"
                border.width: 1
                border.color: Theme.edge

                MouseArea {
                    id: noteMa
                    anchors.fill: parent
                    hoverEnabled: true
                }

                RowLayout {
                    id: noteRow

                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                        rightMargin: 8
                    }
                    spacing: 8

                    BarText {
                        Layout.alignment: Qt.AlignTop
                        text: note.modelData.time || "—"
                        font.pixelSize: root.fs - 2
                        weight: 600
                        color: note.modelData.reminded ? Theme.dim : Theme.warm
                    }

                    BarText {
                        Layout.fillWidth: true
                        text: note.modelData.text
                        wrapMode: Text.Wrap
                        font.pixelSize: root.fs - 2
                        weight: root.wt
                        color: Theme.text
                    }

                    BarText {
                        Layout.alignment: Qt.AlignTop
                        visible: noteMa.containsMouse || delMa.containsMouse
                        text: String.fromCodePoint(0xF0156)
                        font.pixelSize: root.fs
                        color: delMa.containsMouse ? Theme.hot : Theme.dim

                        MouseArea {
                            id: delMa
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notes.remove(Notes.key(root.focusDay), note.modelData.id)
                        }
                    }
                }
            }
        }

        RowLayout {
            visible: root.adding
            Layout.fillWidth: true
            spacing: 4

            Field {
                id: noteText
                implicitHeight: 30
                textSize: root.fs - 2
                placeholder: "Not…"
                onAccepted: save()
                input.Keys.onEscapePressed: root.adding = false

                function save(): void {
                    Notes.add(root.focusDay, noteText.text, noteTime.text);
                    noteText.text = "";
                    noteTime.text = "";
                    root.adding = false;
                }
            }

            Field {
                id: noteTime
                Layout.fillWidth: false
                implicitWidth: 72
                implicitHeight: 30
                textSize: root.fs - 2
                placeholder: "SS:DD"
                onAccepted: noteText.save()
                input.Keys.onEscapePressed: root.adding = false
            }
        }

        BarText {
            visible: root.adding
            text: "Saat boşsa 09:00'da hatırlatılır · Enter kaydeder · Esc vazgeçer"
            font.pixelSize: root.fs - 4
            weight: root.wt
            color: Theme.dim
        }

        BarText {
            visible: !root.adding
            text: `+ ${root.picked ? "bu güne" : "bugüne"} not ekle`
            font.pixelSize: root.fs - 3
            weight: root.wt
            color: addMa.containsMouse ? Theme.bright : Theme.dim

            MouseArea {
                id: addMa
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.adding = true
            }
        }
    }

    onAddingChanged: if (adding)
        Qt.callLater(() => noteText.input.forceActiveFocus())
}
