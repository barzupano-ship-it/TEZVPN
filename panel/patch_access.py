"""Wire staff access into the admin panel. Run on the shop server."""

from pathlib import Path
import shutil

panel_path = Path("/root/vpn-panel/panel.py")
i18n_path = Path("/root/vpn-panel/i18n.py")
shutil.copy2(panel_path, Path("/root/vpn-panel/panel.py.bak-access"))
text = panel_path.read_text(encoding="utf-8")

if "import staff_access" not in text:
    needle = "import i18n  # noqa: E402\n"
    if needle not in text:
        raise SystemExit("import anchor missing")
    text = text.replace(needle, needle + "import staff_access  # noqa: E402\n", 1)

if '"access":' not in text:
    icon = (
        '    "access": \'<svg viewBox="0 0 24 24" width="18" height="18" fill="none" '
        'stroke="currentColor" stroke-width="1.8"><rect x="6" y="10" width="12" height="10" rx="2"/>'
        '<path d="M8 10V7a4 4 0 0 1 8 0v3"/></svg>\',\n'
    )
    marker = '"phone":'
    if marker not in text:
        raise SystemExit("phone icon missing")
    text = text.replace('    "phone":', icon + '    "phone":', 1)

old_session = '''def new_session(role: str = "owner", seller: str = "") -> str:
    token = secrets.token_urlsafe(32)
    with _lock:
        _sessions[token] = {
            "expires": time.time() + SESSION_TTL,
            "csrf": secrets.token_urlsafe(24),
            "role": role if role in ("owner", "seller") else "owner",
            "seller": seller or core.DEFAULT_SELLER,
        }
    return token
'''
new_session = '''def new_session(role: str = "owner", seller: str = "", perms: list | None = None,
                login: str = "") -> str:
    token = secrets.token_urlsafe(32)
    role = role if role in ("owner", "seller", "staff") else "owner"
    with _lock:
        _sessions[token] = {
            "expires": time.time() + SESSION_TTL,
            "csrf": secrets.token_urlsafe(24),
            "role": role,
            "seller": seller or core.DEFAULT_SELLER,
            "perms": list(perms or []),
            "login": login or "",
        }
    return token
'''
if "perms: list | None = None" not in text:
    if old_session not in text:
        raise SystemExit("new_session missing")
    text = text.replace(old_session, new_session, 1)

old_visible = '''    def visible_servers(self) -> dict:
        sess = getattr(self, "sess", None) or {}
        if sess_is_owner(sess):
            return core.servers()
        return core.seller_servers(shop_scope(sess))
'''
new_visible = '''    def visible_servers(self) -> dict:
        sess = getattr(self, "sess", None) or {}
        if sess_is_owner(sess):
            return core.servers()
        if sess.get("role") == "staff":
            if staff_access.allows(sess, "servers"):
                return core.servers()
            return {}
        return core.seller_servers(shop_scope(sess))
'''
if 'sess.get("role") == "staff"' not in text.split("def visible_servers", 1)[1][:500]:
    if old_visible not in text:
        raise SystemExit("visible_servers missing")
    text = text.replace(old_visible, new_visible, 1)

