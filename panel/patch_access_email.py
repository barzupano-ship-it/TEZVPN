"""Switch staff registration to email and keep panel login password-only."""
from pathlib import Path

path = Path("/root/vpn-panel/panel.py")
text = path.read_text(encoding="utf-8")
backup = Path("/root/vpn-panel/panel.py.bak-email")
if not backup.exists():
    backup.write_text(text, encoding="utf-8")

old_form = '''<label>Имя сотрудника</label>
<input name="login" autocomplete="username" placeholder="владелец оставляет пустым" style="width:100%">
<label>{esc(i18n.t("password"))}</label>
<input type="password" name="password" placeholder="{esc(i18n.t("password"))}" required style="width:100%">
'''
new_form = '''<label>{esc(i18n.t("password"))}</label>
<input type="password" name="password" placeholder="{esc(i18n.t("password"))}" autofocus required style="width:100%">
'''
if old_form not in text:
    if new_form not in text:
        raise SystemExit("login form missing")
else:
    text = text.replace(old_form, new_form, 1)

old_handler = '''            form = self.read_form()
            login_name = (form.get("login") or "").strip().lower()
            password = form.get("password", "")
            secure = "; Secure" if tls_ready() else ""
            if not login_name:
                if PASSWORD_HASH and core.check_password(password, PASSWORD_HASH):
                    new_token = new_session()
                    return self.redirect(self.home(), [
                        ("Set-Cookie",
                         f"sid={new_token}; HttpOnly; SameSite=Strict; Path=/{secure}")])
            else:
                staff, _why = staff_access.authenticate(login_name, password)
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
new_handler = '''            form = self.read_form()
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
if "authenticate_password" not in text:
    if old_handler not in text:
        raise SystemExit("login handler missing")
    text = text.replace(old_handler, new_handler, 1)

old_hint = (
    "Человек входит на эту же панель: в поле имени пишет свой логин, ниже — пароль, "
    "который вы задали. Владелец по-прежнему входит только паролем, имя оставляет пустым. "
    "Отметьте разделы, которые ему можно открывать."
)
new_hint = (
    "Укажите почту и пароль. Человек входит на эту же панель только паролем, без имени. "
    "Отметьте разделы, которые ему можно открывать."
)
if old_hint not in text and new_hint not in text:
    raise SystemExit("access hint missing")
text = text.replace(old_hint, new_hint, 1)

old_mail = '''<label>Имя для входа (латиница, 3–24)</label>
<input name="login" required pattern="[a-z0-9]{{3,24}}" placeholder="ivan" style="width:100%">
'''
new_mail = '''<label>Почта</label>
<input type="email" name="login" required maxlength="80" placeholder="name@mail.com" style="width:100%" autocomplete="off">
'''
if old_mail not in text:
    if 'type="email" name="login"' not in text:
        raise SystemExit("email field missing")
else:
    text = text.replace(old_mail, new_mail, 1)

text = text.replace(
    "Доступ сохранён. Сотрудник входит своим именем и паролем.",
    "Доступ сохранён. Сотрудник входит только этим паролем.",
    1,
)

login_page = text.split("def login_page", 1)[1][:900]
if 'Имя сотрудника' in login_page or 'name="login"' in login_page:
    raise SystemExit("login form still asks for a name")
if "authenticate_password" not in text:
    raise SystemExit("password lookup missing")

path.write_text(text, encoding="utf-8")
print("EMAIL_PATCHED")
