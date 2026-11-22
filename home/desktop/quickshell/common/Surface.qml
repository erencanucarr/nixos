import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property color fill: Theme.raised
    property int radius: Theme.radiusLg
    property bool edged: true
    property bool lifted: true
    property color glow: Theme.glowPanel
    property color glowFar: Theme.glowPanelFar
    property real glowSize: 480
    property string grain: "grain-raised.png"

    readonly property int inset: edged ? 1 : 0

    Rectangle {
        visible: root.edged
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.ring
    }

    Shape {
        id: shape

        anchors.fill: parent
        anchors.margins: root.inset
        preferredRendererType: Shape.CurveRenderer

        readonly property int r: Math.max(0, root.radius - root.inset)

        ShapePath {
            strokeWidth: -1
            fillColor: root.fill
            PathRectangle {
                width: shape.width
                height: shape.height
                radius: shape.r
            }
        }

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: 0
                centerY: 0
                centerRadius: root.glowSize * 0.75
                focalX: 0
                focalY: 0
                GradientStop { position: 0; color: root.glow }
                GradientStop { position: 1; color: "transparent" }
            }
            fillTransform: PlanarTransform.fromScale(1, 0.52)
            PathRectangle {
                width: shape.width
                height: shape.height
                radius: shape.r
            }
        }

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: shape.width
                centerY: 0
                centerRadius: root.glowSize * 0.62
                focalX: shape.width
                focalY: 0
                GradientStop { position: 0; color: root.glowFar }
                GradientStop { position: 1; color: "transparent" }
            }
            fillTransform: PlanarTransform.fromScale(1, 0.5)
            PathRectangle {
                width: shape.width
                height: shape.height
                radius: shape.r
            }
        }

        ShapePath {
            strokeWidth: -1
            fillColor: "transparent"
            fillItem: root.grain ? tile : null
            PathRectangle {
                width: shape.width
                height: shape.height
                radius: shape.r
            }
        }
    }

    Image {
        id: tile

        width: shape.width
        height: shape.height
        visible: false
        source: root.grain
        fillMode: Image.Tile
        layer.enabled: true
    }

    Rectangle {
        visible: root.edged
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: Theme.edge
    }

    Item {
        visible: root.edged && root.lifted
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 2
        }
        height: root.radius
        clip: true

        Rectangle {
            width: parent.width
            height: parent.height * 3
            radius: Math.max(0, root.radius - 2)
            color: "transparent"
            border.width: 1
            border.color: Theme.lift
        }
    }
}
