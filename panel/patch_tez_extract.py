from pathlib import Path
path = Path("/root/vpn-panel/webshop.py")
text = path.read_text(encoding="utf-8")
old = 'Windows: <a href="${w}">скачать TEZVPN</a>. Распакуйте архив и откройте TEZVPN.exe'
new = 'Windows: <a href="${w}">скачать TEZVPN</a>. Извлеките весь архив, откройте папку TEZVPN и запустите TEZVPN.exe'
if old not in text:
    if new in text:
        print("ALREADY")
    else:
        raise SystemExit("step missing")
else:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("STEP_OK")
