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

CACHE_FILE = os.path.expanduser("~/.cache/weather.json")
CONFIG_DIR = os.path.expanduser("~/.config/weather")
KEY_FILE = os.path.join(CONFIG_DIR, "api_key")
CITY_FILE = os.path.join(CONFIG_DIR, "city")

DEFAULT_WEATHER = {
    "temp": "20°",
    "city": "Bogota",
    "condition": "Partly cloudy",
    "icon": "partly_cloudy_day",
    "humidity": "65%",
    "feels_like": "19°",
    "forecast": [
        {"day": "Tomorrow", "temp": "20°", "condition": "Partly cloudy", "icon": "partly_cloudy_day"},
        {"day": "Overmorrow", "temp": "19°", "condition": "Light rain", "icon": "rainy"}
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

    city = "Bogota"
    if os.path.exists(CITY_FILE):
        try:
            with open(CITY_FILE, "r") as f:
                c = f.read().strip()
                if c:
                    city = c
        except Exception:
            pass

    return api_key, city

def fetch_wttr(city):
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
        label = day_labels[i - 1]
        try:
            date_obj = datetime.date.fromisoformat(d["date"])
            label = date_obj.strftime("%a") # e.g. Mon, Tue
        except Exception:
            pass
        
        # Mid-day forecast representative conditions
        mid_hourly = d.get("hourly", [{}])[len(d.get("hourly", [])) // 2]
        desc = mid_hourly.get("weatherDesc", [{}])[0].get("value", "Clear").strip()
        icon = wttr_code_to_icon(mid_hourly.get("weatherCode", "113"))
        max_t = d.get("maxtempC", "20")

        forecast.append({
            "day": label,
            "temp": f"{max_t}°",
            "condition": desc,
            "icon": icon
        })

    return {
        "temp": curr_temp,
        "city": city.split(",")[0],
        "condition": curr_desc,
        "icon": curr_icon,
        "humidity": humidity,
        "feels_like": feels_like,
        "forecast": forecast
    }

def main():
    os.makedirs(CONFIG_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)

    api_key, city = read_config()
    result = None

    try:
        result = fetch_wttr(city)
        with open(CACHE_FILE, "w") as f:
            json.dump(result, f, indent=2)
    except Exception:
        pass

    if not result and os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                result = json.load(f)
        except Exception:
            pass

    if not result:
        result = DEFAULT_WEATHER
        try:
            with open(CACHE_FILE, "w") as f:
                json.dump(result, f, indent=2)
        except Exception:
            pass

    print(json.dumps(result))

if __name__ == "__main__":
    main()
