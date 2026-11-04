#!/usr/bin/env python3
"""
weather.py — Fetches current weather and 3-day forecast with local caching.
Supports wttr.in (no API key needed) and OpenWeatherMap fallback.
Outputs structured JSON for Quickshell widgets and gadgets.
"""

import os
import sys
import json
import datetime
import urllib.request
import urllib.parse
import unicodedata

CACHE_FILE = os.path.expanduser("~/.cache/weather.json")
CONFIG_DIR = os.path.expanduser("~/.config/weather")
KEY_FILE = os.path.join(CONFIG_DIR, "api_key")
CITY_FILE = os.path.join(CONFIG_DIR, "city")
LABEL_FILE = os.path.join(CONFIG_DIR, "label")

DEFAULT_WEATHER = {
    "temp": "25°",
    "city": "Cali",
    "real_location": "Cali,Colombia",
    "custom_label": "",
    "display_city": "Cali",
    "condition": "Partly cloudy",
    "icon": "partly_cloudy_day",
    "humidity": "75%",
    "feels_like": "26°",
    "forecast": [
        {"day": "Tomorrow", "temp": "28°", "condition": "Partly cloudy", "icon": "partly_cloudy_day"},
        {"day": "Overmorrow", "temp": "27°", "condition": "Light rain", "icon": "rainy"}
    ]
}

def wttr_code_to_icon(code_str):
    try:
        code = int(code_str)
    except Exception:
        return "partly_cloudy_day"
    
    # Standard WWO / wttr.in weather codes
    if code in (113,): # Sunny / Clear
        return "wb_sunny"
    elif code in (116,): # Partly Cloudy
        return "partly_cloudy_day"
    elif code in (119, 122): # Cloudy, Overcast
        return "cloud"
    elif code in (143, 248, 260): # Mist, Fog
        return "foggy"
    elif code in (176, 263, 266, 293, 296, 299, 302, 305, 308, 353, 356, 359): # Rain
        return "rainy"
    elif code in (200, 386, 389, 392, 395): # Thunderstorm
        return "thunderstorm"
    elif code in (179, 182, 185, 227, 230, 281, 284, 311, 314, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377): # Snow / Ice
        return "ac_unit"
    return "partly_cloudy_day"

def read_config():
    api_key = os.environ.get("OPENWEATHER_API_KEY", "")
    if not api_key and os.path.exists(KEY_FILE):
        try:
            with open(KEY_FILE, "r") as f:
                api_key = f.read().strip()
        except Exception:
            pass

    city = "Cali,Colombia"
    if os.path.exists(CITY_FILE):
        try:
            with open(CITY_FILE, "r") as f:
                c = f.read().strip()
                if c:
                    city = c
        except Exception:
            pass

    label = ""
    if os.path.exists(LABEL_FILE):
        try:
            with open(LABEL_FILE, "r") as f:
                label = f.read().strip()
        except Exception:
            pass

    return api_key, city, label

