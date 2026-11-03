#!/usr/bin/env python3

import sys
import os
import signal
import time
import subprocess
import glob
import ctypes
from datetime import datetime

libc = ctypes.CDLL("libc.so.6")
PR_SET_PDEATHSIG = 1

def set_pdeathsig():
    libc.prctl(PR_SET_PDEATHSIG, signal.SIGTERM)

PREVIEW_FILE = "/tmp/qs-camera-preview.jpg"
PREVIEW_TMP = "/tmp/qs-camera-preview.tmp"

def get_default_device() -> str:
    for dev in sorted(glob.glob("/dev/video*")):
        name_path = f"/sys/class/video4linux/{os.path.basename(dev)}/name"
        try:
            if os.path.exists(name_path):
                with open(name_path, "r", encoding="utf-8", errors="ignore") as f:
                    name = f.read().lower()
                    if "ir" in name or "infra" in name:
                        continue
        except Exception:
            pass
        return dev
    return "/dev/video0"

def stream(device: str = None):
    dev = device or get_default_device()
    cmd = [
        "ffmpeg",
        "-loglevel", "error",
        "-y",
        "-f", "v4l2",
        "-framerate", "20",
        "-video_size", "640x360",
        "-i", dev,
        "-f", "image2pipe",
        "-vcodec", "mjpeg",
        "-q:v", "4",
        "-"
    ]

    p = None

    try:
        p = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            bufsize=10**6,
            preexec_fn=set_pdeathsig
        )
    except Exception as e:
        sys.stderr.write(f"Failed to start ffmpeg: {e}\n")
        sys.exit(1)

    def cleanup(signum=None, frame=None):
        nonlocal p
        if p and p.poll() is None:
            try:
                p.terminate()
                p.wait(timeout=0.5)
            except Exception:
                try:
                    p.kill()
                except Exception:
                    pass
        try:
            if os.path.exists(PREVIEW_TMP):
                os.remove(PREVIEW_TMP)
            if os.path.exists(PREVIEW_FILE):
                os.remove(PREVIEW_FILE)
        except Exception:
            pass
        sys.exit(0)

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    buf = bytearray()
    while True:
        try:
            chunk = p.stdout.read(4096)
            if not chunk:
                break
            buf.extend(chunk)

            while True:
                start = buf.find(b"\xff\xd8")
                if start == -1:
                    buf.clear()
                    break
                end = buf.find(b"\xff\xd9", start + 2)
                if end == -1:
                    if start > 0:
                        del buf[:start]
                    break
                frame_bytes = buf[start:end + 2]
                del buf[:end + 2]

                try:
                    with open(PREVIEW_TMP, "wb") as f:
                        f.write(frame_bytes)
                    os.replace(PREVIEW_TMP, PREVIEW_FILE)
                except Exception:
                    pass
        except KeyboardInterrupt:
            break
        except Exception:
            break

    cleanup()

def snapshot(device: str = None):
    save_dir = os.path.expanduser("~/Pictures/Camera")
    os.makedirs(save_dir, exist_ok=True)
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    target_path = os.path.join(save_dir, f"camera_{timestamp}.jpg")

    if os.path.exists(PREVIEW_FILE) and os.path.getsize(PREVIEW_FILE) > 1000:
        try:
            import shutil
            shutil.copy2(PREVIEW_FILE, target_path)
            print(target_path)
            notify(target_path)
            return
        except Exception:
            pass

    dev = device or get_default_device()
    cmd = [
        "ffmpeg",
        "-loglevel", "error",
        "-y",
        "-f", "v4l2",
        "-video_size", "1280x720",
        "-i", dev,
        "-vframes", "1",
        target_path
    ]
    try:
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=4)
        if os.path.exists(target_path):
            print(target_path)
            notify(target_path)
    except Exception as e:
        sys.stderr.write(f"Snapshot error: {e}\n")

def notify(file_path: str):
    try:
        subprocess.run([
            "notify-send",
            "-a", "Camera Preview",
            "-i", file_path,
            "Photo Captured",
            f"Saved to {os.path.basename(file_path)}"
        ], timeout=2)
    except Exception:
        pass

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "stream"
    dev = sys.argv[2] if len(sys.argv) > 2 else None
    if action == "stream":
        stream(dev)
    elif action == "snapshot":
        snapshot(dev)
    else:
        print("Usage: camera-preview.py [stream|snapshot] [device]")
