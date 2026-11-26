import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "." as Root

// EdgePanel — Universal parent component for edge-anchored panels
// Apple Dynamic Island fluid spring physics and seamless concave shoulder silhouette
Item {
    id: edgePanel

    // ── Configuration ─────────────────────────────────────────────
    property string edge: "right" // "right" | "top" | "bottom" | "left" | "top-right" | "center"
    property real panelWidth: 310
    property real panelHeight: 450
    property int shoulderRadius: 28

    property real topMargin: (edge === "top" || edge === "top-right") ? Root.Theme.shelfHeight - 4 : 0
    property real bottomMargin: 0
    property real rightMargin: 0
    property real leftMargin: 0

    property color accentColor: Root.Theme.panelBorder
    property color panelFillColor: Root.Theme.panelBg

    property bool showDim: false
    property real dimMaxOpacity: 0.45
    property bool closeOnClickOutside: true

    // Default container for caller children
    default property alias content: contentContainer.data

    signal closeRequested()
    signal closed()

    anchors.fill: parent

    // ── Dynamic Island Physics States ─────────────────────────────
    readonly property real _maxSlide: (edge === "right" || edge === "left") ? Math.min(90, panelWidth * 0.32)
                                    : (edge === "bottom") ? Math.min(90, panelHeight * 0.32)
                                    : (edge === "top" || edge === "top-right") ? Math.min(100, panelHeight * 0.28)
                                    : 0

    readonly property real _initialScalePrimary: (edge === "top" || edge === "top-right") ? 0.76
                                                : (edge === "center") ? 0.88
                                                : 0.74
    readonly property real _initialScaleSecondary: (edge === "top" || edge === "top-right") ? 0.86
                                                  : (edge === "center") ? 0.88
                                                  : 0.86

    property real _slideOffset: _maxSlide
    property real _scalePrimary: _initialScalePrimary
    property real _scaleSecondary: _initialScaleSecondary
    property real _opacity: 0.0
    property real _contentScale: 0.92
    property real _contentOpacity: 0.0
    property real _dimOpacity: 0.0

    // dots-hyprland Expressive Spatial Open Animation
    ParallelAnimation {
        id: appearAnim

        // Edge displacement glide (top drops down with elastic bounce)
        NumberAnimation {
            target: edgePanel; property: "_slideOffset"
            from: edgePanel._maxSlide; to: 0.0
            duration: Root.Theme.animDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Root.Theme.curvePanelOpen
        }

        // Primary extrusion axis
        NumberAnimation {
            target: edgePanel; property: "_scalePrimary"
            from: edgePanel._initialScalePrimary; to: 1.0
            duration: Root.Theme.animDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Root.Theme.curvePanelOpen
        }

        // Orthogonal axis expansion
        NumberAnimation {
            target: edgePanel; property: "_scaleSecondary"
            from: edgePanel._initialScaleSecondary; to: 1.0
            duration: Root.Theme.animDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Root.Theme.curvePanelOpen
        }

        // Outer surface opacity
        NumberAnimation {
            target: edgePanel; property: "_opacity"
            from: 0.0; to: 1.0
            duration: 220
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Root.Theme.curveEmphasizedDecel
        }

        // Dim backdrop fade
        NumberAnimation {
            target: edgePanel; property: "_dimOpacity"
            from: 0.0; to: edgePanel.dimMaxOpacity
            duration: Root.Theme.animDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Root.Theme.curveEmphasizedDecel
        }

        // Content blooming
        ParallelAnimation {
            NumberAnimation {
                target: edgePanel; property: "_contentScale"
                from: 0.92; to: 1.0
                duration: Root.Theme.animDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelOpen
            }
            NumberAnimation {
                target: edgePanel; property: "_contentOpacity"
                from: 0.0; to: 1.0
                duration: 220
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curveEmphasizedDecel
            }
        }
    }

    // dots-hyprland Emphasized Accel Close Animation
    SequentialAnimation {
        id: dismissAnim

        ParallelAnimation {
            // Content contracts symmetrically
            NumberAnimation {
                target: edgePanel; property: "_contentScale"
                to: 0.92; duration: Root.Theme.animDurationFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelClose
            }
            NumberAnimation {
                target: edgePanel; property: "_contentOpacity"
                to: 0.0; duration: 140
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelClose
            }

            // Shell contracts back into initial state (mirrored inverse)
            NumberAnimation {
                target: edgePanel; property: "_slideOffset"
                to: edgePanel._maxSlide; duration: Root.Theme.animDurationFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelClose
            }
            NumberAnimation {
                target: edgePanel; property: "_scalePrimary"
                to: edgePanel._initialScalePrimary
                duration: Root.Theme.animDurationFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelClose
            }
            NumberAnimation {
                target: edgePanel; property: "_scaleSecondary"
                to: edgePanel._initialScaleSecondary
                duration: Root.Theme.animDurationFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelClose
            }
            NumberAnimation {
                target: edgePanel; property: "_opacity"
                to: 0.0; duration: Root.Theme.animDurationFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelClose
            }
            NumberAnimation {
                target: edgePanel; property: "_dimOpacity"
                to: 0.0; duration: Root.Theme.animDurationFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Root.Theme.curvePanelClose
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
        _scalePrimary = _initialScalePrimary;
        _scaleSecondary = _initialScaleSecondary;
        _opacity = 0.0;
        _contentScale = 0.90;
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
    }

    // ── Click outside handler ─────────────────────────────────────
    MouseArea {
        id: outsideDismissArea
        anchors.fill: parent
        enabled: edgePanel.closeOnClickOutside
        onClicked: edgePanel.closeRequested()
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

        anchors.verticalCenter: (edgePanel.edge === "right" || edgePanel.edge === "left" || edgePanel.edge === "center") ? parent.verticalCenter : undefined
        anchors.horizontalCenter: (edgePanel.edge === "top" || edgePanel.edge === "bottom" || edgePanel.edge === "center") ? parent.horizontalCenter : undefined

        transformOrigin: (edgePanel.edge === "right") ? Item.Right
                       : (edgePanel.edge === "left") ? Item.Left
                       : (edgePanel.edge === "top" || edgePanel.edge === "top-right") ? Item.Top
                       : (edgePanel.edge === "bottom") ? Item.Bottom
                       : Item.Center

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
                origin.x: (edgePanel.edge === "right") ? panelCard.width
                        : (edgePanel.edge === "left") ? 0
                        : panelCard.width / 2
                origin.y: (edgePanel.edge === "top" || edgePanel.edge === "top-right") ? 0
                        : (edgePanel.edge === "bottom") ? panelCard.height
                        : panelCard.height / 2
                xScale: edgePanel.edge === "center" ? edgePanel._scalePrimary : ((edgePanel.edge === "right" || edgePanel.edge === "left") ? edgePanel._scalePrimary : edgePanel._scaleSecondary)
                yScale: edgePanel.edge === "center" ? edgePanel._scalePrimary : ((edgePanel.edge === "right" || edgePanel.edge === "left") ? edgePanel._scaleSecondary : edgePanel._scalePrimary)
            }
        ]

        // Center Floating Rounded Card (GNOME modal / Dashboard style)
        Rectangle {
            id: centerPanelBg
            anchors.fill: parent
            visible: edgePanel.edge === "center"
            radius: edgePanel.shoulderRadius
            color: edgePanel.panelFillColor
            border.width: 1
            border.color: edgePanel.accentColor
        }

        // Unified Shape with Concave Shoulders
        Shape {
            id: panelShape
            anchors.fill: parent
            visible: edgePanel.edge !== "center"

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

            // ── Edge: TOP (MediaSelector, centered dynamic island) ──
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: edgePanel.edge === "top" ? edgePanel.panelFillColor : "transparent"

                startX: 0
                startY: 0

                PathLine { x: 0; y: 3 }

                // Left concave shoulder fillet with zero horizontal tangent at y=3
                PathCubic {
                    control1X: 14; control1Y: 3
                    control2X: 28; control2Y: 17
                    x: 28; y: 31
                }
                // Left flank
                PathLine { x: 28; y: Math.max(31, panelShape.height - 28) }
                // Bottom-left rounded corner
                PathCubic {
                    control1X: 28; control1Y: panelShape.height - 14
                    control2X: 42; control2Y: panelShape.height
                    x: 56; y: panelShape.height
                }
                // Bottom horizontal base
                PathLine { x: Math.max(56, panelShape.width - 56); y: panelShape.height }
                // Bottom-right rounded corner
                PathCubic {
                    control1X: panelShape.width - 42; control1Y: panelShape.height
                    control2X: panelShape.width - 28; control2Y: panelShape.height - 14
                    x: panelShape.width - 28; y: Math.max(31, panelShape.height - 28)
                }
                // Right flank
                PathLine { x: panelShape.width - 28; y: 31 }
                // Right concave shoulder fillet with zero horizontal exit tangent at y=3
                PathCubic {
                    control1X: panelShape.width - 28; control1Y: 17
                    control2X: panelShape.width - 14; control2Y: 3
                    x: panelShape.width; y: 3
                }
                // Top bridge over Waybar border for seamless fusion
                PathLine { x: panelShape.width; y: 0 }
                PathLine { x: 0; y: 0 }
            }

            ShapePath {
                strokeWidth: 1
                strokeColor: edgePanel.edge === "top" ? edgePanel.accentColor : "transparent"
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                joinStyle: ShapePath.RoundJoin

                startX: 0
                startY: 3

                // Left concave shoulder
                PathCubic {
                    control1X: 14; control1Y: 3
                    control2X: 28; control2Y: 17
                    x: 28; y: 31
                }
                PathLine { x: 28; y: Math.max(31, panelShape.height - 28) }
                PathCubic {
                    control1X: 28; control1Y: panelShape.height - 14
                    control2X: 42; control2Y: panelShape.height
                    x: 56; y: panelShape.height
                }
                PathLine { x: Math.max(56, panelShape.width - 56); y: panelShape.height }
                PathCubic {
                    control1X: panelShape.width - 42; control1Y: panelShape.height
                    control2X: panelShape.width - 28; control2Y: panelShape.height - 14
                    x: panelShape.width - 28; y: Math.max(31, panelShape.height - 28)
                }
                PathLine { x: panelShape.width - 28; y: 31 }
                PathCubic {
                    control1X: panelShape.width - 28; control1Y: 17
                    control2X: panelShape.width - 14; control2Y: 3
                    x: panelShape.width; y: 3
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

                PathLine { x: 0; y: 3 }

                // Left concave shoulder fillet with zero horizontal tangent at y=3
                PathCubic {
                    control1X: 14; control1Y: 3
                    control2X: 28; control2Y: 17
                    x: 28; y: 31
                }
                // Left flank
                PathLine { x: 28; y: Math.max(31, panelShape.height - 28) }
                // Bottom-left rounded corner
                PathCubic {
                    control1X: 28; control1Y: panelShape.height - 14
                    control2X: 42; control2Y: panelShape.height
                    x: 56; y: panelShape.height
                }
                // Bottom horizontal base
                PathLine { x: Math.max(56, panelShape.width - 28); y: panelShape.height }
                // Bottom-right rounded corner
                PathCubic {
                    control1X: panelShape.width - 14; control1Y: panelShape.height
                    control2X: panelShape.width; control2Y: panelShape.height - 14
                    x: panelShape.width; y: Math.max(28, panelShape.height - 28)
                }
                // Right flank
                PathLine { x: panelShape.width; y: 0 }
                // Top bridge over Waybar border for seamless fusion
                PathLine { x: 0; y: 0 }
            }

            ShapePath {
                strokeWidth: 1
                strokeColor: edgePanel.edge === "top-right" ? edgePanel.accentColor : "transparent"
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                joinStyle: ShapePath.RoundJoin

                startX: 0
                startY: 3

                // Left concave shoulder
                PathCubic {
                    control1X: 14; control1Y: 3
                    control2X: 28; control2Y: 17
                    x: 28; y: 31
                }
                PathLine { x: 28; y: Math.max(31, panelShape.height - 28) }
                PathCubic {
                    control1X: 28; control1Y: panelShape.height - 14
                    control2X: 42; control2Y: panelShape.height
                    x: 56; y: panelShape.height
                }
                PathLine { x: Math.max(56, panelShape.width - 28); y: panelShape.height }
                PathCubic {
                    control1X: panelShape.width - 14; control1Y: panelShape.height
                    control2X: panelShape.width; control2Y: panelShape.height - 14
                    x: panelShape.width; y: Math.max(28, panelShape.height - 28)
                }
                PathLine { x: panelShape.width; y: 0 }
            }
        }

        // Prevent click-through to dismiss overlay
        MouseArea {
            anchors.fill: parent
        }

        // Staggered Content Blooming Container (Dynamic Island style)
        Item {
            id: contentContainer
            anchors.fill: parent
            clip: true
            opacity: edgePanel._contentOpacity
            scale: (edgePanel.edge === "top" || edgePanel.edge === "top-right") ? 1.0 : edgePanel._contentScale
            transformOrigin: (edgePanel.edge === "top" || edgePanel.edge === "top-right") ? Item.Top : Item.Center
        }
    }
}