nav = r'''    def can_see(self, key: str) -> bool:
        sess = getattr(self, "sess", None) or {}
        if key == "access":
            return sess_is_owner(sess)
        if sess_is_owner(sess):
            return True
        if sess.get("role") == "staff":
            return staff_access.allows(sess, key)
        return key in {"home", "seller", "shop", "books", "add", "servers"}

    def sidebar(self, current: str) -> str:
        servers = ""
        if self.can_see("servers"):
            servers = "".join(
                self._nav_link(f"/s/{sid}", srv.get("title", sid), current, sid, "server")
                for sid, srv in self.visible_servers().items()
            )

        def item(href: str, label: str, key: str, ico: str) -> str:
            if not self.can_see(key):
                return ""
            return self._nav_link(href, label, current, key, ico)

        sales = (
            item("/shop", i18n.t("nav_shop"), "shop", "shop")
            + item("/keys", i18n.t("nav_links"), "keys", "link")
            + item("/cabinets", i18n.t("nav_cabinets"), "cabinets", "link")
            + item("/partners", i18n.t("nav_partners"), "partners", "link")
            + item("/books", i18n.t("nav_books"), "books", "books")
        )
        settings = (
            item("/sellers", i18n.t("nav_users"), "sellers", "shop")
            + item("/access", "Доступ", "access", "access")
            + item("/bots", i18n.t("nav_bots"), "bots", "bots")
            + item("/app", i18n.t("nav_app"), "app", "phone")
            + item("/theme", i18n.t("nav_theme"), "theme", "theme")
        )
        add_btn = ""
        if self.can_see("add"):
            add_btn = f'<a class="btn-yellow" href="/add">{_ICO["plus"]} {esc(i18n.t("add_server"))}</a>'
        server_note = (
            '<p class="muted" style="padding:0 10px">' + esc(i18n.t("nav_no_servers")) + "</p>"
            if self.can_see("servers") and not servers else ""
        )
        sales_block = (
            f'<div class="nav-group">{esc(i18n.t("nav_sales"))}</div>{sales}' if sales.strip() else ""
        )
        settings_block = (
            f'<div class="nav-group">{esc(i18n.t("nav_settings"))}</div>{settings}'
            if settings.strip() else ""
        )
        return f"""<aside class="sidebar">
{add_btn}
<nav class="nav">
<div class="nav-group">{esc(i18n.t("nav_cabinet"))}</div>
{item("/", i18n.t("nav_overview"), "home", "home")}
{item("/seller", i18n.t("nav_seller"), "seller", "shop")}
<div class="nav-group">{esc(i18n.t("nav_services"))}</div>
{servers}{server_note}
{item("/add", i18n.t("nav_new_vps"), "add", "plus")}
{sales_block}
{settings_block}
</nav></aside>"""

    def mobile_nav(self, current: str) -> str:
        items = []
        if self.can_see("home"):
            items.append('<a class="%s" href="/">%s</a>' % (
                "on" if current == "home" else "", esc(i18n.t("nav_overview"))))
        if self.can_see("servers"):
            for sid, srv in self.visible_servers().items():
                cls = "on" if sid == current else ""
                items.append(f'<a class="{cls}" href="/s/{sid}">{esc(srv.get("title", sid))}</a>')
        links = [
            ("/seller", "seller", i18n.t("nav_seller_short"), "seller"),
            ("/shop", "shop", i18n.t("nav_shop"), "shop"),
            ("/keys", "keys", i18n.t("nav_links"), "keys"),
            ("/cabinets", "cabinets", i18n.t("nav_cabinets"), "cabinets"),
            ("/partners", "partners", i18n.t("nav_partners"), "partners"),
            ("/books", "books", i18n.t("nav_books"), "books"),
            ("/bots", "bots", i18n.t("nav_bots"), "bots"),
            ("/app", "app", i18n.t("nav_app"), "app"),
            ("/theme", "theme", i18n.t("nav_theme"), "theme"),
            ("/sellers", "sellers", i18n.t("nav_users"), "sellers"),
            ("/access", "access", "Доступ", "access"),
            ("/add", "add", i18n.t("nav_new_vps"), "add"),
        ]
        for href, key, label, perm in links:
            if not self.can_see(perm):
                continue
            cls = "on" if current == key else ""
            items.append(f'<a class="{cls}" href="{href}">{esc(label)}</a>')
        return f'<div class="mobile-nav">{"".join(items)}</div>'

'''
if "def can_see(" not in text:
    start = text.find("    def sidebar(")
    end = text.find("    def shell(")
    if start < 0 or end < 0 or end < start:
        raise SystemExit("sidebar block missing")
    text = text[:start] + nav + text[end:]

# Login stays password-only. Staff are recognized by their own password.
if 'name="login"' in text.split("def login_page", 1)[1][:800]:
    raise SystemExit("login form must stay password-only")

