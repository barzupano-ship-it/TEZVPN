"""Public download landing at /. The shop stays at /shop."""
from pathlib import Path

path = Path("/root/vpn-panel/webshop.py")
text = path.read_text(encoding="utf-8")
backup = Path("/root/vpn-panel/webshop.py.bak-landing")
if not backup.exists():
    backup.write_text(text, encoding="utf-8")

landing_fn = '''def landing_html(lang: str = "ru") -> bytes:
    lang = i18n.normalize(lang)
    en = lang == "en"
    title = "TEZVPN"
    android = APP_LINKS["Android"]
    ios = APP_LINKS["iPhone / iPad"]
    if en:
        lead = "Download the app for your computer or phone. One paid access works on 3 devices."
        win_sub = "Download TEZVPN"
        mac_sub = "Download for Mac"
        buy = "Buy access"
        note = (
            "Open the downloaded file and the program installs itself. "
            "If Windows says the publisher is unknown, choose Run anyway. "
            "On each device open the account. Do not forward the same QR."
        )
        tg = "Message on Telegram"
        page_title = "TEZVPN — download"
    else:
        lead = "Скачайте приложение для компьютера или телефона. Один оплаченный доступ работает на 3 устройствах."
        win_sub = "Скачать TEZVPN"
        mac_sub = "Скачать для Mac"
        buy = "Купить доступ"
        note = (
            "Откройте скачанный файл — программа установится сама. "
            "Если Windows пишет про неизвестного издателя, нажмите «Выполнить в любом случае». "
            "На каждом устройстве откройте кабинет и не пересылайте один и тот же QR."
        )
        tg = "Написать в Telegram"
        page_title = "TEZVPN — скачать"
    ru_on = "" if en else " on"
    en_on = " on" if en else ""
    body = f"""<!DOCTYPE html>
<html lang="{esc(lang)}"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0c2438">
<meta name="description" content="{esc(lead)}">
<link rel="icon" type="image/png" href="/logo.png">
<title>{esc(page_title)}</title>
<style>
:root {{ --navy:#0c2438; --card:#16324f; --gold:#f5c518; --text:#f4f7fb; --muted:#9db0c3; }}
* {{ box-sizing:border-box; }}
body {{ margin:0; min-height:100vh; color:var(--text);
  font-family:Segoe UI,system-ui,sans-serif;
  background:radial-gradient(1000px 420px at 50% -10%, #1a4468, var(--navy)); }}
.wrap {{ max-width:880px; margin:0 auto; padding:28px 18px 56px; }}
header {{ display:flex; align-items:center; gap:12px; }}
header img {{ height:52px; width:auto; }}
.lang {{ margin-left:auto; display:flex; gap:6px; }}
.lang a {{ color:#fff; text-decoration:none; padding:6px 10px; border-radius:999px; }}
.lang a.on {{ background:var(--gold); color:#111; font-weight:800; }}
h1 {{ font-size:clamp(34px,6vw,52px); margin:28px 0 8px; letter-spacing:-.03em; }}
.lead {{ color:var(--muted); font-size:18px; line-height:1.45; max-width:38em; margin:0; }}
.grid {{ display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-top:28px; }}
a.dl {{ display:block; background:var(--card); color:#fff; text-decoration:none;
  border-radius:16px; padding:18px; border:1px solid rgba(255,255,255,.08); }}
a.dl strong {{ display:block; font-size:18px; margin-bottom:4px; }}
a.dl span {{ color:var(--muted); font-size:14px; }}
a.dl.win {{ background:var(--gold); color:#111; }}
a.dl.win span {{ color:#3d340c; }}
a.shop {{ display:inline-block; margin-top:18px; color:#111; background:var(--gold);
  border-radius:12px; padding:12px 18px; text-decoration:none; font-weight:800; }}
.note {{ margin-top:22px; color:var(--muted); font-size:14px; line-height:1.55; max-width:42em; }}
.note a {{ color:#8ec5ff; }}
@media (max-width:640px) {{ .grid {{ grid-template-columns:1fr; }} }}
</style>
</head><body>
<div class="wrap">
  <header>
    <img src="/logo.png" alt="{esc(title)}">
    <span class="lang" aria-label="Language">
      <a class="{ru_on.strip()}" href="/lang/ru?next=/">RU</a>
      <a class="{en_on.strip()}" href="/lang/en?next=/">EN</a>
    </span>
  </header>
  <h1>{esc(title)}</h1>
  <p class="lead">{esc(lead)}</p>
  <div class="grid">
    <a class="dl win" href="/download/windows"><strong>Windows</strong><span>{esc(win_sub)}</span></a>
    <a class="dl" href="/download/macos"><strong>Mac</strong><span>{esc(mac_sub)}</span></a>
    <a class="dl" href="{esc(android)}" target="_blank" rel="noopener"><strong>Android</strong><span>Google Play</span></a>
    <a class="dl" href="{esc(ios)}" target="_blank" rel="noopener"><strong>iPhone</strong><span>App Store</span></a>
  </div>
  <a class="shop" href="/shop">{esc(buy)}</a>
  <p class="note">{esc(note)}</p>
  <p class="note"><a href="https://t.me/{esc(BOT_USER)}" target="_blank" rel="noopener">{esc(tg)}</a></p>
</div>
</body></html>"""
    return body.encode()


'''

