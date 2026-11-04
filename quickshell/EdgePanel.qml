import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "." as Root

// EdgePanel — Universal parent component for edge-anchored panels
// Unified concave shoulder silhouette and VolumeOSD-inspired physics animation
Item {
    id: edgePanel

    // ── Configuration ─────────────────────────────────────────────
    property string edge: "right" // "right" | "top" | "bottom" | "left"
    property real panelWidth: 310
    property real panelHeight: 450
    property int shoulderRadius: 28

    property real topMargin: (edge === "top") ? Root.Theme.shelfHeight : 0
    property real bottomMargin: 0
    property real rightMargin: 0
    property real leftMargin: 0

    property color accentColor: Root.Theme.primary
    property color panelFillColor: Qt.rgba(Root.Theme.surfaceContainer.r,
                                           Root.Theme.surfaceContainer.g,
                                           Root.Theme.surfaceContainer.b, 0.94)

    property bool showDim: true
    property real dimMaxOpacity: 0.45
    property bool closeOnClickOutside: true

    // Default container for caller children
    default property alias content: contentContainer.data

    signal closeRequested()
    signal closed()

    anchors.fill: parent

    // ── Animation States (VolumeOSD physics) ───────────────────────
    property real _scalePrimary: 0.0
    property real _scaleSecondary: 0.82
    property real _opacity: 0.0
    property real _contentOpacity: 0.0
    property real _dimOpacity: 0.0

    // VolumeOSD-inspired organic extrusion animation
    ParallelAnimation {
        id: appearAnim
        NumberAnimation {
            target: edgePanel; property: "_scalePrimary"
            from: 0.0; to: 1.0; duration: 280
            easing.type: Easing.OutBack
            easing.overshoot: 1.18
        }
        NumberAnimation {
            target: edgePanel; property: "_scaleSecondary"
            from: 0.82; to: 1.0; duration: 260
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: edgePanel; property: "_opacity"
            from: 0.0; to: 1.0; duration: 160
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: edgePanel; property: "_dimOpacity"
            from: 0.0; to: edgePanel.dimMaxOpacity; duration: 220
            easing.type: Easing.OutQuad
        }
        SequentialAnimation {
            PauseAnimation { duration: 50 }
            NumberAnimation {
                target: edgePanel; property: "_contentOpacity"
                from: 0.0; to: 1.0; duration: 180
                easing.type: Easing.OutQuad
            }
        }
    }

    // VolumeOSD-inspired retraction animation
    SequentialAnimation {
        id: dismissAnim
        ParallelAnimation {
            NumberAnimation {
                target: edgePanel; property: "_contentOpacity"
                to: 0.0; duration: 100
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: edgePanel; property: "_scalePrimary"
                to: 0.0; duration: 190
                easing.type: Easing.InBack
                easing.overshoot: 1.1
            }
            NumberAnimation {
                target: edgePanel; property: "_scaleSecondary"
                to: 0.85; duration: 170
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: edgePanel; property: "_opacity"
                to: 0.0; duration: 170
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: edgePanel; property: "_dimOpacity"
                to: 0.0; duration: 170
                easing.type: Easing.InQuad
            }
        }
        ScriptAction {
            script: edgePanel.closed()
        }
    }

    function open(): void {
        dismissAnim.stop();
        appearAnim.stop();
        _scalePrimary = 0.0;
        _scaleSecondary = 0.82;
        _opacity = 0.0;
        _contentOpacity = 0.0;
        _dimOpacity = 0.0;
        appearAnim.start();
    }

    function close(): void {
        if (!dismissAnim.running) {
            appearAnim.stop();
            dismissAnim.start();
        }
    }

    Component.onCompleted: open()

    // ── Dim overlay ───────────────────────────────────────────────
    Rectangle {
        id: dimOverlay
        anchors.fill: parent
        visible: edgePanel.showDim
        color: Qt.rgba(0, 0, 0, edgePanel._dimOpacity)

        MouseArea {
            anchors.fill: parent
            enabled: edgePanel.closeOnClickOutside
            onClicked: edgePanel.closeRequested()
        }
    }

    // ── Panel Container ───────────────────────────────────────────
    Item {
        id: panelCard
        width: edgePanel.panelWidth
        height: edgePanel.panelHeight
        opacity: edgePanel._opacity

        // Edge placement
        anchors.right: (edgePanel.edge === "right") ? parent.right : undefined
        anchors.rightMargin: (edgePanel.edge === "right") ? edgePanel.rightMargin : 0
        anchors.left: (edgePanel.edge === "left") ? parent.left : undefined
        anchors.leftMargin: (edgePanel.edge === "left") ? edgePanel.leftMargin : 0
        anchors.top: (edgePanel.edge === "top") ? parent.top : undefined
        anchors.topMargin: (edgePanel.edge === "top") ? edgePanel.topMargin : 0
        anchors.bottom: (edgePanel.edge === "bottom") ? parent.bottom : undefined
        anchors.bottomMargin: (edgePanel.edge === "bottom") ? edgePanel.bottomMargin : 0

        anchors.verticalCenter: (edgePanel.edge === "right" || edgePanel.edge === "left") ? parent.verticalCenter : undefined
        anchors.horizontalCenter: (edgePanel.edge === "top" || edgePanel.edge === "bottom") ? parent.horizontalCenter : undefined

        // Transform origin aligned with edge
        transformOrigin: (edgePanel.edge === "right") ? Item.Right
                       : (edgePanel.edge === "left") ? Item.Left
                       : (edgePanel.edge === "top") ? Item.Top
                       : Item.Bottom

        transform: Scale {
            origin.x: (edgePanel.edge === "right") ? panelCard.width
                    : (edgePanel.edge === "left") ? 0
                    : panelCard.width / 2
            origin.y: (edgePanel.edge === "top") ? 0
                    : (edgePanel.edge === "bottom") ? panelCard.height
                    : panelCard.height / 2
            xScale: (edgePanel.edge === "right" || edgePanel.edge === "left") ? edgePanel._scalePrimary : edgePanel._scaleSecondary
            yScale: (edgePanel.edge === "right" || edgePanel.edge === "left") ? edgePanel._scaleSecondary : edgePanel._scalePrimary
        }

        // Unified Shape with Concave Shoulders
        Shape {
            id: panelShape
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4

            // ── Edge: RIGHT ──
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: edgePanel.edge === "right" ? edgePanel.panelFillColor : "transparent"

                startX: panelShape.width
                startY: 0

                PathArc {
                    x: panelShape.width - edgePanel.shoulderRadius
                    y: edgePanel.shoulderRadius
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Clockwise
                }
                PathLine { x: edgePanel.shoulderRadius; y: edgePanel.shoulderRadius }
                PathArc {
                    x: 0
                    y: edgePanel.shoulderRadius * 2
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: 0; y: Math.max(edgePanel.shoulderRadius * 2, panelShape.height - edgePanel.shoulderRadius * 2) }
                PathArc {
                    x: edgePanel.shoulderRadius
                    y: panelShape.height - edgePanel.shoulderRadius
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: panelShape.width - edgePanel.shoulderRadius; y: panelShape.height - edgePanel.shoulderRadius }
                PathArc {
                    x: panelShape.width
                    y: panelShape.height
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Clockwise
                }
                PathLine { x: panelShape.width; y: 0 }
            }

            ShapePath {
                strokeWidth: 2
                strokeColor: edgePanel.edge === "right" ? edgePanel.accentColor : "transparent"
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                joinStyle: ShapePath.RoundJoin

                startX: panelShape.width
                startY: 0

                PathArc {
                    x: panelShape.width - edgePanel.shoulderRadius
                    y: edgePanel.shoulderRadius
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Clockwise
                }
                PathLine { x: edgePanel.shoulderRadius; y: edgePanel.shoulderRadius }
                PathArc {
                    x: 0
                    y: edgePanel.shoulderRadius * 2
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: 0; y: Math.max(edgePanel.shoulderRadius * 2, panelShape.height - edgePanel.shoulderRadius * 2) }
                PathArc {
                    x: edgePanel.shoulderRadius
                    y: panelShape.height - edgePanel.shoulderRadius
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: panelShape.width - edgePanel.shoulderRadius; y: panelShape.height - edgePanel.shoulderRadius }
                PathArc {
                    x: panelShape.width
                    y: panelShape.height
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Clockwise
                }
            }

            // ── Edge: TOP ──
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: edgePanel.edge === "top" ? edgePanel.panelFillColor : "transparent"

                startX: 0
                startY: 0

                PathArc {
                    x: edgePanel.shoulderRadius
                    y: edgePanel.shoulderRadius
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Clockwise
                }
                PathLine { x: edgePanel.shoulderRadius; y: Math.max(edgePanel.shoulderRadius, panelShape.height - edgePanel.shoulderRadius) }
                PathArc {
                    x: edgePanel.shoulderRadius * 2
                    y: panelShape.height
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: Math.max(edgePanel.shoulderRadius * 2, panelShape.width - edgePanel.shoulderRadius * 2); y: panelShape.height }
                PathArc {
                    x: panelShape.width - edgePanel.shoulderRadius
                    y: Math.max(edgePanel.shoulderRadius, panelShape.height - edgePanel.shoulderRadius)
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: panelShape.width - edgePanel.shoulderRadius; y: edgePanel.shoulderRadius }
                PathArc {
                    x: panelShape.width
                    y: 0
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Clockwise
                }
                PathLine { x: 0; y: 0 }
            }

            ShapePath {
                strokeWidth: 2
                strokeColor: edgePanel.edge === "top" ? edgePanel.accentColor : "transparent"
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                joinStyle: ShapePath.RoundJoin

                startX: 0
                startY: 0

                PathArc {
                    x: edgePanel.shoulderRadius
                    y: edgePanel.shoulderRadius
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Clockwise
                }
                PathLine { x: edgePanel.shoulderRadius; y: Math.max(edgePanel.shoulderRadius, panelShape.height - edgePanel.shoulderRadius) }
                PathArc {
                    x: edgePanel.shoulderRadius * 2
                    y: panelShape.height
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: Math.max(edgePanel.shoulderRadius * 2, panelShape.width - edgePanel.shoulderRadius * 2); y: panelShape.height }
                PathArc {
                    x: panelShape.width - edgePanel.shoulderRadius
                    y: Math.max(edgePanel.shoulderRadius, panelShape.height - edgePanel.shoulderRadius)
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: panelShape.width - edgePanel.shoulderRadius; y: edgePanel.shoulderRadius }
                PathArc {
                    x: panelShape.width
                    y: 0
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Clockwise
                }
            }

            // ── Edge: BOTTOM ──
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: edgePanel.edge === "bottom" ? edgePanel.panelFillColor : "transparent"

                startX: 0
                startY: panelShape.height

                PathArc {
                    x: edgePanel.shoulderRadius
                    y: panelShape.height - edgePanel.shoulderRadius
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Clockwise
                }
                PathLine { x: edgePanel.shoulderRadius; y: edgePanel.shoulderRadius }
                PathArc {
                    x: edgePanel.shoulderRadius * 2
                    y: 0
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: Math.max(edgePanel.shoulderRadius * 2, panelShape.width - edgePanel.shoulderRadius * 2); y: 0 }
                PathArc {
                    x: panelShape.width - edgePanel.shoulderRadius
                    y: edgePanel.shoulderRadius
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: panelShape.width - edgePanel.shoulderRadius; y: panelShape.height - edgePanel.shoulderRadius }
                PathArc {
                    x: panelShape.width
                    y: panelShape.height
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Clockwise
                }
                PathLine { x: 0; y: panelShape.height }
            }

            ShapePath {
                strokeWidth: 2
                strokeColor: edgePanel.edge === "bottom" ? edgePanel.accentColor : "transparent"
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                joinStyle: ShapePath.RoundJoin

                startX: 0
                startY: panelShape.height

                PathArc {
                    x: edgePanel.shoulderRadius
                    y: panelShape.height - edgePanel.shoulderRadius
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Clockwise
                }
                PathLine { x: edgePanel.shoulderRadius; y: edgePanel.shoulderRadius }
                PathArc {
                    x: edgePanel.shoulderRadius * 2
                    y: 0
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: Math.max(edgePanel.shoulderRadius * 2, panelShape.width - edgePanel.shoulderRadius * 2); y: 0 }
                PathArc {
                    x: panelShape.width - edgePanel.shoulderRadius
                    y: edgePanel.shoulderRadius
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: panelShape.width - edgePanel.shoulderRadius; y: panelShape.height - edgePanel.shoulderRadius }
                PathArc {
                    x: panelShape.width
                    y: panelShape.height
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Clockwise
                }
            }
        }

        // Prevent click-through to dismiss overlay
        MouseArea {
            anchors.fill: parent
        }

        // Staggered Content Container
        Item {
            id: contentContainer
            anchors.fill: parent
            opacity: edgePanel._contentOpacity
        }
    }
}