old_login = '''            form = self.read_form()
            if PASSWORD_HASH and core.check_password(form.get("password", ""), PASSWORD_HASH):
                new_token = new_session()
                secure = "; Secure" if tls_ready() else ""
                return self.redirect(self.home(), [
                    ("Set-Cookie",
                     f"sid={new_token}; HttpOnly; SameSite=Strict; Path=/{secure}")])
            note_fail(client_ip)
            return self.login_page(i18n.t("wrong_password"))
'''
new_login = '''            form = self.read_form()
            password = form.get("password", "")
            secure = "; Secure" if tls_ready() else ""
            if PASSWORD_HASH and core.check_password(password, PASSWORD_HASH):
                new_token = new_session()
                return self.redirect(self.home(), [
                    ("Set-Cookie",
                     f"sid={new_token}; HttpOnly; SameSite=Strict; Path=/{secure}")])
            staff = staff_access.authenticate_password(password)
            if staff:
                new_token = new_session(
                    "staff", perms=staff["perms"], login=staff["login"],
                )
                dest = staff_access.landing({"role": "staff", "perms": staff["perms"]}) or "/"
                return self.redirect(dest, [
                    ("Set-Cookie",
                     f"sid={new_token}; HttpOnly; SameSite=Strict; Path=/{secure}")])
            note_fail(client_ip)
            return self.login_page(i18n.t("wrong_password"))
'''
if "staff_access.authenticate_password" not in text:
    if old_login not in text:
        raise SystemExit("login handler missing")
    text = text.replace(old_login, new_login, 1)

old_shop = '''            if not sess_is_owner(sess):
                problem = core.save_seller_shop(
'''
new_shop = '''            if sess.get("role") == "seller":
                problem = core.save_seller_shop(
'''
if old_shop not in text:
    if 'sess.get("role") == "seller"' not in text:
        raise SystemExit("shop branch missing")
else:
    text = text.replace(old_shop, new_shop, 1)

old_gate = '''        if (path.startswith("/keys") or path.startswith("/partners")
                or path in ("/bots", "/theme", "/app") or path.startswith("/app/")
                or path.startswith("/sellers")):
            if not sess_is_owner(sess) and path.startswith("/sellers"):
                return self.redirect("/")
            if path.startswith("/keys") or path.startswith("/partners") or path in ("/bots", "/theme", "/app") or path.startswith("/app/"):
                if not sess_is_owner(sess):
                    return self.redirect("/")
'''
new_gate = '''        _staff_areas = (
            ("/keys", "keys"),
            ("/partners", "partners"),
            ("/cabinets", "cabinets"),
            ("/bots", "bots"),
            ("/theme", "theme"),
            ("/app", "app"),
            ("/sellers", "sellers"),
            ("/access", "owner"),
        )
        for _prefix, _perm in _staff_areas:
            if path == _prefix or path.startswith(_prefix + "/"):
                if not staff_access.owner_area(sess, _perm):
                    return self.redirect(staff_access.landing(sess) or "/")
                break
'''
if "_staff_areas" not in text:
    if old_gate not in text:
        raise SystemExit("post gate missing")
    text = text.replace(old_gate, new_gate, 1)

# GET checks that still bounce every non-owner.
get_swaps = [
    ("/keys", "keys", "return self.keys_page(sess)"),
    ("/partners", "partners", "return self.partners_page(sess)"),
    ("/cabinets", "cabinets", "return self.cabinets_page(sess)"),
    ("/bots", "bots", "return self.bots_page(sess)"),
    ("/app/download", "app", "return self.send_built_apk()"),
    ("/app", "app", "return self.app_page(sess)"),
    ("/theme", "theme", "return self.theme_page(sess)"),
    ("/sellers", "sellers", "return self.sellers_page(sess)"),
]
for path, perm, follow in get_swaps:
    old = (
        f'        if path == "{path}":\n'
        f'            if not sess_is_owner(sess):\n'
        f'                return self.redirect("/")\n'
        f'            {follow}\n'
    )
    new = (
        f'        if path == "{path}":\n'
        f'            if not staff_access.owner_area(sess, "{perm}"):\n'
        f'                return self.redirect(staff_access.landing(sess) or "/")\n'
        f'            {follow}\n'
    )
    if old not in text:
        if f'staff_access.owner_area(sess, "{perm}")' not in text or path == "/app":
            # /app appears twice historically; accept if already swapped
            if old not in text and new not in text:
                raise SystemExit(f"get check missing for {path}")
    else:
        text = text.replace(old, new, 1)

