import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: backgroundScope

    property string currentWallpaper: ""
    property string nextWallpaper: ""
    property bool isAnimating: false

    signal triggerTransition()
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

    function changeWallpaper(path) {
        if (!path || path === "") return;
        var cleanPath = path.replace(/^file:\/\//, "");
        if (cleanPath === currentWallpaper && !isAnimating) return;

        nextWallpaper = cleanPath;
        isAnimating = true;

        // Persistir en el archivo de estado
        saveProc.command = ["/bin/sh", "-c",
            "mkdir -p ~/.config/themes/current && printf '%s\\n' '" +
            cleanPath.replace(/'/g, "'\\''") +
            "' > ~/.config/themes/current/wallpaper"];
        saveProc.running = true;

        // Ejecutar Matugen en segundo plano
        matugenProc.command = ["/home/zero/.config/themes/apply-matugen.sh", cleanPath];
        matugenProc.running = true;

        // Disparar la transición en todas las pantallas
        triggerTransition();
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

                // Imagen actual
                Image {
                    id: imgCurrent
                    anchors.fill: parent
                    source: backgroundScope.currentWallpaper !== "" ? "file://" + backgroundScope.currentWallpaper : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    scale: 1.0
                    opacity: 1.0
                    transformOrigin: Item.Center
                }

                // Siguiente imagen para la animación de transición
                Image {
                    id: imgNext
                    anchors.fill: parent
                    source: backgroundScope.nextWallpaper !== "" ? "file://" + backgroundScope.nextWallpaper : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    scale: 0.88
                    opacity: 0.0
                    transformOrigin: Item.Center

                    onStatusChanged: {
                        if (status === Image.Ready && backgroundScope.isAnimating && !transitionAnim.running) {
                            transitionAnim.restart();
                        }
                    }
                }

                Connections {
                    target: backgroundScope
                    function onTriggerTransition() {
                        if (imgNext.status === Image.Ready) {
                            transitionAnim.restart();
                        }
                    }
                }

                // ── Animación Dinámica Zoom & Blur (Emergence) ───────
                // La imagen saliente escala y se desvanece suavemente.
                // La imagen entrante emerge desde el centro escalando a 1.0
                ParallelAnimation {
                    id: transitionAnim

                    // Outgoing: Zoom Out / Fade Out
                    NumberAnimation {
                        target: imgCurrent
                        property: "scale"
                        from: 1.0
                        to: 1.15
                        duration: 750
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: imgCurrent
                        property: "opacity"
                        from: 1.0
                        to: 0.0
                        duration: 750
                        easing.type: Easing.InOutQuad
                    }

                    // Incoming: Zoom In / Fade In
                    NumberAnimation {
                        target: imgNext
                        property: "scale"
                        from: 0.88
                        to: 1.0
                        duration: 750
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: imgNext
                        property: "opacity"
                        from: 0.0
                        to: 1.0
                        duration: 750
                        easing.type: Easing.InOutQuad
                    }

                    onFinished: {
                        backgroundScope.currentWallpaper = backgroundScope.nextWallpaper;
                        backgroundScope.nextWallpaper = "";
                        backgroundScope.isAnimating = false;

                        imgCurrent.source = "file://" + backgroundScope.currentWallpaper;
                        imgCurrent.scale = 1.0;
                        imgCurrent.opacity = 1.0;

                        imgNext.opacity = 0.0;
                        imgNext.scale = 0.88;
                        imgNext.source = "";
                    }
                }
            }
        }
    }
}
