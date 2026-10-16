import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: backgroundScope

    property string currentWallpaper: ""
    property bool isAnimating: false

    signal requestChange(string cleanPath)
    signal requestWallpaperPicker()

    // ── Leer el fondo configurado al inicio ──────────────────────
    Process {
        id: readWallProc
        command: ["/bin/sh", "-c", "cat ~/.config/themes/current/wallpaper 2>/dev/null || echo '/home/zero/Pictures/walls/wa1.png'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var w = text.trim();
                if (w !== "") {
                    backgroundScope.currentWallpaper = w;
                } else {
                    backgroundScope.currentWallpaper = "/home/zero/Pictures/walls/wa1.png";
                }
            }
        }
    }

    Component.onCompleted: readWallProc.running = true

    // ── Procesos para persistir y ejecutar Matugen ──────────────
    Process {
        id: saveProc
    }

    Process {
        id: matugenProc
    }

    // Temporizador de seguridad para evitar bloqueos si la animación fallara
    Timer {
        id: safetyTimer
        interval: 1600
        repeat: false
        onTriggered: {
            backgroundScope.isAnimating = false;
        }
    }

    function changeWallpaper(path) {
        if (!path || path === "") return;
        var cleanPath = path.replace(/^file:\/\//, "");
        if (cleanPath === currentWallpaper && !isAnimating) return;

        isAnimating = true;
        safetyTimer.restart();

        // Persistir en el archivo de estado de inmediato
        if (saveProc.running) saveProc.running = false;
        saveProc.command = ["/bin/sh", "-c",
            "mkdir -p ~/.config/themes/current && printf '%s\\n' '" +
            cleanPath.replace(/'/g, "'\\''") +
            "' > ~/.config/themes/current/wallpaper"];
        saveProc.running = true;

        // Ejecutar Matugen en segundo plano
        if (matugenProc.running) matugenProc.running = false;
        matugenProc.command = ["/home/zero/.config/themes/apply-matugen.sh", cleanPath];
        matugenProc.running = true;

        // Disparar transición visual en cada monitor
        requestChange(cleanPath);
    }

    // ── IPC Handler: `qs ipc call wallpaper set <path>` ──────────
    IpcHandler {
        target: "wallpaper"
        function set(path: string): void {
            backgroundScope.changeWallpaper(path);
        }
        function toggle(): void {
            backgroundScope.requestWallpaperPicker();
        }
    }

    // ── Renderizado en todas las pantallas conectadas ────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "#000000"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell:background"

            Item {
                id: container
                anchors.fill: parent
                clip: true

                // Doble búfer (ping-pong) para transiciones 100% confiables:
                // activeLayer === 0 -> layerA visible
                // activeLayer === 1 -> layerB visible
                property int activeLayer: 0
                property string pendingWall: ""

                Image {
                    id: layerA
                    anchors.fill: parent
                    source: backgroundScope.currentWallpaper !== "" ? "file://" + backgroundScope.currentWallpaper : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    scale: 1.0
                    opacity: 1.0
                    transformOrigin: Item.Center
                    z: container.activeLayer === 0 ? 2 : 1

                    onStatusChanged: {
                        if (status === Image.Ready && container.activeLayer === 1 && animToA.pending) {
                            animToA.pending = false;
                            animToA.restart();
                        }
                    }
                }

                Image {
                    id: layerB
                    anchors.fill: parent
                    source: ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    scale: 0.88
                    opacity: 0.0
                    transformOrigin: Item.Center
                    z: container.activeLayer === 1 ? 2 : 1

                    onStatusChanged: {
                        if (status === Image.Ready && container.activeLayer === 0 && animToB.pending) {
                            animToB.pending = false;
                            animToB.restart();
                        }
                    }
                }

                // Animación de Layer A -> Layer B (B entra desde el centro con Zoom & Blur, A sale)
                ParallelAnimation {
                    id: animToB
                    property bool pending: false

                    // Outgoing: layerA
                    NumberAnimation {
                        target: layerA
                        property: "scale"
                        from: 1.0
                        to: 1.15
                        duration: 750
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: layerA
                        property: "opacity"
                        from: 1.0
                        to: 0.0
                        duration: 750
                        easing.type: Easing.InOutQuad
                    }

                    // Incoming: layerB
                    NumberAnimation {
                        target: layerB
                        property: "scale"
                        from: 0.88
                        to: 1.0
                        duration: 750
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: layerB
                        property: "opacity"
                        from: 0.0
                        to: 1.0
                        duration: 750
                        easing.type: Easing.InOutQuad
                    }

                    onFinished: {
                        container.activeLayer = 1;
                        layerA.source = "";
                        layerA.scale = 1.0;
                        layerA.opacity = 0.0;
                        backgroundScope.currentWallpaper = container.pendingWall;
                        backgroundScope.isAnimating = false;
                        safetyTimer.stop();
                    }
                }

                // Animación de Layer B -> Layer A (A entra desde el centro con Zoom & Blur, B sale)
                ParallelAnimation {
                    id: animToA
                    property bool pending: false

                    // Outgoing: layerB
                    NumberAnimation {
                        target: layerB
                        property: "scale"
                        from: 1.0
                        to: 1.15
                        duration: 750
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: layerB
                        property: "opacity"
                        from: 1.0
                        to: 0.0
                        duration: 750
                        easing.type: Easing.InOutQuad
                    }

                    // Incoming: layerA
                    NumberAnimation {
                        target: layerA
                        property: "scale"
                        from: 0.88
                        to: 1.0
                        duration: 750
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: layerA
                        property: "opacity"
                        from: 0.0
                        to: 1.0
                        duration: 750
                        easing.type: Easing.InOutQuad
                    }

                    onFinished: {
                        container.activeLayer = 0;
                        layerB.source = "";
                        layerB.scale = 1.0;
                        layerB.opacity = 0.0;
                        backgroundScope.currentWallpaper = container.pendingWall;
                        backgroundScope.isAnimating = false;
                        safetyTimer.stop();
                    }
                }

                // Temporizador de respaldo si onStatusChanged no se dispara
                Timer {
                    id: fallbackAnimTimer
                    interval: 60
                    repeat: false
                    onTriggered: {
                        if (animToB.pending) {
                            animToB.pending = false;
                            animToB.restart();
                        } else if (animToA.pending) {
                            animToA.pending = false;
                            animToA.restart();
                        }
                    }
                }

                function transitionTo(newPath) {
                    container.pendingWall = newPath;
                    var fileUri = "file://" + newPath;

                    // Detener cualquier animación en curso para evitar parpadeos
                    if (animToA.running) animToA.stop();
                    if (animToB.running) animToB.stop();

                    if (container.activeLayer === 0) {
                        // A es el actual, B es el nuevo
                        layerB.scale = 0.88;
                        layerB.opacity = 0.0;
                        layerB.z = 2;
                        layerA.z = 1;
                        layerA.scale = 1.0;
                        layerA.opacity = 1.0;

                        animToB.pending = true;
                        layerB.source = fileUri;

                        if (layerB.status === Image.Ready) {
                            animToB.pending = false;
                            animToB.restart();
                        } else {
                            fallbackAnimTimer.restart();
                        }
                    } else {
                        // B es el actual, A es el nuevo
                        layerA.scale = 0.88;
                        layerA.opacity = 0.0;
                        layerA.z = 2;
                        layerB.z = 1;
                        layerB.scale = 1.0;
                        layerB.opacity = 1.0;

                        animToA.pending = true;
                        layerA.source = fileUri;

                        if (layerA.status === Image.Ready) {
                            animToA.pending = false;
                            animToA.restart();
                        } else {
                            fallbackAnimTimer.restart();
                        }
                    }
                }

                Connections {
                    target: backgroundScope
                    function onRequestChange(path) {
                        container.transitionTo(path);
                    }
                }
            }
        }
    }
}
