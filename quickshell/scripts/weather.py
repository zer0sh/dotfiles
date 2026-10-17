#!/usr/bin/env python3
"""
weather.py — Fetches current weather data via OpenWeatherMap API
with local caching and graceful fallback.
"""

import os
import sys
import json
import urllib.request
import urllib.parse

CACHE_FILE = os.path.expanduser("~/.cache/weather.json")
CONFIG_DIR = os.path.expanduser("~/.config/weather")
KEY_FILE = os.path.join(CONFIG_DIR, "api_key")
CITY_FILE = os.path.join(CONFIG_DIR, "city")

DEFAULT_WEATHER = {
    "temp": "20°",
    "city": "Bogotá",
    "condition": "Partly cloudy",
    "icon": "partly_cloudy_day",
    "humidity": "65%",
    "feels_like": "19°"
}

def get_icon(weather_id, is_night=False):
    # OpenWeather condition codes: https://openweathermap.org/weather-conditions
    if 200 <= weather_id < 300:
        return "thunderstorm"
    elif 300 <= weather_id < 600:
        return "rainy"
    elif 600 <= weather_id < 700:
        return "ac_unit"
    elif 700 <= weather_id < 800:
        return "foggy"
    elif weather_id == 800:
        return "bedtime" if is_night else "wb_sunny"
    elif weather_id == 801 or weather_id == 802:
        return "bedtime" if is_night else "partly_cloudy_day"
    elif weather_id >= 803:
        return "cloud"
    return "partly_cloudy_day"

def read_config():
    api_key = os.environ.get("OPENWEATHER_API_KEY", "")
    if not api_key and os.path.exists(KEY_FILE):
        try:
            with open(KEY_FILE, "r") as f:
                api_key = f.read().strip()
        except Exception:
            pass

    city = "Bogota,CO"
    if os.path.exists(CITY_FILE):
        try:
            with open(CITY_FILE, "r") as f:
                c = f.read().strip()
                if c:
                    city = c
        except Exception:
            pass

    return api_key, city

def fetch_openweather(api_key, city):
    encoded_city = urllib.parse.quote(city)
    url = f"https://api.openweathermap.org/data/2.5/weather?q={encoded_city}&appid={api_key}&units=metric&lang=en"
    req = urllib.request.Request(url, headers={"User-Agent": "QuickShell-Weather/1.0"})
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        
    temp = round(data.get("main", {}).get("temp", 20))
    feels_like = round(data.get("main", {}).get("feels_like", temp))
    humidity = data.get("main", {}).get("humidity", 50)
    city_name = data.get("name", city.split(",")[0])
    
    weather_list = data.get("weather", [])
    if weather_list:
        condition = weather_list[0].get("description", "Clear").capitalize()
        weather_id = weather_list[0].get("id", 800)
        icon_code = weather_list[0].get("icon", "01d")
        is_night = icon_code.endswith("n")
        icon = get_icon(weather_id, is_night)
    else:
        condition = "Clear"
        icon = "wb_sunny"

    return {
        "temp": f"{temp}°",
        "city": city_name,
        "condition": condition,
        "icon": icon,
        "humidity": f"{humidity}%",
        "feels_like": f"{feels_like}°"
    }

def main():
    os.makedirs(CONFIG_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)

    api_key, city = read_config()

    result = None
    if api_key:
        try:
            result = fetch_openweather(api_key, city)
            with open(CACHE_FILE, "w") as f:
                json.dump(result, f, indent=2)
        except Exception as e:
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