refuse = '''    def refuse_staff(self, sess: dict, path: str) -> bool:
        """Block a staff login from sections that were not checked. Owners and sellers unchanged."""
        if sess_is_owner(sess) or sess.get("role") != "staff":
            return False
        if path == "/logout":
            return False
        need = staff_access.required_perm(path)
        if need == "seller":
            self.redirect(staff_access.landing(sess) or "/")
            return True
        if need and not staff_access.allows(sess, need):
            dest = staff_access.landing(sess)
            if not dest or dest == path:
                self.respond(page(
                    '<div class="wrap"><p>Вам не открыт этот раздел. Попросите владельца отметить его в «Доступ».</p></div>'
                ))
                return True
            self.redirect(dest)
            return True
        return False

'''
if "def refuse_staff(" not in text:
    anchor = "    def send_client_file("
    if anchor not in text:
        raise SystemExit("send_client_file missing")
    text = text.replace(anchor, refuse + anchor, 1)

old_get_sess = '''        self.sess = sess
        if path == "/":
            return self.dashboard_page(sess)
'''
new_get_sess = '''        self.sess = sess
        if self.refuse_staff(sess, path):
            return
        if path == "/":
            return self.dashboard_page(sess)
'''
if "self.refuse_staff(sess, path)" not in text.split("def _handle_get", 1)[1].split("def send_client_file", 1)[0]:
    if old_get_sess not in text:
        raise SystemExit("get sess anchor missing")
    text = text.replace(old_get_sess, new_get_sess, 1)

old_post_logout = '''        if path == "/logout":
            drop_session(token)
            return self.redirect("/login", [("Set-Cookie", "sid=; Max-Age=0; Path=/")])
'''
new_post_logout = '''        if path == "/logout":
            drop_session(token)
            return self.redirect("/login", [("Set-Cookie", "sid=; Max-Age=0; Path=/")])

        if self.refuse_staff(sess, path):
            return
'''
if text.count("self.refuse_staff(sess, path)") < 2:
    if old_post_logout not in text:
        raise SystemExit("logout anchor missing")
    text = text.replace(old_post_logout, new_post_logout, 1)

