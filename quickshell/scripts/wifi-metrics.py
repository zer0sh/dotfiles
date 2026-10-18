#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys
import time

CACHE_FILE = os.path.expanduser("~/.cache/quickshell/wifi_status.json")

def get_wireless_interface():
    try:
        with open("/proc/net/wireless", "r") as f:
            for line in f:
                parts = line.strip().split(":")
                if len(parts) == 2:
                    return parts[0].strip()
    except Exception:
        pass

    try:
        with open("/proc/net/dev", "r") as f:
            for line in f:
                parts = line.split(":")
                if len(parts) == 2:
                    iface = parts[0].strip()
                    if iface.startswith("wl"):
                        return iface
    except Exception:
        pass
    return "wlp3s0"

def get_transfer_bytes(iface):
    try:
        with open("/proc/net/dev", "r") as f:
            for line in f:
                if iface in line:
                    parts = line.split(":")
                    if len(parts) == 2:
                        cols = parts[1].split()
                        return int(cols[0]), int(cols[8])
    except Exception:
        pass
    return 0, 0

def format_rate(bytes_per_sec):
    if bytes_per_sec >= 1024 * 1024:
        return f"{bytes_per_sec / (1024 * 1024):.1f} MB/s"
    elif bytes_per_sec >= 1024:
        return f"{bytes_per_sec / 1024:.0f} kB/s"
    else:
        return f"{bytes_per_sec:.0f} B/s"

def get_ping():
    try:
        p = subprocess.run(
            ["ping", "-c", "1", "-W", "1", "1.1.1.1"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=1.1
        )
        m = re.search(r"time=([\d\.]+)\s*ms", p.stdout)
        if m:
            return f"{float(m.group(1)):.0f} ms"
    except Exception:
        pass
    return "--"

def get_iw_link_info(iface):
    bitrate = "--"
    dbm = "--"
    try:
        res = subprocess.run(
            ["iw", "dev", iface, "link"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=1.0
        )
        m_bit = re.search(r"tx bitrate:\s*([\d\.]+\s*\S+)", res.stdout)
        if m_bit:
            bitrate = m_bit.group(1)
        m_dbm = re.search(r"signal:\s*(-?\d+)\s*dBm", res.stdout)
        if m_dbm:
            dbm = f"{m_dbm.group(1)} dBm"
    except Exception:
        pass
    return bitrate, dbm

def get_ip_and_range(iface):
    ip_addr = "--"
    ip_range = "--"
    try:
        res = subprocess.run(
            ["ip", "-4", "-o", "addr", "show", "dev", iface],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=1.0
        )
        m = re.search(r"inet\s+([\d\.]+)/(\d+)", res.stdout)
        if m:
            ip_addr = m.group(1)
            ip_range = f"/{m.group(2)}"
    except Exception:
        pass
    return ip_addr, ip_range

def get_connected_info():
    try:
        res = subprocess.run(
            ["nmcli", "-t", "-f", "active,ssid,signal,security", "dev", "wifi"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=1.2
        )
        for line in res.stdout.strip().split("\n"):
            parts = line.split(":")
            if len(parts) >= 4 and parts[0] == "yes":
                ssid = parts[1]
                sig = parts[2]
                sec = ":".join(parts[3:]).strip() or "Open"
                return True, ssid, sig, sec
    except Exception:
        pass
    return False, "", "0", "--"

def main():
    iface = get_wireless_interface()
    rx1, tx1 = get_transfer_bytes(iface)
    time.sleep(0.25)
    rx2, tx2 = get_transfer_bytes(iface)

    dt = 0.25
    rx_speed = (rx2 - rx1) / dt if rx2 >= rx1 else 0
    tx_speed = (tx2 - tx1) / dt if tx2 >= tx1 else 0

    connected, ssid, signal, security = get_connected_info()
    ping_ms = get_ping() if connected else "--"
    bitrate, dbm = get_iw_link_info(iface) if connected else ("--", "--")
    ip_addr, ip_range = get_ip_and_range(iface) if connected else ("--", "--")

    payload = {
        "interface": iface,
        "connected": connected,
        "ssid": ssid,
        "signal": signal,
        "security": security,
        "dbm": dbm,
        "ip": ip_addr,
        "range": ip_range,
        "ping": ping_ms,
        "bitrate": bitrate,
        "rx_rate": format_rate(rx_speed),
        "tx_rate": format_rate(tx_speed)
    }

    try:
        os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
        with open(CACHE_FILE + ".tmp", "w") as f:
            json.dump(payload, f)
        os.replace(CACHE_FILE + ".tmp", CACHE_FILE)
    except Exception:
        pass

    print(json.dumps(payload))

if __name__ == "__main__":
    main()
