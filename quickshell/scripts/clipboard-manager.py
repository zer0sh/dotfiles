#!/usr/bin/env python3
"""
clipboard-manager.py — High-performance clipboard controller for Quickshell.
Supports text and image caching, instant search, copy, and per-item deletion.
"""

import sys
import os
import json
import subprocess
import re

THUMB_DIR = "/tmp/cliphist-thumbs"

def ensure_thumb_dir():
    if not os.path.exists(THUMB_DIR):
        try:
            os.makedirs(THUMB_DIR, exist_ok=True)
        except Exception:
            pass

def is_image_data(data: bytes) -> bool:
    if data.startswith(b"\x89PNG") or data.startswith(b"\xff\xd8\xff") or data.startswith(b"GIF8"):
        return True
    if b"[[ binary data" in data:
        return True
    return False

def list_items(query: str = "", limit: int = 50):
    ensure_thumb_dir()
    try:
        proc = subprocess.Popen(["cliphist", "list"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        stdout, _ = proc.communicate(timeout=3)
    except Exception as e:
        print(json.dumps([]))
        return

    items = []
    lines = stdout.split(b"\n")
    query_lower = query.lower().strip()

    for line in lines:
        if not line:
            continue
        idx = line.find(b"\t")
        if idx < 0:
            continue

        cid = line[:idx].decode("utf-8", errors="ignore").strip()
        raw_content = line[idx+1:]
        if not raw_content.strip():
            continue

        is_img = is_image_data(raw_content)
        thumb_path = ""
        preview = ""

        if is_img:
            thumb_path = os.path.join(THUMB_DIR, f"{cid}.png")
            if not os.path.exists(thumb_path) or os.path.getsize(thumb_path) == 0:
                try:
                    dec = subprocess.run(["cliphist", "decode", cid], capture_output=True, timeout=2)
                    if dec.returncode == 0 and dec.stdout:
                        with open(thumb_path, "wb") as f:
                            f.write(dec.stdout)
                except Exception:
                    pass

            # Detect format / dimensions if present in binary data string
            decoded_text = raw_content.decode("utf-8", errors="ignore")
            dim_match = re.search(r"(\d+x\d+)", decoded_text)
            if dim_match:
                preview = f"Image ({dim_match.group(1)})"
            else:
                preview = "Image (PNG / Screenshot)"
        else:
            preview = raw_content.decode("utf-8", errors="replace").replace("\t", " ").strip()
            # Collapse multiple spaces and newlines for clean display
            preview = " ".join(preview.split())

        if query_lower:
            if query_lower not in preview.lower():
                continue

        items.append({
            "id": cid,
            "preview": preview,
            "is_image": is_img,
            "thumb": f"file://{thumb_path}" if is_img and os.path.exists(thumb_path) else ""
        })

        if len(items) >= limit:
            break

    print(json.dumps(items))

def copy_item(cid: str):
    try:
        dec = subprocess.Popen(["cliphist", "decode", cid], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        wl = subprocess.Popen(["wl-copy"], stdin=dec.stdout, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        dec.stdout.close()
        wl.communicate(timeout=2)
        subprocess.run(["/usr/bin/notify-send", "Clipboard", "Copied to clipboard"], check=False)
        print(json.dumps({"success": True}))
    except Exception as e:
        print(json.dumps({"success": False, "error": str(e)}))

def delete_item(cid: str):
    ensure_thumb_dir()
    try:
        proc = subprocess.Popen(["cliphist", "list"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        stdout, _ = proc.communicate(timeout=3)
        target_line = None
        target_prefix = f"{cid}\t".encode("utf-8")
        for line in stdout.split(b"\n"):
            if line.startswith(target_prefix):
                target_line = line
                break

        if target_line:
            d = subprocess.Popen(["cliphist", "delete"], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            d.communicate(target_line + b"\n", timeout=2)

        thumb = os.path.join(THUMB_DIR, f"{cid}.png")
        if os.path.exists(thumb):
            try:
                os.remove(thumb)
            except Exception:
                pass

        print(json.dumps({"success": True}))
    except Exception as e:
        print(json.dumps({"success": False, "error": str(e)}))

def wipe_all():
    try:
        subprocess.run(["cliphist", "wipe"], check=False, timeout=3)
        if os.path.exists(THUMB_DIR):
            for f in os.listdir(THUMB_DIR):
                try:
                    os.remove(os.path.join(THUMB_DIR, f))
                except Exception:
                    pass
        print(json.dumps({"success": True}))
    except Exception as e:
        print(json.dumps({"success": False, "error": str(e)}))

def main():
    if len(sys.argv) < 2:
        list_items()
        return

    cmd = sys.argv[1]
    if cmd == "list":
        query = sys.argv[2] if len(sys.argv) > 2 else ""
        limit = int(sys.argv[3]) if len(sys.argv) > 3 else 50
        list_items(query, limit)
    elif cmd == "copy":
        if len(sys.argv) > 2:
            copy_item(sys.argv[2])
    elif cmd == "delete":
        if len(sys.argv) > 2:
            delete_item(sys.argv[2])
    elif cmd == "wipe":
        wipe_all()
    else:
        list_items()

if __name__ == "__main__":
    main()
