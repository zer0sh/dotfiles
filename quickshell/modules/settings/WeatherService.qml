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

    property var searchResults: []
    property bool isSearching: false

    signal weatherUpdated()

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
                weatherService.statusMessage = "Location updated";
                weatherService.weatherUpdated();
            } else if (code === 2) {
                weatherService.isError = true;
                weatherService.statusMessage = "";
                try {
                    var parsed = JSON.parse(errCollector.text.trim());
                    weatherService.errorMessage = parsed.error || "Location not found";
                } catch (e) {
                    weatherService.errorMessage = "Location not found";
                }
            } else {
                weatherService.isError = true;
                weatherService.statusMessage = "";
                weatherService.errorMessage = "Connection error";
            }
        }
    }

    function saveLocation(newRealLoc, newCustomLabel) {
        weatherService.isSaving = true;
        weatherService.isError = false;
        weatherService.errorMessage = "";
        weatherService.statusMessage = "Saving...";

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
            weatherService.statusMessage = "Updating...";
            saveProc.command = ["/home/zero/.config/quickshell/scripts/weather.py"];
            saveProc.running = true;
        }
    }

    property Process searchProc: Process {
        id: searchProc
        stdout: StdioCollector {
            onStreamFinished: {
                weatherService.isSearching = false;
                try {
                    weatherService.searchResults = JSON.parse(text.trim());
                } catch (e) {
                    weatherService.searchResults = [];
                }
            }
        }
        onExited: (code) => {
            weatherService.isSearching = false;
            if (code !== 0) weatherService.searchResults = [];
        }
    }

    function search(query) {
        var q = (query || "").trim();
        if (q.length < 2) {
            weatherService.searchResults = [];
            weatherService.isSearching = false;
            return;
        }
        weatherService.isSearching = true;
        searchProc.command = [
            "/home/zero/.config/quickshell/scripts/weather.py",
            "--search", q
        ];
        searchProc.running = true;
    }

    function clearSearch() {
        weatherService.searchResults = [];
        weatherService.isSearching = false;
    }
}
