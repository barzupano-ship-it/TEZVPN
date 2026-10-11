"""Keep the public page as a single download window."""
from pathlib import Path

path = Path("/root/vpn-panel/webshop.py")
text = path.read_text(encoding="utf-8")
start = text.find("def landing_html(")
end = text.find("\ndef app_html(", start)
if start < 0 or end < 0:
    raise SystemExit(f"landing block missing {start} {end}")
fn = '''def landing_html(lang: str = "ru") -> bytes:
    android = APP_LINKS["Android"]
    ios = APP_LINKS["iPhone / iPad"]
    body = f"""<!DOCTYPE html>
<html lang="ru"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0c2438">
<link rel="icon" type="image/png" href="/logo.png">
<title>TEZVPN — скачать</title>
<style>
:root {{ --navy:#0c2438; --card:#16324f; --gold:#f5c518; --text:#f4f7fb; }}
* {{ box-sizing:border-box; }}
body {{ margin:0; min-height:100vh; display:flex; align-items:center; justify-content:center;
  padding:24px 16px; color:var(--text); font-family:Segoe UI,system-ui,sans-serif;
  background:radial-gradient(900px 420px at 50% -10%, #1a4468, var(--navy)); }}
.box {{ width:min(420px, 100%); background:#122c44; border:1px solid rgba(255,255,255,.08);
  border-radius:22px; padding:28px 22px 22px; text-align:center;
  box-shadow:0 24px 60px rgba(0,0,0,.28); }}
img {{ height:56px; width:auto; }}
h1 {{ margin:14px 0 18px; font-size:28px; }}
a.dl {{ display:block; text-decoration:none; border-radius:14px; padding:14px 16px; margin-top:10px;
  background:var(--card); color:#fff; font-weight:800; font-size:17px; }}
a.dl.win {{ background:var(--gold); color:#111; }}
</style>
</head><body>
<div class="box">
  <img src="/logo.png" alt="TEZVPN">
  <h1>Скачать</h1>
  <a class="dl win" href="/download/windows">Windows</a>
  <a class="dl" href="/download/macos">Mac</a>
  <a class="dl" href="{esc(android)}" target="_blank" rel="noopener">Android</a>
  <a class="dl" href="{esc(ios)}" target="_blank" rel="noopener">iPhone</a>
</div>
</body></html>"""
    return body.encode()


'''
text = text[:start] + fn + text[end + 1 :]
if "Купить доступ" in text[start:start + len(fn)]:
    raise SystemExit("buy button still in landing")
path.write_text(text, encoding="utf-8")
print("LANDING_ONLY")
