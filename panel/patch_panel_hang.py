"""Keep a slow TLS handshake from blocking the admin panel."""
from pathlib import Path

path = Path("/root/vpn-panel/panel.py")
text = path.read_text(encoding="utf-8")
backup = Path("/root/vpn-panel/panel.py.bak-hang")
if not backup.exists():
    backup.write_text(text, encoding="utf-8")

old_handler = "class Handler(BaseHTTPRequestHandler):\n"
new_handler = '''class Handler(BaseHTTPRequestHandler):
    timeout = 20

    def setup(self):
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
if "def setup(self):" not in text.split("class Handler", 1)[1][:500]:
    if old_handler not in text:
        raise SystemExit("handler missing")
    text = text.replace(old_handler, new_handler, 1)

old_srv = '''    srv = ThreadingHTTPServer((BIND, PORT), Handler)
    scheme = "http"
    if tls_ready():
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ctx.load_cert_chain(CERT, CERT_KEY)
        ctx.minimum_version = ssl.TLSVersion.TLSv1_2
        srv.socket = ctx.wrap_socket(srv.socket, server_side=True)
        scheme = "https"
'''
new_srv = '''    class PanelServer(ThreadingHTTPServer):
        daemon_threads = True
        request_queue_size = 128
        allow_reuse_address = True

        def handle_error(self, request, client_address):
            import sys
            exc = sys.exc_info()[1]
            if isinstance(exc, (TimeoutError, OSError, ssl.SSLError)):
                return
            super().handle_error(request, client_address)

    srv = PanelServer((BIND, PORT), Handler)
    scheme = "http"
    if tls_ready():
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ctx.load_cert_chain(CERT, CERT_KEY)
        ctx.minimum_version = ssl.TLSVersion.TLSv1_2
        srv.socket = ctx.wrap_socket(
            srv.socket, server_side=True, do_handshake_on_connect=False,
        )
        scheme = "https"
'''
if "do_handshake_on_connect=False" not in text:
    if old_srv not in text:
        raise SystemExit("server start missing")
    text = text.replace(old_srv, new_srv, 1)

if "do_handshake_on_connect=False" not in text or "request_queue_size = 128" not in text:
    raise SystemExit("hang fix missing")
path.write_text(text, encoding="utf-8")
print("HANG_PATCHED")
