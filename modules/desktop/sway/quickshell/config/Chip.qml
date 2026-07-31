import QtQuick

Item {
    id: c

    required property var props
    required property var rootRef
    property bool hover: false

    readonly property bool blink: props.blink === true || (props.blink !== false && (props.tone === "warn" || props.tone === "danger"))
    readonly property color activeColor:
        props.tone === "on"     ? rootRef.accent
      : props.tone === "warn"   ? rootRef.warn
      : props.tone === "danger" ? rootRef.danger
      : hover                    ? rootRef.accent
      :                            rootRef.fg

    implicitHeight: 20
    implicitWidth: chipRow.implicitWidth

    Row {
        id: chipRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        property real blinkAlpha: 1.0
        opacity: c.blink ? blinkAlpha : 1.0

        SequentialAnimation on blinkAlpha {
            running: c.blink
            loops: Animation.Infinite
            NumberAnimation { to: 0.30; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
        }

        Text {
            text: c.props.icon || ""
            color: c.activeColor
            font { family: c.rootRef.fontFamily; pixelSize: 14; weight: Font.Bold }
            visible: text.length > 0
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Text {
            text: c.props.text || ""
            color: c.activeColor
            font { family: c.rootRef.fontFamily; pixelSize: 13; weight: Font.Bold }
            visible: text.length > 0
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: c.hover = true
        onExited:  c.hover = false
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton && c.props.onClickRight)
                c.props.onClickRight()
            else if (c.props.onClick)
                c.props.onClick()
        }
    }
}
