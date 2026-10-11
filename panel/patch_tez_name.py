from pathlib import Path

path = Path("/root/vpn-panel/webshop.py")
text = path.read_text(encoding="utf-8")
old_file = 'folder / "amneziawg-windows.msi", "amneziawg-windows.msi"'
new_file = 'folder / "TEZVPN-Windows.zip", "TEZVPN-Windows.zip"'
old_step = 'Windows: <a href="${w}">скачать</a>'
new_step = 'Windows: <a href="${w}">скачать TEZVPN</a>. Распакуйте архив и откройте TEZVPN.exe'
if old_file not in text and new_file not in text:
    raise SystemExit("windows file missing")
if old_file in text:
    text = text.replace(old_file, new_file, 1)
if old_step not in text and "скачать TEZVPN" not in text:
    raise SystemExit("windows step missing")
if old_step in text:
    text = text.replace(old_step, new_step, 1)
path.write_text(text, encoding="utf-8")
print("TEZ_NAMED")
