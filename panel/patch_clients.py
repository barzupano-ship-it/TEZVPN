"""Clients who register see only their own servers. Login stays password-only."""
import re
from pathlib import Path

ROOT = Path("/root/vpn-panel")
core_path = ROOT / "awgcore.py"
panel_path = ROOT / "panel.py"
core = core_path.read_text(encoding="utf-8")
panel = panel_path.read_text(encoding="utf-8")
core_bak = ROOT / "awgcore.py.bak-client"
panel_bak = ROOT / "panel.py.bak-client"
if not core_bak.exists():
    core_bak.write_text(core, encoding="utf-8")
if not panel_bak.exists():
    panel_bak.write_text(panel, encoding="utf-8")

client_api = '''
def seller_password_taken(password: str, skip_slug: str = "") -> bool:
    """True when this password would also open the owner or another client."""
    for key, value in os.environ.items():
        if key.endswith("PASSWORD_HASH") and str(value).startswith("scrypt$"):
            if check_password(password, str(value)):
                return True
            break
    skip = str(skip_slug or "").strip().lower()
    with db() as conn:
        rows = conn.execute("SELECT slug, password_hash FROM shop_sellers").fetchall()
    for row in rows:
        slug = str(row["slug"] or "")
        if slug == DEFAULT_SELLER or slug == skip:
            continue
        stored = str(row["password_hash"] or "")
        if stored and check_password(password, stored):
            return True
    return False


def ensure_seller_email() -> None:
    with db() as conn:
        cols = {r[1] for r in conn.execute("PRAGMA table_info(shop_sellers)")}
        if "email" not in cols:
            conn.execute("ALTER TABLE shop_sellers ADD COLUMN email TEXT")


def slug_for_email(email: str) -> str:
    local = re.sub(r"[^a-z0-9]", "", email.split("@", 1)[0])[:18]
    if len(local) < 3:
        local = ("vpn" + local)[:18]
    for n in range(0, 100):
        suffix = "" if n == 0 else str(n)
        slug = local[: 24 - len(suffix)] + suffix
        if not SELLER_SLUG_RE.fullmatch(slug) or slug in RESERVED_SELLERS:
            continue
        if seller_get(slug) is None:
            return slug
    return ""


def register_client(email: str, password: str) -> str:
    """Create a client cabinet. Their server list starts empty."""
    email = str(email or "").strip().lower()
    if not re.fullmatch(r"[a-z0-9._%+\\-]+@[a-z0-9.\\-]+\\.[a-z]{2,24}", email) or len(email) > 80:
        return "Укажите почту, например name@mail.com."
    if len(password or "") < 8:
        return "Пароль: минимум 8 символов."
    ensure_seller_email()
    with db() as conn:
        taken = conn.execute(
            "SELECT slug FROM shop_sellers WHERE lower(ifnull(email,''))=?",
            (email,),
        ).fetchone()
        count = conn.execute("SELECT COUNT(*) FROM shop_sellers").fetchone()[0]
    if taken:
        return "Эта почта уже зарегистрирована."
    if count >= 200:
        return "Список клиентов заполнен."
    slug = slug_for_email(email)
    if not slug:
        return "Не удалось создать кабинет. Укажите другую почту."
    title = email.split("@", 1)[0][:40]
    if len(title) < 2:
        title = slug
    err = seller_add_user(slug, password, title, "")
    if err:
        return err
    with db() as conn:
        conn.execute("UPDATE shop_sellers SET email=? WHERE slug=?", (email, slug))
    return ""


def client_by_password(password: str) -> dict | None:
    """Find a client by password. Does not return the owner cabinet."""
    if len(password or "") < 8:
        return None
    ensure_seller_email()
    with db() as conn:
        rows = list(conn.execute(
            "SELECT slug, title, password_hash, approved FROM shop_sellers"
        ))
    found = None
    for row in rows:
        if str(row["slug"] or "") == DEFAULT_SELLER:
            continue
        stored = str(row["password_hash"] or "")
        if not stored or not check_password(password, stored):
            continue
        if found is not None:
            return None
        found = row
    if found is None:
        return None
    return {
        "slug": str(found["slug"]),
        "title": str(found["title"] or found["slug"]),
        "enabled": bool(int(found["approved"] or 0)),
    }


'''