if "def landing_html(" not in text:
    anchor = "def app_html("
    if text.count(anchor) != 1:
        raise SystemExit(f"app_html count {text.count(anchor)}")
    text = text.replace(anchor, landing_fn + anchor, 1)

old_lang = '''        if path in ("/lang/ru", "/lang/en"):
            code = path.rsplit("/", 1)[-1]
            loc = "/"
            tenant = getattr(self, "tenant", core.DEFAULT_SELLER)
            if tenant and tenant != core.DEFAULT_SELLER:
                loc = f"/s/{tenant}/"
            return self.redirect(loc, [i18n.set_cookie(code, secure=True)])
'''
new_lang = '''        if path in ("/lang/ru", "/lang/en"):
            code = path.rsplit("/", 1)[-1]
            loc = "/"
            tenant = getattr(self, "tenant", core.DEFAULT_SELLER)
            nxt = (qs.get("next") or [""])[0]
            if tenant and tenant != core.DEFAULT_SELLER:
                loc = f"/s/{tenant}/"
            elif nxt.startswith("/") and not nxt.startswith("//") and ".." not in nxt and "\\\\" not in nxt:
                loc = nxt
            return self.redirect(loc, [i18n.set_cookie(code, secure=True)])
'''
if "qs.get(\"next\")" not in text:
    if old_lang not in text:
        raise SystemExit("lang handler missing")
    text = text.replace(old_lang, new_lang, 1)

old_route = '''        rest = self.bind_tenant(path)
'''
new_route = '''        if path == "/" or path == "/index.html":
            ref = (qs.get("ref") or [""])[0].strip()
            if ref:
                q = ("?" + parsed.query) if parsed.query else ""
                return self.redirect("/shop" + q)
            lang = i18n.normalize(i18n.from_cookie(self.headers.get("Cookie", "")))
            return self.respond(landing_html(lang))

        rest = self.bind_tenant(path)
'''
if "return self.respond(landing_html(lang))" not in text:
    # only the first bind_tenant in _get, which follows the download block
    marker = '''            return

        rest = self.bind_tenant(path)
'''
    if marker not in text:
        raise SystemExit("bind marker missing")
    text = text.replace(
        marker,
        marker.replace("        rest = self.bind_tenant(path)\n", new_route, 1),
        1,
    )

old_shop = '        if path in ("/", "/index.html"):'
new_shop = '        if path in ("/", "/index.html", "/shop", "/shop/"):'
if new_shop not in text:
    if text.count(old_shop) != 1:
        raise SystemExit(f"shop route count {text.count(old_shop)}")
    text = text.replace(old_shop, new_shop, 1)

old_switch = 'i18n.lang_switch_html(lang, "/")'
new_switch = 'i18n.lang_switch_html(lang, "/shop")'
if new_switch not in text:
    if text.count(old_switch) != 1:
        raise SystemExit(f"lang switch count {text.count(old_switch)}")
    text = text.replace(old_switch, new_switch, 1)

old_brand = '<a class="brand" id="brandName" href="/"'
new_brand = '<a class="brand" id="brandName" href="/shop"'
if new_brand not in text:
    if text.count(old_brand) != 1:
        raise SystemExit("brand link missing")
    text = text.replace(old_brand, new_brand, 1)

old_tg = '<a class="pill" href="https://t.me/{esc(bot)}" target="_blank" rel="noopener">Telegram</a>'
new_tg = '<a class="pill" href="/">{"Download" if lang == "en" else "Скачать"}</a>\\n    ' + old_tg
if 'class="pill" href="/"' not in text:
    if text.count(old_tg) != 1:
        raise SystemExit("telegram pill missing")
    text = text.replace(old_tg, new_tg, 1)

text = text.replace(
    '<p><a href="/">Открыть магазин TEZ VPN</a></p>',
    '<p><a href="/shop">Открыть магазин TEZ VPN</a></p>',
    1,
)
text = text.replace(
    '<p style="margin-top:16px"><a href="/" style="color:#5aa7ff">Или купить на сайте</a></p>',
    '<p style="margin-top:16px"><a href="/shop" style="color:#5aa7ff">Или купить на сайте</a></p>',
    1,
)

if "def landing_html(" not in text or "landing_html(lang)" not in text or '"/shop"' not in text:
    raise SystemExit("landing patch incomplete")
path.write_text(text, encoding="utf-8")
print("LANDING_PATCHED")
