import json, os, subprocess, sys

d = json.load(open('.flutter-plugins-dependencies', encoding='utf-8'))
plat = sys.argv[1] if len(sys.argv) > 1 else 'linux'
target_dir = plat + '/flutter/ephemeral/.plugin_symlinks'
os.makedirs(target_dir, exist_ok=True)
for p in d['plugins'].get(plat, []):
    name, path = p['name'], p['path'].rstrip('\\/')
    link = os.path.join(target_dir, name)
    if os.path.exists(link):
        print('EXISTS', name)
        continue
    r = subprocess.run(
        ['cmd', '/c', 'mklink', '/J', link.replace('/', '\\'), path.replace('/', '\\')],
        capture_output=True)
    print('LINK', r.returncode, name)