def fetch_wttr(city, label=""):
    encoded_city = urllib.parse.quote(city)
    url = f"https://wttr.in/{encoded_city}?format=j1"
    req = urllib.request.Request(url, headers={"User-Agent": "curl/7.68.0"})
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode("utf-8"))

    curr = data["current_condition"][0]
    curr_temp = f"{curr.get('temp_C', '20')}°"
    feels_like = f"{curr.get('FeelsLikeC', curr.get('temp_C', '20'))}°"
    humidity = f"{curr.get('humidity', '60')}%"
    curr_desc = curr.get("weatherDesc", [{}])[0].get("value", "Partly cloudy").strip()
    curr_icon = wttr_code_to_icon(curr.get("weatherCode", "116"))

    forecast = []
    days = data.get("weather", [])
    day_labels = ["Tomorrow", "Overmorrow"]

    for i in range(1, min(3, len(days))):
        d = days[i]
        label_day = day_labels[i - 1]
        try:
            date_obj = datetime.date.fromisoformat(d["date"])
            label_day = date_obj.strftime("%a") # e.g. Mon, Tue
        except Exception:
            pass
        
        # Mid-day forecast representative conditions
        mid_hourly = d.get("hourly", [{}])[len(d.get("hourly", [])) // 2]
        desc = mid_hourly.get("weatherDesc", [{}])[0].get("value", "Clear").strip()
        icon = wttr_code_to_icon(mid_hourly.get("weatherCode", "113"))
        max_t = d.get("maxtempC", "20")

        forecast.append({
            "day": label_day,
            "temp": f"{max_t}°",
            "condition": desc,
            "icon": icon
        })

    display_city = label.strip() if label.strip() else city.split(",")[0].strip()

    return {
        "temp": curr_temp,
        "city": city.split(",")[0].strip(),
        "real_location": city.strip(),
        "custom_label": label.strip(),
        "display_city": display_city,
        "condition": curr_desc,
        "icon": curr_icon,
        "humidity": humidity,
        "feels_like": feels_like,
        "forecast": forecast
    }

def clean_ascii(s):
    return ''.join(c for c in unicodedata.normalize('NFKD', s) if not unicodedata.combining(c))

def search_cities(q):
    if not q or len(q.strip()) < 2:
        return []
    url = f"https://geocoding-api.open-meteo.com/v1/search?name={urllib.parse.quote(q.strip())}&count=6&format=json"
    req = urllib.request.Request(url, headers={"User-Agent": "curl/7.68.0"})
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            results = []
            seen = set()
            for r in data.get("results", []):
                name = r.get("name", "")
                admin1 = r.get("admin1", "")
                country = r.get("country", "")
                query = f"{clean_ascii(name)},{clean_ascii(country)}" if country else clean_ascii(name)
                dedup = (name.lower(), admin1.lower(), country.lower())
                if dedup in seen:
                    continue
                seen.add(dedup)
                desc_parts = []
                if admin1 and admin1.lower() != name.lower():
                    desc_parts.append(admin1)
                if country:
                    desc_parts.append(country)
                display_ctx = ", ".join(desc_parts)
                results.append({
                    "name": name,
                    "country": country,
                    "admin1": admin1,
                    "query": query,
                    "display": display_ctx if display_ctx else name
                })
            return results
    except Exception:
        return []

def main():
    os.makedirs(CONFIG_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)

    # CLI parameter overrides:
    # --search <query>
    # --set-city <city>
    # --set-label <label>
    args = sys.argv[1:]
    new_city = None
    new_label = None

    i = 0
    while i < len(args):
        if args[i] == "--search" and i + 1 < len(args):
            results = search_cities(args[i + 1])
            print(json.dumps(results))
            sys.exit(0)
        elif args[i] == "--set-city" and i + 1 < len(args):
            new_city = args[i + 1].strip()
            i += 2
        elif args[i] == "--set-label" and i + 1 < len(args):
            new_label = args[i + 1].strip()
            i += 2
        else:
            i += 1

    api_key, current_city, current_label = read_config()

    target_city = new_city if new_city is not None else current_city
    target_label = new_label if new_label is not None else current_label

    result = None
    location_error = None

    # If setting a new city, validate it first by querying
    if target_city:
        try:
            result = fetch_wttr(target_city, target_label)
            # Fetch succeeded: persist configuration
            with open(CITY_FILE, "w") as f:
                f.write(target_city)
            if new_label is not None:
                with open(LABEL_FILE, "w") as f:
                    f.write(target_label)

            with open(CACHE_FILE, "w") as f:
                json.dump(result, f, indent=2)
        except urllib.error.HTTPError as he:
            location_error = f"Location not found ({he.code})"
        except Exception as e:
            location_error = f"Fetch failed: {str(e)}"

    if location_error:
        # If city was specifically set but failed to be found, return error
        if new_city is not None:
            # Still update label if provided
            if new_label is not None:
                with open(LABEL_FILE, "w") as f:
                    f.write(target_label)

            err_payload = {
                "success": False,
                "error": "Location not found. Please check the spelling or format (e.g. City,Country).",
                "attempted_city": new_city,
                "detail": location_error
            }
            print(json.dumps(err_payload), file=sys.stderr)
            sys.exit(2)

    # Fallback to existing cache if available
    if not result and os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                result = json.load(f)
                if result:
                    result["real_location"] = current_city.strip()
                    result["custom_label"] = target_label.strip()
                    result["display_city"] = target_label.strip() if target_label.strip() else result.get("city", current_city.split(",")[0].strip())
        except Exception:
            pass

    if not result:
        result = dict(DEFAULT_WEATHER)
        result["real_location"] = target_city.strip()
        result["custom_label"] = target_label.strip()
        result["display_city"] = target_label.strip() if target_label.strip() else target_city.split(",")[0].strip()
        try:
            with open(CACHE_FILE, "w") as f:
                json.dump(result, f, indent=2)
        except Exception:
            pass

    print(json.dumps(result))

if __name__ == "__main__":
    main()
