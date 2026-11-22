import QtQuick
import qs.common

BarModule {
    id: root

    visible: Recorder.busy
    selected: Recorder.recording
    onClicked: Recorder.stop()

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: 8
        radius: Recorder.recording ? 4 : 2
        color: Recorder.saving ? Theme.dim : Theme.hot

        SequentialAnimation on opacity {
            running: Recorder.recording
            loops: Animation.Infinite
            onRunningChanged: if (!running)
                parent.opacity = 1

            NumberAnimation {
                to: 0.35
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                to: 1
                duration: 700
                easing.type: Easing.InOutSine
            }
        }
    }

    BarText {
        anchors.verticalCenter: parent.verticalCenter
        text: Recorder.saving ? (Recorder.kind === "gif" ? "gif hazırlanıyor" : "kaydediliyor") : Recorder.countdown > 0 ? `${Recorder.countdown}` : Recorder.clock(Recorder.elapsed)
        color: Recorder.recording ? Theme.bright : Theme.dim
        font.features: {
            "tnum": 1
        }
    }
}