if "def register_client(" not in core:
    anchor = "def seller_add_user("
    if anchor not in core:
        raise SystemExit("seller_add_user missing")
    core = core.replace(anchor, client_api + anchor, 1)

old_pw = '''    if len(password or "") < 8:
        return "Пароль: минимум 8 символов."
    telegram = str(telegram or "").strip().lstrip("@")
'''
new_pw = '''    if len(password or "") < 8:
        return "Пароль: минимум 8 символов."
    if seller_password_taken(password):
        return "Такой пароль уже используется. Задайте другой."
    telegram = str(telegram or "").strip().lstrip("@")
'''
if "seller_password_taken(password)" not in core:
    if core.count(old_pw) != 1:
        raise SystemExit(f"password check count {core.count(old_pw)}")
    core = core.replace(old_pw, new_pw, 1)

old_visible = '''    def visible_servers(self) -> dict:
        sess = getattr(self, "sess", None) or {}
        if sess_is_owner(sess):
            return core.servers()
        if sess.get("role") == "staff":
            if staff_access.allows(sess, "servers"):
                return core.servers()
            return {}
        return core.seller_servers(shop_scope(sess))
'''
new_visible = '''    def visible_servers(self) -> dict:
        sess = getattr(self, "sess", None) or {}
        if sess_is_owner(sess):
            return core.servers()
        if sess.get("role") != "seller":
            return {}
        return core.seller_servers(shop_scope(sess))
'''
if 'sess.get("role") != "seller"' not in panel:
    if old_visible not in panel:
        raise SystemExit("visible_servers missing")
    panel = panel.replace(old_visible, new_visible, 1)

old_login = '''            staff = staff_access.authenticate_password(password)
            if staff and not staff.get("enabled"):
                return self.login_page("Доступ ещё не открыт. Владелец должен отметить разделы.")
            if staff:
                new_token = new_session(
                    "staff", perms=staff["perms"], login=staff["login"],
                )
                dest = staff_access.landing({"role": "staff", "perms": staff["perms"]}) or "/"
                return self.redirect(dest, [
                    ("Set-Cookie",
                     f"sid={new_token}; HttpOnly; SameSite=Strict; Path=/{secure}")])
'''
new_login = '''            client = staff_access.authenticate_password(password)
            if client and not client.get("enabled"):
                return self.login_page("Кабинет закрыт.")
            if client:
                new_token = new_session("seller", seller=client["slug"])
                return self.redirect(self.home(), [
                    ("Set-Cookie",
                     f"sid={new_token}; HttpOnly; SameSite=Strict; Path=/{secure}")])
'''
if 'new_session("seller", seller=client["slug"])' not in panel:
    if old_login not in panel:
        raise SystemExit("login client branch missing")
    panel = panel.replace(old_login, new_login, 1)

panel = panel.replace(
    "Укажите почту и пароль. Вход в панель остаётся только по паролю.",
    "Укажите почту и пароль. Вход только по паролю. В панели будут ваши серверы.",
    1,
)
panel = panel.replace(
    "Заявка принята. Вход только паролем. Панель откроется, когда владелец отметит разделы.",
    "Кабинет создан. Войдите только паролем — откроются ваши серверы.",
    1,
)
panel = panel.replace(
    "Человек регистрируется сам: почта и пароль. В панель он входит только паролем. "
    "Пока вы не отметите разделы и «Может входить», пароль панель не откроет. "
    "Добавить человека можно и здесь.",
    "Это сотрудники панели. Клиенты сервиса регистрируются по почте и после входа паролем видят только свои серверы.",
    1,
)
panel = panel.replace(
    "Он войдёт в панель своим именем и паролем, добавит свой VPS и получит магазин\n"
    "<code>https://188-116-24-47.sslip.io/s/myvpn/</code> — логин только латиницей.",
    "Он входит только своим паролем и видит только свои серверы. Чужие серверы ему не показываются.",
    1,
)

