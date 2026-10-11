"""Employee tab: pick functions and servers. Staff can add clients."""
from pathlib import Path

ROOT = Path("/root/vpn-panel")
core_path = ROOT / "awgcore.py"
panel_path = ROOT / "panel.py"
core = core_path.read_text(encoding="utf-8")
panel = panel_path.read_text(encoding="utf-8")
core_bak = ROOT / "awgcore.py.bak-staff"
panel_bak = ROOT / "panel.py.bak-staff"
if not core_bak.exists():
    core_bak.write_text(core, encoding="utf-8")
if not panel_bak.exists():
    panel_bak.write_text(panel, encoding="utf-8")

old_taken = '''def seller_password_taken(password: str, skip_slug: str = "") -> bool:
'''
new_taken = '''def seller_password_taken(password: str, skip_slug: str = "", skip_staff: str = "") -> bool:
'''
if "skip_staff: str = \"\"" not in core:
    if old_taken not in core:
        raise SystemExit("seller_password_taken missing")
    core = core.replace(old_taken, new_taken, 1)

old_end = '''        if stored and check_password(password, stored):
            return True
    return False


def ensure_seller_email() -> None:
'''
new_end = '''        if stored and check_password(password, stored):
            return True
    try:
        staff = json.loads(Path("/root/vpn-panel/staff.json").read_text(encoding="utf-8"))
    except (OSError, ValueError):
        staff = {}
    if isinstance(staff, dict):
        skip = str(skip_staff or "").strip().lower()
        for login, row in staff.items():
            if str(login) == skip or not isinstance(row, dict):
                continue
            stored = str(row.get("password_hash") or "")
            if stored and check_password(password, stored):
                return True
    return False


def ensure_seller_email() -> None:
'''
if "staff.json" not in core:
    if old_end not in core:
        raise SystemExit("password taken end missing")
    core = core.replace(old_end, new_end, 1)

old_session = '''def new_session(role: str = "owner", seller: str = "", perms: list | None = None,
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
new_session = '''def new_session(role: str = "owner", seller: str = "", perms: list | None = None,
                login: str = "", servers: list | None = None) -> str:
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
            "servers": [str(sid) for sid in (servers or [])],
        }
    return token
'''
if '"servers":' not in panel.split("def new_session", 1)[1][:700]:
    if old_session not in panel:
        raise SystemExit("new_session missing")
    panel = panel.replace(old_session, new_session, 1)

old_visible = '''    def visible_servers(self) -> dict:
        sess = getattr(self, "sess", None) or {}
        if sess_is_owner(sess):
            return core.servers()
        if sess.get("role") != "seller":
            return {}
        return core.seller_servers(shop_scope(sess))
'''
new_visible = '''    def scoped_capacity(self, sess: dict) -> list:
        if sess_is_owner(sess):
            return core.capacity()
        if sess.get("role") == "staff":
            allowed = {str(sid) for sid in (sess.get("servers") or [])}
            picked = []
            for item in core.capacity():
                if not isinstance(item, dict):
                    continue
                sid = str(item.get("sid") or item.get("id") or "")
                if sid in allowed:
                    picked.append(item)
            return picked
        return core.capacity(seller=shop_scope(sess))

    def visible_servers(self) -> dict:
        sess = getattr(self, "sess", None) or {}
        if sess_is_owner(sess):
            return core.servers()
        if sess.get("role") == "staff":
            allowed = {str(sid) for sid in (sess.get("servers") or [])}
            return {sid: srv for sid, srv in core.servers().items() if sid in allowed}
        if sess.get("role") != "seller":
            return {}
        return core.seller_servers(shop_scope(sess))
'''
if "sess.get(\"role\") == \"staff\"" not in panel.split("def visible_servers", 1)[1][:500]:
    if old_visible not in panel:
        raise SystemExit("visible_servers missing")
    panel = panel.replace(old_visible, new_visible, 1)

panel = panel.replace(
    "core.capacity() if sess_is_owner(sess) else core.capacity(seller=slug)",
    "self.scoped_capacity(sess)",
)

old_login = '''            client = staff_access.authenticate_password(password)
'''
new_login = '''            staff = staff_access.find_staff(password)
            if staff and not staff.get("enabled"):
                return self.login_page("Вход сотрудника закрыт.")
            if staff:
                new_token = new_session(
                    "staff", perms=staff["perms"], login=staff["login"],
                    servers=staff["servers"],
                )
                dest = staff_access.landing({"role": "staff", "perms": staff["perms"]}) or "/"
                return self.redirect(self.home() if dest == "/" else dest, [
                    ("Set-Cookie",
                     f"sid={new_token}; HttpOnly; SameSite=Strict; Path=/{secure}")])
            client = staff_access.authenticate_password(password)
'''
if "staff_access.find_staff" not in panel:
    if old_login not in panel:
        raise SystemExit("client login missing")
    panel = panel.replace(old_login, new_login, 1)

panel = panel.replace('item("/access", "Доступ", "access", "access")',
                      'item("/access", "Сотрудники", "access", "access")', 1)
panel = panel.replace('("/access", "access", "Доступ", "access")',
                      '("/access", "access", "Сотрудники", "access")', 1)
panel = panel.replace(
    'self.shell(csrf, "access", "Доступ", inner, cta_href="/access", cta_label="Доступ")',
    'self.shell(csrf, "access", "Сотрудники", inner, cta_href="/access", cta_label="Сотрудники")',
    1,
)

old_boxes_end = '''            return "".join(bits)

        rows = []
        for person in staff_access.list_staff():
            login = person["login"]
            selected = set(person["perms"])
