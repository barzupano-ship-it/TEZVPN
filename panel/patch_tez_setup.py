from pathlib import Path

path = Path("/root/vpn-panel/webshop.py")
text = path.read_text(encoding="utf-8")
old_file = 'folder / "TEZVPN-Windows.zip", "TEZVPN-Windows.zip"'
new_file = 'folder / "TEZVPN-Setup.exe", "TEZVPN-Setup.exe"'
old_step = 'Windows: <a href="${w}">скачать TEZVPN</a>. Распакуйте архив и откройте TEZVPN.exe'
new_step = 'Windows: <a href="${w}">скачать TEZVPN</a>. Откройте скачанный файл — программа установится сама'
if old_file not in text:
    raise SystemExit("windows file missing")
if old_step not in text:
    raise SystemExit("windows step missing")
text = text.replace(old_file, new_file, 1)
text = text.replace(old_step, new_step, 1)
path.write_text(text, encoding="utf-8")
print("SETUP_PATCHED")
