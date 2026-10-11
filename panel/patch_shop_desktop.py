"""Serve Windows and Mac app downloads from the shop."""
from pathlib import Path

path = Path("/root/vpn-panel/webshop.py")
text = path.read_text(encoding="utf-8")
backup = Path("/root/vpn-panel/webshop.py.bak-desktop")
if not backup.exists():
    backup.write_text(text, encoding="utf-8")

if "pathlib" not in text:
    text = "from pathlib import Path\n" + text

old_links = '''APP_LINKS = {
    "Android": "https://play.google.com/store/apps/details?id=org.amnezia.awg",
    "iPhone / iPad": "https://apps.apple.com/app/amneziawg/id6478942365",
    "Windows": "https://github.com/amnezia-vpn/amneziawg-windows-client/releases/latest",
}
'''
new_links = '''APP_LINKS = {
    "Android": "https://play.google.com/store/apps/details?id=org.amnezia.awg",
    "iPhone / iPad": "https://apps.apple.com/app/amneziawg/id6478942365",
    "Windows": "/download/windows",
    "Mac": "/download/macos",
}
'''
if '"Mac":' not in text.split("APP_LINKS", 1)[1][:400]:
    if old_links not in text:
        raise SystemExit("APP_LINKS missing")
    text = text.replace(old_links, new_links, 1)

old_js = '''const APP = {
  Android: 'https://play.google.com/store/apps/details?id=org.amnezia.awg',
  iOS: 'https://apps.apple.com/app/amneziawg/id6478942365',
  Win: 'https://github.com/amnezia-vpn/amneziawg-windows-client/releases/latest',
};
'''
new_js = '''const APP = {
  Android: 'https://play.google.com/store/apps/details?id=org.amnezia.awg',
  iOS: 'https://apps.apple.com/app/amneziawg/id6478942365',
  Win: '/download/windows',
  Mac: '/download/macos',
};
'''
if "Mac: '/download/macos'" not in text:
    if old_js not in text:
        raise SystemExit("APP js missing")
    text = text.replace(old_js, new_js, 1)

old_how = '''  const w = (APP && APP.Win) || 'https://github.com/amnezia-vpn/amneziawg-windows-client/releases/latest';
  return `<div class="steps">
    <div class="step"><i>1</i><div>Установите <strong>AmneziaWG</strong> (не обычный WireGuard).</div></div>
    <div class="step"><i>2</i><div>Android: <a href="${a}" target="_blank" rel="noopener">Google Play</a></div></div>
    <div class="step"><i>3</i><div>iPhone / iPad: <a href="${i}" target="_blank" rel="noopener">App Store</a></div></div>
    <div class="step"><i>4</i><div>Windows: <a href="${w}" target="_blank" rel="noopener">скачать</a></div></div>
    <div class="step"><i>5</i><div>В приложении «+» → сканируйте QR или импортируйте файл .conf → включите VPN.</div></div>
'''
new_how = '''  const w = (APP && APP.Win) || '/download/windows';
  const mac = (APP && APP.Mac) || '/download/macos';
  return `<div class="steps">
    <div class="step"><i>1</i><div>Установите приложение для своего компьютера или телефона. Это не обычный WireGuard.</div></div>
    <div class="step"><i>2</i><div>Android: <a href="${a}" target="_blank" rel="noopener">Google Play</a></div></div>
    <div class="step"><i>3</i><div>iPhone / iPad: <a href="${i}" target="_blank" rel="noopener">App Store</a></div></div>
    <div class="step"><i>4</i><div>Windows: <a href="${w}">скачать</a></div></div>
    <div class="step"><i>5</i><div>Mac: <a href="${mac}">скачать</a></div></div>
    <div class="step"><i>6</i><div>В приложении «+» → сканируйте QR или импортируйте файл .conf → включите VPN.</div></div>
'''
if "Mac: <a href=" not in text:
    if old_how not in text:
        raise SystemExit("howto missing")
    text = text.replace(old_how, new_how, 1)

old_logo = '''        rest = self.bind_tenant(path)
        if rest is None:
            parts = [p for p in path.split("/") if p]
'''
new_logo = '''        if path in ("/download/windows", "/download/macos"):
            folder = Path("/root/vpn-panel/downloads")
            if path.endswith("windows"):
                f, name = folder / "amneziawg-windows.msi", "amneziawg-windows.msi"
            else:
                f, name = folder / "AmneziaVPN-macOS.pkg", "AmneziaVPN-macOS.pkg"
            if not f.is_file():
                return self.json({"error": "no_file"}, 404)
            size = f.stat().st_size
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Length", str(size))
            self.send_header("Content-Disposition", f'attachment; filename="{name}"')
            self.end_headers()
            with f.open("rb") as fh:
                while True:
                    chunk = fh.read(256 * 1024)
                    if not chunk:
                        break
                    try:
                        self.wfile.write(chunk)
                    except (BrokenPipeError, ConnectionResetError):
                        break
            return

        rest = self.bind_tenant(path)
        if rest is None:
            parts = [p for p in path.split("/") if p]
'''
if 'path in ("/download/windows", "/download/macos")' not in text:
    if text.count(old_logo) != 1:
        raise SystemExit(f"bind count {text.count(old_logo)}")
    text = text.replace(old_logo, new_logo, 1)

if 'path in ("/download/windows", "/download/macos")' not in text or "Mac: <a href=" not in text:
    raise SystemExit("desktop download missing")
path.write_text(text, encoding="utf-8")
print("DESKTOP_PATCHED")
