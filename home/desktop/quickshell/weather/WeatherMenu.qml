import QtQuick
import QtQuick.Layouts
import qs.common

// The weather card's menu, laid out like MyWeather's popup in the bar's
// graphite: the condition and temperature large, four readings under it, the
// next five days in columns, and the sun times and last update at the foot.
Popup {
    id: root

    readonly property var c: WeatherData.current
    readonly property var tr: Qt.locale("tr_TR")

    contentWidth: 380
    contentHeight: body.implicitHeight + 2 * Theme.pad + 4

    component Stat: ColumnLayout {
        required property string label
        required property string value

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
            text: parent.value
            color: Theme.text
            font.weight: Font.Medium
        }
    }

    ColumnLayout {
        id: body

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: Theme.pad + 4
            rightMargin: Theme.pad + 4
        }
        spacing: 10

        // Glyph, temperature, and the place with the condition beside them.
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            BarText {
                text: WeatherData.glyph
                font.pixelSize: 34
                color: Theme.bright
            }

            BarText {
                text: `${root.c.temp ?? ""}°`
                font.pixelSize: 30
                font.weight: Font.DemiBold
                color: Theme.bright
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                BarText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: WeatherData.place
                    font.weight: Font.Medium
                    color: Theme.text
                }

                BarText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: WeatherData.condition
                    font.pixelSize: Theme.small
                    color: Theme.dim
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Stat {
                label: "Hissedilen"
                value: `${root.c.feels ?? "–"}°`
            }
            Stat {
                label: "Rüzgâr"
                value: `${root.c.wind ?? "–"} km/s`
            }
            Stat {
                label: "Nem"
                value: `%${root.c.humidity ?? "–"}`
            }
            Stat {
                label: "Yağış"
                value: `%${root.c.rain ?? "–"}`
            }
        }

        Rule {}

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: WeatherData.days

                delegate: ColumnLayout {
                    id: day

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.maximumWidth: Number.POSITIVE_INFINITY
                    spacing: 3

                    BarText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.tr.toString(day.modelData.date, "ddd")
                        font.pixelSize: Theme.small
                        color: Theme.dim
                    }

                    BarText {
                        Layout.alignment: Qt.AlignHCenter
                        text: WeatherData.glyphFor(day.modelData.code, false)
                        font.pixelSize: 20
                        color: Theme.text
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        BarText {
                            text: `${day.modelData.max}°`
                            color: Theme.text
                        }
                        BarText {
                            text: `${day.modelData.min}°`
                            color: Theme.dim
                        }
                    }

                    // Rain chance, warm once rain is likely.
                    BarText {
                        Layout.alignment: Qt.AlignHCenter
                        text: `${String.fromCodePoint(0xF058C)} %${day.modelData.rain ?? 0}`
                        font.pixelSize: Theme.small - 1
                        color: (day.modelData.rain ?? 0) >= 50 ? Theme.warm : Theme.dim
                    }
                }
            }
        }

        Rule {}

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            BarText {
                text: `${String.fromCodePoint(0xF059C)} ${WeatherData.sunrise}   ${String.fromCodePoint(0xF059B)} ${WeatherData.sunset}`
                font.pixelSize: Theme.small
                font.wordSpacing: Theme.glyphGap
                color: Theme.dim
            }

            Item {
                Layout.fillWidth: true
            }

            // The last update; a click fetches again.
            BarText {
                text: WeatherData.failed ? "bağlanamadı · yenile" : `${Qt.formatDateTime(WeatherData.updated, "HH:mm")} · yenile`
                font.pixelSize: Theme.small
                color: WeatherData.failed ? Theme.hot : refreshMa.containsMouse ? Theme.text : Theme.dim

                MouseArea {
                    id: refreshMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WeatherData.refresh()
                }
            }
        }
    }
}
