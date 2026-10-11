"""Limit simultaneous TLS handshakes so a scan cannot stall the panel."""
from pathlib import Path

path = Path("/root/vpn-panel/panel.py")
text = path.read_text(encoding="utf-8")
backup = Path("/root/vpn-panel/panel.py.bak-guard")
if not backup.exists():
    backup.write_text(text, encoding="utf-8")

old = '''    def setup(self):
        sock = self.request
        import ssl as _ssl
        if isinstance(sock, _ssl.SSLSocket):
            sock.settimeout(self.timeout)
            try:
                sock.do_handshake()
            except (TimeoutError, OSError, _ssl.SSLError):
                try:
                    sock.close()
                except OSError:
                    pass
                raise
        super().setup()
'''
new = '''    def setup(self):
        sock = self.request
        import ssl as _ssl
        if isinstance(sock, _ssl.SSLSocket):
            if not _PANEL_HANDSHAKES.acquire(timeout=5):
                try:
                    sock.close()
                except OSError:
                    pass
                raise TimeoutError("too many handshakes")
            try:
                sock.settimeout(self.timeout)
                try:
                    sock.do_handshake()
                except (TimeoutError, OSError, _ssl.SSLError):
                    try:
                        sock.close()
                    except OSError:
                        pass
                    raise
            finally:
                _PANEL_HANDSHAKES.release()
        super().setup()
'''
if "_PANEL_HANDSHAKES" not in text:
    anchor = "class Handler(BaseHTTPRequestHandler):\n"
    if anchor not in text:
        raise SystemExit("handler missing")
    text = text.replace(
        anchor,
        "import threading\n_PANEL_HANDSHAKES = threading.BoundedSemaphore(40)\n\n" + anchor,
        1,
    )
if old not in text:
    if "_PANEL_HANDSHAKES.acquire" not in text:
        raise SystemExit("setup missing")
else:
    text = text.replace(old, new, 1)
if "_PANEL_HANDSHAKES.acquire" not in text:
    raise SystemExit("guard missing")
path.write_text(text, encoding="utf-8")
print("GUARD_PATCHED")