page = r'''    def access_page(self, sess: dict, msg: str = "", err: str = "") -> None:
        csrf = esc(sess["csrf"])
        notes = ""
        if msg:
            notes += f'<div class="msg ok">{esc(msg)}</div>'
        if err:
            notes += f'<div class="msg err">{esc(err)}</div>'

        def boxes(selected: set[str], prefix: str) -> str:
            bits = []
            for key, label, _href in staff_access.PERMS:
                checked = " checked" if key in selected else ""
                bits.append(
                    f'<label style="display:flex;gap:8px;align-items:center;margin:6px 0">'
                    f'<input type="checkbox" name="{prefix}{key}" value="1"{checked}>'
                    f'{esc(label)}</label>'
                )
            return "".join(bits)

        rows = []
        for person in staff_access.list_staff():
            login = person["login"]
            selected = set(person["perms"])
            enabled = " checked" if person["enabled"] else ""
            rows.append(f"""<div class="card">
<h2 style="margin-top:0">{esc(person["title"])} · <code>{esc(login)}</code></h2>
<form method="post" action="/access">
<input type="hidden" name="csrf" value="{csrf}">
<input type="hidden" name="login" value="{esc(login)}">
<label>Как показывать в списке</label>
<input name="title" value="{esc(person["title"])}" maxlength="40" style="width:100%">
<label>Новый пароль (пусто = не менять)</label>
<input type="password" name="password" minlength="8" style="width:100%" autocomplete="new-password">
<label style="display:flex;gap:8px;align-items:center"><input type="checkbox" name="enabled" value="1"{enabled}>Может входить</label>
<div class="color-grid">{boxes(selected, "perm_")}</div>
<div class="row" style="margin-top:12px">
<button class="btn-yellow" type="submit">Сохранить доступ</button>
</div>
</form>
<form method="post" action="/access/delete" style="margin-top:8px">
<input type="hidden" name="csrf" value="{csrf}">
<input type="hidden" name="login" value="{esc(login)}">
<button class="danger" type="submit">Удалить</button>
</form>
</div>""")
        inner = f"""{notes}
<div class="card">
<h2 style="margin-top:0">Новый сотрудник</h2>
<p class="muted">Укажите почту и пароль. Человек входит на эту же панель только паролем, без имени. Отметьте разделы, которые ему можно открывать.</p>
<form method="post" action="/access">
<input type="hidden" name="csrf" value="{csrf}">
<label>Почта</label>
<input type="email" name="login" required maxlength="80" placeholder="name@mail.com" style="width:100%" autocomplete="off">
<label>Имя в списке</label>
<input name="title" maxlength="40" placeholder="Иван" style="width:100%">
<label>Пароль (минимум 8)</label>
<input type="password" name="password" required minlength="8" style="width:100%" autocomplete="new-password">
<input type="hidden" name="enabled" value="1">
<div class="color-grid">{boxes(set(), "perm_")}</div>
<div class="row" style="margin-top:12px"><button class="btn-yellow" type="submit">Дать доступ</button></div>
</form>
</div>
{''.join(rows)}
"""
        self.respond(page(
            self.shell(csrf, "access", "Доступ", inner, cta_href="/access", cta_label="Доступ"),
            "Доступ",
        ))

'''
if "def access_page(" not in text:
    anchor = "    def app_page("
    if anchor not in text:
        anchor = "    def theme_page("
    if anchor not in text:
        raise SystemExit("page anchor missing")
    text = text.replace(anchor, page + anchor, 1)

get_access = '''        if path == "/access":
            if not staff_access.owner_area(sess, "owner"):
                return self.redirect("/")
            return self.access_page(sess)
'''
if 'path == "/access"' not in text.split("def _handle_get", 1)[1].split("def _handle_post", 1)[0]:
    spot = '        if path == "/theme":\n'
    # first theme check is GET
    if spot not in text:
        raise SystemExit("theme get missing")
    text = text.replace(spot, get_access + spot, 1)

post_access = '''        if path == "/access":
            if not staff_access.owner_area(sess, "owner"):
                return self.redirect("/")
            chosen = [key for key, _label, _href in staff_access.PERMS if form.get(f"perm_{key}")]
            problem = staff_access.save_staff(
                form.get("login") or "",
                form.get("title") or "",
                form.get("password") or "",
                chosen,
                bool(form.get("enabled")),
            )
            if problem:
                return self.access_page(sess, err=problem)
            return self.access_page(sess, msg="Доступ сохранён. Сотрудник входит только этим паролем.")

        if path == "/access/delete":
            if not staff_access.owner_area(sess, "owner"):
                return self.redirect("/")
            problem = staff_access.delete_staff(form.get("login") or "")
            if problem:
                return self.access_page(sess, err=problem)
            return self.access_page(sess, msg="Сотрудник удалён.")

'''
if 'path == "/access/delete"' not in text:
    spot = '        if path == "/theme":\n            preset = (form.get("preset") or "").strip()\n'
    if spot not in text:
        raise SystemExit("theme post missing")
    text = text.replace(spot, post_access + spot, 1)

panel_path.write_text(text, encoding="utf-8")

i18n = i18n_path.read_text(encoding="utf-8")
if '"nav_access"' not in i18n:
    i18n = i18n.replace(
        '"nav_theme": "Цвета",\n',
        '"nav_theme": "Цвета",\n        "nav_access": "Доступ",\n',
        1,
    ).replace(
        '"nav_theme": "Colors",\n',
        '"nav_theme": "Colors",\n        "nav_access": "Access",\n',
        1,
    )
    i18n_path.write_text(i18n, encoding="utf-8")
print("ACCESS_PATCHED")
