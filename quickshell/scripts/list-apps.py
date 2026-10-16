#!/usr/bin/env python3
import glob
import os
import configparser
import json

def get_installed_apps():
    apps = []
    seen = set()
    dirs = [
        os.path.expanduser('~/.local/share/applications'),
        '/usr/local/share/applications',
        '/usr/share/applications',
        '/var/lib/flatpak/exports/share/applications',
        os.path.expanduser('~/.local/share/flatpak/exports/share/applications')
    ]

    for d in dirs:
        if not os.path.isdir(d):
            continue
        for f in sorted(glob.glob(os.path.join(d, '*.desktop'))):
            try:
                cp = configparser.ConfigParser(interpolation=None)
                cp.read(f, encoding='utf-8')
                if 'Desktop Entry' in cp:
                    sec = cp['Desktop Entry']
                    if sec.getboolean('NoDisplay', fallback=False):
                        continue
                    name = sec.get('Name', '').strip()
                    if not name or name in seen:
                        continue
                    icon = sec.get('Icon', '').strip()
                    exec_cmd = sec.get('Exec', '').strip()
                    comment = sec.get('Comment', sec.get('GenericName', '')).strip()
                    if name and exec_cmd:
                        seen.add(name)
                        apps.append({
                            'name': name,
                            'icon': icon,
                            'comment': comment,
                            'exec': exec_cmd
                        })
            except Exception:
                pass

    apps.sort(key=lambda x: x['name'].lower())
    return apps

if __name__ == '__main__':
    print(json.dumps(get_installed_apps()))
