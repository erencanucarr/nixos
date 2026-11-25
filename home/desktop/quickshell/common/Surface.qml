import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property color fill: Theme.raised
    property int radius: Theme.radiusLg

    readonly property real glowSize: 480

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.ring
    }

    Shape {
        id: shape

        anchors.fill: parent
        anchors.margins: 1
        preferredRendererType: Shape.CurveRenderer

        readonly property int r: Math.max(0, root.radius - 1)

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
                GradientStop { position: 0; color: Theme.glowPanel }
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
                GradientStop { position: 0; color: Theme.glowPanelFar }
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
            fillItem: tile
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
        source: "grain-raised.png"
        fillMode: Image.Tile
        layer.enabled: true
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: Theme.edge
    }

    Item {
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
