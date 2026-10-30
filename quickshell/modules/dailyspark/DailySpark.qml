import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.." as Root

Scope {
    id: dailySpark

    property string currentQuote: "La simplicidad es el requisito previo para la fiabilidad."
    property string currentAuthor: "Edsger W. Dijkstra"
    property string currentCategory: "tecnología"
    property var quotesList: []
    property int currentIndex: 0

    property bool panelVisible: Root.GadgetsManager.isEnabled("dailyspark")
    property int posX: Root.GadgetsManager.getPosition("dailyspark", 560, 720).x
    property int posY: Root.GadgetsManager.getPosition("dailyspark", 560, 720).y

    Connections {
        target: Root.GadgetsManager
        function onStateChanged() {
            dailySpark.panelVisible = Root.GadgetsManager.isEnabled("dailyspark");
            var pos = Root.GadgetsManager.getPosition("dailyspark", 560, 720);
            dailySpark.posX = pos.x;
            dailySpark.posY = pos.y;
        }
    }

    IpcHandler {
        target: "dailyspark"
        function toggle(): void { Root.GadgetsManager.toggle("dailyspark") }
        function show(): void { Root.GadgetsManager.setEnabled("dailyspark", true) }
        function hide(): void { Root.GadgetsManager.setEnabled("dailyspark", false) }
        function next(): void { dailySpark.nextQuote() }
    }

    // Proceso para leer quotes.json
    Process {
        id: readQuotesProc
        command: ["/bin/sh", "-c", "cat ~/.config/quickshell/data/quotes.json 2>/dev/null || cat /home/zero/dotfiles/quickshell/data/quotes.json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim();
                if (raw !== "") {
                    try {
                        var parsed = JSON.parse(raw);
                        if (Array.isArray(parsed) && parsed.length > 0) {
                            dailySpark.quotesList = parsed;
                            dailySpark.pickRandomQuote();
                        }
                    } catch (e) {
                        console.log("[DailySpark] Error al parsear quotes.json:", e);
                    }
                }
            }
        }
    }

    function pickRandomQuote() {
        if (dailySpark.quotesList.length > 0) {
            var idx = Math.floor(Math.random() * dailySpark.quotesList.length);
            dailySpark.currentIndex = idx;
            var item = dailySpark.quotesList[idx];
            dailySpark.currentQuote = item.quote;
            dailySpark.currentAuthor = item.author;
            dailySpark.currentCategory = item.category || "";
        }
    }

    function nextQuote() {
        if (dailySpark.quotesList.length > 0) {
            dailySpark.currentIndex = (dailySpark.currentIndex + 1) % dailySpark.quotesList.length;
            var item = dailySpark.quotesList[dailySpark.currentIndex];
            dailySpark.currentQuote = item.quote;
            dailySpark.currentAuthor = item.author;
            dailySpark.currentCategory = item.category || "";
        }
    }

    // Rotar cada 3 horas
    Timer {
        interval: 10800000
        repeat: true
        running: true
        onTriggered: dailySpark.nextQuote()
    }

    Component.onCompleted: {
        readQuotesProc.running = true;
    }

    PanelWindow {
        id: win
        visible: dailySpark.panelVisible
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:dailyspark"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: mainCard
        }

        // Contenedor principal sin fondo ni bordes — arrastrable directamente
        Item {
            id: mainCard
            x: dailySpark.posX
            y: dailySpark.posY
            width: 480
            height: 160
            property bool isDragging: false

            Binding {
                target: mainCard
                property: "x"
                value: dailySpark.posX
                when: !mainCard.isDragging
            }
            Binding {
                target: mainCard
                property: "y"
                value: dailySpark.posY
                when: !mainCard.isDragging
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)
                drag.target: mainCard
                drag.axis: Drag.XAndYAxis

                onPressed: {
                    mainCard.isDragging = true;
                }

                onReleased: {
                    var fx = Math.round(mainCard.x);
                    var fy = Math.round(mainCard.y);
                    dailySpark.posX = fx;
                    dailySpark.posY = fy;
                    Root.GadgetsManager.setPosition("dailyspark", fx, fy);
                    mainCard.isDragging = false;
                }
            }

            // Botón sutil de cierre al pasar el cursor
            Text {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                z: 100
                text: "✕"
                font.family: Root.Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                color: closeHover.hovered ? Root.Theme.error : Qt.rgba(Root.Theme.textSecondary.r, Root.Theme.textSecondary.g, Root.Theme.textSecondary.b, 0.45)
                opacity: dragArea.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                HoverHandler { id: closeHover }
                TapHandler {
                    onTapped: Root.GadgetsManager.setEnabled("dailyspark", false)
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // Cita
                Text {
                    Layout.fillWidth: true
                    text: "“" + dailySpark.currentQuote + "”"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 15
                    font.italic: true
                    font.weight: Font.Medium
                    color: Root.Theme.textPrimary
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.3
                }

                // Autor y botón de siguiente
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Text {
                        text: "— " + dailySpark.currentAuthor
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Qt.lighter(Root.Theme.primary, 1.2)
                    }

                    // Botón sutil para pasar a otra cita
                    Item {
                        width: 22
                        height: 22
                        visible: dragArea.containsMouse

                        Text {
                            anchors.centerIn: parent
                            text: "󰑐"
                            font.family: Root.Theme.iconFont
                            font.pixelSize: 14
                            color: nextHover.hovered ? Root.Theme.primary : Root.Theme.textSecondary
                        }

                        HoverHandler { id: nextHover }
                        TapHandler {
                            onTapped: dailySpark.nextQuote()
                        }
                    }
                }
            }
        }
    }
}