old_slug = '''            slug = row["slug"]
            ok = int(row["approved"] or 0)
'''
new_slug = '''            slug = row["slug"]
            try:
                mail = str(row["email"] or "")
            except (KeyError, IndexError):
                mail = ""
            mail_html = f'<div class="muted">{esc(mail)}</div>' if mail else ""
            ok = int(row["approved"] or 0)
'''
if 'mail_html' not in panel.split("def sellers_page", 1)[1][:2500]:
    if old_slug not in panel:
        raise SystemExit("seller row missing")
    panel = panel.replace(old_slug, new_slug, 1)
    panel = panel.replace(
        '''f'<tr><td data-label="Логин"><code>{esc(slug)}</code></td>'
''',
        '''f'<tr><td data-label="Логин"><code>{esc(slug)}</code>{mail_html}</td>'
''',
        1,
    )

job_method = '''    def job_owned(self, jid: str) -> bool:
        sess = getattr(self, "sess", None) or {}
        if sess_is_owner(sess):
            return True
        path = JOBS_DIR / f"{jid}.log"
        try:
            first = path.read_text(encoding="utf-8", errors="replace").split("\\n", 1)[0]
        except OSError:
            return False
        if "seller=" not in first:
            return False
        owner = first.split("seller=", 1)[1].strip().split()[0]
        return owner == shop_scope(sess)

'''
if "def job_owned(" not in panel:
    anchor = "    def add_page("
    if anchor not in panel:
        raise SystemExit("add_page missing")
    panel = panel.replace(anchor, job_method + anchor, 1)

old_jobs = '''        jobs = []
        if JOBS_DIR.is_dir():
            for path in sorted(JOBS_DIR.glob("*.log"), key=lambda p: p.stat().st_mtime,
                               reverse=True)[:5]:
                when = time.strftime("%d.%m %H:%M", time.localtime(path.stat().st_mtime))
                jobs.append(f'<li><a href="/job/{path.stem}">Установка от {when}</a></li>')
'''
new_jobs = '''        jobs = []
        if JOBS_DIR.is_dir():
            shown = 0
            for path in sorted(JOBS_DIR.glob("*.log"), key=lambda p: p.stat().st_mtime,
                               reverse=True):
                if not self.job_owned(path.stem):
                    continue
                when = time.strftime("%d.%m %H:%M", time.localtime(path.stat().st_mtime))
                jobs.append(f'<li><a href="/job/{path.stem}">Установка от {when}</a></li>')
                shown += 1
                if shown >= 5:
                    break
'''
if "self.job_owned(path.stem)" not in panel:
    if old_jobs not in panel:
        raise SystemExit("job list missing")
    panel = panel.replace(old_jobs, new_jobs, 1)

idx = panel.find("    def job_page(")
if idx < 0:
    raise SystemExit("job_page missing")
line_end = panel.find("\n", idx)
sig = panel[idx:line_end]
print("JOBDEF", sig)
args = sig.split("(", 1)[1].split(")", 1)[0].split(",")
names = [part.strip().split(":")[0].split("=")[0].strip() for part in args]
param = "jid" if "jid" in names else ""
if not param:
    raise SystemExit("job_page jid arg missing")
guard = f"        if not self.job_owned({param}):\n            return self.redirect(\"/\")\n"
if guard not in panel:
    panel = panel[:line_end + 1] + guard + panel[line_end + 1:]

for name in ("dashboard_page", "seller_page", "shop_page", "books_page"):
    mark = f"    def {name}("
    start = panel.find(mark)
    if start < 0:
        print("NO", name)
        continue
    end = panel.find("\n    def ", start + 10)
    body = panel[start:end]
    count = body.count("core.servers()")
    print("SCOPE", name, count)
    if count:
        panel = panel[:start] + body.replace("core.servers()", "self.visible_servers()") + panel[end:]

if "def register_client(" not in core or "def client_by_password(" not in core:
    raise SystemExit("client api missing")
if 'new_session("seller", seller=client["slug"])' not in panel:
    raise SystemExit("seller login missing")
if 'sess.get("role") != "seller"' not in panel:
    raise SystemExit("server scope missing")
if 'name="email"' in panel.split("def login_page", 1)[1][:1200]:
    raise SystemExit("login form asks for more than a password")

core_path.write_text(core, encoding="utf-8")
panel_path.write_text(panel, encoding="utf-8")
print("CLIENT_PATCHED")
