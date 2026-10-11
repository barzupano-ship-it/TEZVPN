"""Add public registration. Login stays a single password field."""
from pathlib import Path

path = Path("/root/vpn-panel/panel.py")
text = path.read_text(encoding="utf-8")
backup = Path("/root/vpn-panel/panel.py.bak-register")
if not backup.exists():
    backup.write_text(text, encoding="utf-8")

register_page = '''    def register_page(self, msg: str = "", err: str = "", email: str = "") -> None:
        note = ""
        if msg:
            note += f'<div class="msg ok">{esc(msg)}</div>'
        if err:
            note += f'<div class="msg err">{esc(err)}</div>'
        self.respond(page(f"""<div class="login-wrap"><div class="login-card">
<div style="display:flex;justify-content:flex-end;margin-bottom:8px">{self.lang_switch()}</div>
<div class="brand" style="color:#1a1d21;margin-bottom:8px">TEZ <span>VPN</span></div>
<h1>Регистрация</h1>
<p class="muted" style="margin-top:0">Укажите почту и пароль. Вход в панель остаётся только по паролю.</p>
{note}
<form method="post" action="/register">
<label>Почта</label>
<input type="email" name="email" required maxlength="80" value="{esc(email)}" placeholder="name@mail.com" style="width:100%" autocomplete="email">
<label>Пароль</label>
<input type="password" name="password" required minlength="8" style="width:100%" autocomplete="new-password">
<label>Пароль ещё раз</label>
<input type="password" name="password2" required minlength="8" style="width:100%" autocomplete="new-password">
<div class="row" style="margin-top:14px"><button class="btn-yellow" style="width:100%">Зарегистрироваться</button></div>
</form>
<p class="muted" style="margin-top:14px;text-align:center"><a href="/login">Войти по паролю</a></p>
</div></div>""", "Регистрация"))

'''

anchor = "    def login_page(self, error: str = \"\") -> None:\n"
if "def register_page(" not in text:
    if anchor not in text:
        raise SystemExit("login page missing")
    text = text.replace(anchor, register_page + anchor, 1)

old_login_tail = '''<div class="row" style="margin-top:14px"><button class="btn-yellow" style="width:100%">{esc(i18n.t("sign_in"))}</button></div>
</form></div></div>""", i18n.t("login_title")))
'''
new_login_tail = '''<div class="row" style="margin-top:14px"><button class="btn-yellow" style="width:100%">{esc(i18n.t("sign_in"))}</button></div>
</form>
<p class="muted" style="margin-top:14px;text-align:center"><a href="/register">Регистрация</a></p>
</div></div>""", i18n.t("login_title")))
'''
if 'href="/register"' not in text.split("def login_page", 1)[1][:1200]:
    if old_login_tail not in text:
        raise SystemExit("login button missing")
    text = text.replace(old_login_tail, new_login_tail, 1)

old_get = '''        if path == "/login":
            return self.redirect(self.home()) if sess else self.login_page()
        if path == "/join":
'''
new_get = '''        if path == "/login":
            return self.redirect(self.home()) if sess else self.login_page()
        if path == "/register":
            return self.redirect(self.home()) if sess else self.register_page()
        if path == "/join":
'''
if text.count('path == "/register"') < 1:
    if old_get not in text:
        raise SystemExit("login get missing")
    text = text.replace(old_get, new_get, 1)

old_post = '''            staff = staff_access.authenticate_password(password)
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

        if not sess:
'''
new_post = '''            staff = staff_access.authenticate_password(password)
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
            note_fail(client_ip)
            return self.login_page(i18n.t("wrong_password"))

        if path == "/register":
            if sess:
                return self.redirect(self.home())
            if login_locked(client_ip):
                return self.register_page(err=i18n.t("too_many"))
            form = self.read_form()
            email = (form.get("email") or "").strip()
            password = form.get("password") or ""
            again = form.get("password2") or ""
            if password != again:
                note_fail(client_ip)
                return self.register_page(err="Пароли не совпадают.", email=email)
            problem = staff_access.register(email, password)
            if problem:
                note_fail(client_ip)
                return self.register_page(err=problem, email=email)
            return self.register_page(msg="Заявка принята. Вход только паролем. Панель откроется, когда владелец отметит разделы.")

        if not sess:
'''
if 'staff_access.register(' not in text:
    if old_post not in text:
        raise SystemExit("login post missing")
    text = text.replace(old_post, new_post, 1)

old_loop = '''            enabled = " checked" if person["enabled"] else ""
            rows.append(f"""<div class="card">
<h2 style="margin-top:0">{esc(person["title"])} · <code>{esc(login)}</code></h2>
'''
new_loop = '''            enabled = " checked" if person["enabled"] else ""
            wait = "" if person["enabled"] else " · ждёт доступа"
            rows.append(f"""<div class="card">
<h2 style="margin-top:0">{esc(person["title"])} · <code>{esc(login)}</code>{wait}</h2>
'''
if "ждёт доступа" not in text:
    if old_loop not in text:
        raise SystemExit("staff card missing")
    text = text.replace(old_loop, new_loop, 1)

old_hint = (
    "Укажите почту и пароль. Человек входит на эту же панель только паролем, без имени. "
    "Отметьте разделы, которые ему можно открывать."
)
new_hint = (
    "Человек регистрируется сам: почта и пароль. В панель он входит только паролем. "
    "Пока вы не отметите разделы и «Может входить», пароль панель не откроет. "
    "Добавить человека можно и здесь."
)
if old_hint not in text and new_hint not in text:
    raise SystemExit("access hint missing")
text = text.replace(old_hint, new_hint, 1)

login_body = text.split("def login_page", 1)[1][:1400]
if 'name="email"' in login_body or 'name="login"' in login_body:
    raise SystemExit("login form is no longer password-only")
if 'href="/register"' not in login_body:
    raise SystemExit("register link missing")
if "def register_page(" not in text or 'staff_access.register(' not in text:
    raise SystemExit("register flow missing")
if text.count('path == "/register"') < 2:
    raise SystemExit("register routes missing")

path.write_text(text, encoding="utf-8")
print("REGISTER_PATCHED")