'''
new_boxes_end = '''            return "".join(bits)

        def server_boxes(selected: set[str]) -> str:
            bits = []
            for sid, srv in core.servers().items():
                if not isinstance(srv, dict):
                    continue
                checked = " checked" if sid in selected else ""
                title = str(srv.get("title") or sid)
                who = str(srv.get("seller") or "")
                if who and who != core.DEFAULT_SELLER:
                    title = f"{title} · {who}"
                bits.append(
                    f'<label style="display:flex;gap:8px;align-items:center;margin:6px 0">'
                    f'<input type="checkbox" name="srv_{sid}" value="1"{checked}>'
                    f'{esc(title)}</label>'
                )
            if not bits:
                return '<p class="muted">Серверов пока нет.</p>'
            return "".join(bits)

        rows = []
        for person in staff_access.list_staff():
            login = person["login"]
            selected = set(person["perms"])
            chosen_servers = set(person.get("servers") or [])
'''
if "def server_boxes(" not in panel:
    if old_boxes_end not in panel:
        raise SystemExit("access boxes missing")
    panel = panel.replace(old_boxes_end, new_boxes_end, 1)

panel = panel.replace(
    '<div class="color-grid">{boxes(selected, "perm_")}</div>',
    '<div class="color-grid">{boxes(selected, "perm_")}</div>'
    '<p class="muted" style="margin:12px 0 4px">Серверы этого сотрудника</p>'
    '<div class="color-grid">{server_boxes(chosen_servers)}</div>',
    1,
)
panel = panel.replace(
    '<div class="color-grid">{boxes(set(), "perm_")}</div>',
    '<div class="color-grid">{boxes(set(), "perm_")}</div>'
    '<p class="muted" style="margin:12px 0 4px">Серверы этого сотрудника</p>'
    '<div class="color-grid">{server_boxes(set())}</div>',
    1,
)
panel = panel.replace(
    "Это сотрудники панели. Клиенты сервиса регистрируются по почте и после входа паролем видят только свои серверы.",
    "Сотрудник входит только своим паролем. Отметьте функции и серверы. "
    "«Клиенты» даёт право создавать новых клиентов. Чужие серверы он не видит.",
    1,
)

old_save = '''            chosen = [key for key, _label, _href in staff_access.PERMS if form.get(f"perm_{key}")]
            problem = staff_access.save_staff(
                form.get("login") or "",
                form.get("title") or "",
                form.get("password") or "",
                chosen,
                bool(form.get("enabled")),
            )
'''
new_save = '''            chosen = [key for key, _label, _href in staff_access.PERMS if form.get(f"perm_{key}")]
            chosen_servers = [sid for sid in core.servers() if form.get(f"srv_{sid}")]
            problem = staff_access.save_staff(
                form.get("login") or "",
                form.get("title") or "",
                form.get("password") or "",
                chosen,
                bool(form.get("enabled")),
                chosen_servers,
            )
'''
if "chosen_servers = [sid for sid in core.servers()" not in panel:
    if old_save not in panel:
        raise SystemExit("access save missing")
    panel = panel.replace(old_save, new_save, 1)

old_new = '''        if path == "/sellers/new":
            if not sess_is_owner(sess):
                return self.redirect("/")
'''
new_new = '''        if path == "/sellers/new":
            if not staff_access.owner_area(sess, "sellers"):
                return self.redirect("/")
'''
if 'path == "/sellers/new"' not in panel or 'owner_area(sess, "sellers")' not in panel.split('path == "/sellers/new"', 1)[1][:180]:
    if old_new not in panel:
        raise SystemExit("sellers new gate missing")
    panel = panel.replace(old_new, new_new, 1)

panel = panel.replace(
    'msg=f"Пользователь {slug} создан. Вход: имя {slug} и его пароль. Магазин: {url}"',
    'msg=f"Клиент {slug} создан. Вход только его паролем. Магазин: {url}"',
    1,
)

old_act = '''            if slug == core.DEFAULT_SELLER:
                act = '<span class="muted">владелец</span>'
            elif ok:
'''
new_act = '''            if slug == core.DEFAULT_SELLER:
                act = '<span class="muted">владелец</span>'
            elif not sess_is_owner(sess):
                act = '<span class="muted">клиент</span>'
            elif ok:
'''
if "not sess_is_owner(sess)" not in panel.split("def sellers_page", 1)[1][:2200]:
    if old_act not in panel:
        raise SystemExit("seller actions missing")
    panel = panel.replace(old_act, new_act, 1)

if "def find_staff(" not in Path("/root/vpn-panel/staff_access.py").read_text(encoding="utf-8"):
    raise SystemExit("find_staff missing")
if "staff_access.find_staff" not in panel or "def server_boxes(" not in panel:
    raise SystemExit("employee tab missing")
if 'owner_area(sess, "sellers")' not in panel.split('path == "/sellers/new"', 1)[1][:200]:
    raise SystemExit("client create still owner-only")
if 'name="email"' in panel.split("def login_page", 1)[1][:1200]:
    raise SystemExit("login form is not password-only")

core_path.write_text(core, encoding="utf-8")
panel_path.write_text(panel, encoding="utf-8")
print("STAFF_TAB_PATCHED")
