pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: weatherService

    property string realLocation: "Cali,Colombia"
    property string customLabel: ""
    readonly property string displayLocation: customLabel.trim() !== "" 
        ? customLabel.trim() 
        : (realLocation.indexOf(",") !== -1 ? realLocation.split(",")[0].trim() : realLocation.trim())

    property bool isSaving: false
    property bool isError: false
    property string statusMessage: ""
    property string errorMessage: ""

    signal weatherUpdated()

    // Popular preset locations for 1-click selection
    readonly property var popularLocations: [
        { name: "Cali", country: "Colombia", query: "Cali,Colombia" },
        { name: "Bogota", country: "Colombia", query: "Bogota,Colombia" },
        { name: "Medellin", country: "Colombia", query: "Medellin,Colombia" },
        { name: "Madrid", country: "Spain", query: "Madrid,Spain" },
        { name: "London", country: "United Kingdom", query: "London,UK" },
        { name: "New York", country: "United States", query: "New York,US" },
        { name: "Tokyo", country: "Japan", query: "Tokyo,Japan" },
        { name: "Paris", country: "France", query: "Paris,France" },
        { name: "Berlin", country: "Germany", query: "Berlin,Germany" },
        { name: "Buenos Aires", country: "Argentina", query: "Buenos Aires,Argentina" },
        { name: "Mexico City", country: "Mexico", query: "Mexico City,Mexico" }
    ]

    // Fast zero-delay file reading
    property FileView cityFile: FileView {
        path: "/home/zero/.config/weather/city"
        blockLoading: true
        onLoaded: {
            var val = text().trim();
            if (val !== "") weatherService.realLocation = val;
        }
    }

    property FileView labelFile: FileView {
        path: "/home/zero/.config/weather/label"
        blockLoading: true
        onLoaded: {
            weatherService.customLabel = text().trim();
        }
    }

    property Process saveProc: Process {
        id: saveProc
        stderr: StdioCollector {
            id: errCollector
        }
        onExited: (code) => {
            weatherService.isSaving = false;
            if (code === 0) {
                weatherService.isError = false;
                weatherService.errorMessage = "";
                weatherService.statusMessage = "Location updated successfully";
                weatherService.weatherUpdated();
            } else if (code === 2) {
                weatherService.isError = true;
                weatherService.statusMessage = "";
                try {
                    var parsed = JSON.parse(errCollector.text.trim());
                    weatherService.errorMessage = parsed.error || "Location not found. Please check spelling.";
                } catch (e) {
                    weatherService.errorMessage = "Location not found. Please check spelling or use 'City,Country'.";
                }
            } else {
                weatherService.isError = true;
                weatherService.statusMessage = "";
                weatherService.errorMessage = "Network or service connection error. Please try again.";
            }
        }
    }

    function saveLocation(newRealLoc, newCustomLabel) {
        weatherService.isSaving = true;
        weatherService.isError = false;
        weatherService.errorMessage = "";
        weatherService.statusMessage = "Validating location...";

        var cleanReal = (newRealLoc !== undefined && newRealLoc !== null) ? newRealLoc.trim() : "";
        if (cleanReal === "") cleanReal = "Cali,Colombia";

        var cleanLabel = (newCustomLabel !== undefined && newCustomLabel !== null) ? newCustomLabel.trim() : "";

        weatherService.customLabel = cleanLabel;

        saveProc.command = [
            "/home/zero/.config/quickshell/scripts/weather.py",
            "--set-city", cleanReal,
            "--set-label", cleanLabel
        ];
        saveProc.running = true;
    }

    function refreshNow() {
        if (!saveProc.running) {
            weatherService.isSaving = true;
            weatherService.isError = false;
            weatherService.errorMessage = "";
            weatherService.statusMessage = "Refreshing forecast...";
            saveProc.command = ["/home/zero/.config/quickshell/scripts/weather.py"];
            saveProc.running = true;
        }
    }
}
