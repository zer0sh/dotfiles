import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "." as Root

// EdgePanel — Universal parent component for edge-anchored panels
// Fluid cinematic drawer physics (slide + micro-depth) with concave shoulder silhouette
Item {
    id: edgePanel

    // ── Configuration ─────────────────────────────────────────────
    property string edge: "right" // "right" | "top" | "bottom" | "left" | "top-right"
    property real panelWidth: 310
    property real panelHeight: 450
    property int shoulderRadius: 26

    property real topMargin: (edge === "top" || edge === "top-right") ? Root.Theme.shelfHeight : 0
    property real bottomMargin: 0
    property real rightMargin: 0
    property real leftMargin: 0

    property color accentColor: Root.Theme.primary
    property color panelFillColor: Qt.rgba(Root.Theme.surfaceContainer.r,
                                           Root.Theme.surfaceContainer.g,
                                           Root.Theme.surfaceContainer.b, 0.92)

    property bool showDim: true
    property real dimMaxOpacity: 0.45
    property bool closeOnClickOutside: true

    // Default container for caller children
    default property alias content: contentContainer.data

    signal closeRequested()
    signal closed()

    anchors.fill: parent

    // ── Animation States (Fluid Cinematic Drawer Physics) ─────────
    readonly property real _maxSlide: (edge === "right" || edge === "left") ? (panelWidth + 30) : (panelHeight + 30)

    property real _slideOffset: _maxSlide
    property real _microScale: 0.97
    property real _opacity: 0.0
    property real _contentOpacity: 0.0
    property real _dimOpacity: 0.0

    // Fluid deceleration on appear (OutCubic — no distortion, 100% crisp vector fidelity)
    ParallelAnimation {
        id: appearAnim
        NumberAnimation {
            target: edgePanel; property: "_slideOffset"
            from: edgePanel._maxSlide; to: 0.0; duration: 250
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: edgePanel; property: "_microScale"
            from: 0.97; to: 1.0; duration: 240
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: edgePanel; property: "_opacity"
            from: 0.0; to: 1.0; duration: 180
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: edgePanel; property: "_contentOpacity"
            from: 0.0; to: 1.0; duration: 210
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: edgePanel; property: "_dimOpacity"
            from: 0.0; to: edgePanel.dimMaxOpacity; duration: 230
            easing.type: Easing.OutQuad
        }
    }

    // Natural acceleration on dismiss (InCubic — sleek, seamless glide back into the edge)
    SequentialAnimation {
        id: dismissAnim
        ParallelAnimation {
            NumberAnimation {
                target: edgePanel; property: "_slideOffset"
                to: edgePanel._maxSlide; duration: 200
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: edgePanel; property: "_microScale"
                to: 0.97; duration: 190
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: edgePanel; property: "_contentOpacity"
                to: 0.0; duration: 130
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: edgePanel; property: "_opacity"
                to: 0.0; duration: 180
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: edgePanel; property: "_dimOpacity"
                to: 0.0; duration: 190
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
        _slideOffset = _maxSlide;
        _microScale = 0.97;
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
        anchors.right: (edgePanel.edge === "right" || edgePanel.edge === "top-right") ? parent.right : undefined
        anchors.rightMargin: (edgePanel.edge === "right" || edgePanel.edge === "top-right") ? edgePanel.rightMargin : 0
        anchors.left: (edgePanel.edge === "left") ? parent.left : undefined
        anchors.leftMargin: (edgePanel.edge === "left") ? edgePanel.leftMargin : 0
        anchors.top: (edgePanel.edge === "top" || edgePanel.edge === "top-right") ? parent.top : undefined
        anchors.topMargin: (edgePanel.edge === "top" || edgePanel.edge === "top-right") ? edgePanel.topMargin : 0
        anchors.bottom: (edgePanel.edge === "bottom") ? parent.bottom : undefined
        anchors.bottomMargin: (edgePanel.edge === "bottom") ? edgePanel.bottomMargin : 0

        anchors.verticalCenter: (edgePanel.edge === "right" || edgePanel.edge === "left") ? parent.verticalCenter : undefined
        anchors.horizontalCenter: (edgePanel.edge === "top" || edgePanel.edge === "bottom") ? parent.horizontalCenter : undefined

        transformOrigin: (edgePanel.edge === "right") ? Item.Right
                       : (edgePanel.edge === "left") ? Item.Left
                       : (edgePanel.edge === "top") ? Item.Top
                       : (edgePanel.edge === "top-right") ? Item.TopRight
                       : Item.Bottom

        transform: [
            Translate {
                x: (edgePanel.edge === "right") ? edgePanel._slideOffset
                 : (edgePanel.edge === "left") ? -edgePanel._slideOffset
                 : 0
                y: (edgePanel.edge === "top" || edgePanel.edge === "top-right") ? -edgePanel._slideOffset
                 : (edgePanel.edge === "bottom") ? edgePanel._slideOffset
                 : 0
            },
            Scale {
                origin.x: (edgePanel.edge === "right" || edgePanel.edge === "top-right") ? panelCard.width
                        : (edgePanel.edge === "left") ? 0
                        : panelCard.width / 2
                origin.y: (edgePanel.edge === "top" || edgePanel.edge === "top-right") ? 0
                        : (edgePanel.edge === "bottom") ? panelCard.height
                        : panelCard.height / 2
                xScale: edgePanel._microScale
                yScale: edgePanel._microScale
            }
        ]

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
                strokeWidth: 1.5
                strokeColor: edgePanel.edge === "right" ? edgePanel.accentColor : "transparent"
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
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
                strokeWidth: 1.5
                strokeColor: edgePanel.edge === "top" ? edgePanel.accentColor : "transparent"
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
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
                strokeWidth: 1.5
                strokeColor: edgePanel.edge === "bottom" ? edgePanel.accentColor : "transparent"
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
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

            // ── Edge: TOP-RIGHT (ControlCenter, NotificationCenter, ClipboardPanel) ──
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: edgePanel.edge === "top-right" ? edgePanel.panelFillColor : "transparent"

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
                PathLine { x: Math.max(edgePanel.shoulderRadius * 2, panelShape.width - edgePanel.shoulderRadius); y: panelShape.height }
                PathArc {
                    x: panelShape.width
                    y: Math.max(edgePanel.shoulderRadius, panelShape.height - edgePanel.shoulderRadius)
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: panelShape.width; y: 0 }
                PathLine { x: 0; y: 0 }
            }

            ShapePath {
                strokeWidth: 1.5
                strokeColor: edgePanel.edge === "top-right" ? edgePanel.accentColor : "transparent"
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
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
                PathLine { x: Math.max(edgePanel.shoulderRadius * 2, panelShape.width - edgePanel.shoulderRadius); y: panelShape.height }
                PathArc {
                    x: panelShape.width
                    y: Math.max(edgePanel.shoulderRadius, panelShape.height - edgePanel.shoulderRadius)
                    radiusX: edgePanel.shoulderRadius
                    radiusY: edgePanel.shoulderRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: panelShape.width; y: 0 }
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
