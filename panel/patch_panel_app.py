"""Add the branded-APK page to the admin panel. Run on the shop server."""

from pathlib import Path

panel_path = Path("/root/vpn-panel/panel.py")
i18n_path = Path("/root/vpn-panel/i18n.py")
panel = panel_path.read_text(encoding="utf-8")
i18n = i18n_path.read_text(encoding="utf-8")

if "import appfactory" not in panel:
    needle = "import i18n  # noqa: E402\n"
    if needle not in panel:
        raise SystemExit("import anchor missing")
    panel = panel.replace(needle, needle + "import appfactory  # noqa: E402\n", 1)

phone = (
    '    "phone": \'<svg viewBox="0 0 24 24" width="18" height="18" fill="none" '
    'stroke="currentColor" stroke-width="1.8"><rect x="7" y="3" width="10" height="18" rx="2"/>'
    '<path d="M11 18h2"/></svg>\',\n'
)
if '"phone":' not in panel:
    marker = "# --------------------------------------------------------------------------- #\n# handler\n"
    idx = panel.find(marker)
    if idx < 0:
        raise SystemExit("handler marker missing")
    brace = panel.rfind("\n}", 0, idx)
    if brace < 0:
        raise SystemExit("icon brace missing")
    panel = panel[:brace] + "\n" + phone + panel[brace + 1 :]

nav_old = """f'{self._nav_link("/theme", i18n.t("nav_theme"), current, "theme", "theme")}'"""
nav_new = '''f'{self._nav_link("/app", i18n.t("nav_app"), current, "app", "phone")}'
                f'{self._nav_link("/theme", i18n.t("nav_theme"), current, "theme", "theme")}' '''
if "/app" not in panel.split("def sidebar")[1].split("def mobile_nav")[0]:
    if nav_old not in panel:
        raise SystemExit("sidebar theme link missing")
    panel = panel.replace(nav_old, nav_new, 1)

mob_old = '''("/theme", "theme", i18n.t("nav_theme")),'''
mob_new = '''("/app", "app", i18n.t("nav_app")),
                     ("/theme", "theme", i18n.t("nav_theme")),'''
mobile = panel.split("def mobile_nav", 1)[1].split("def shell", 1)[0]
if '"/app"' not in mobile and "'/app'" not in mobile:
    if mob_old not in panel:
        raise SystemExit("mobile theme link missing")
    panel = panel.replace(mob_old, mob_new, 1)

owner_old = '''or path in ("/bots", "/theme") or path.startswith("/sellers")):'''
owner_new = '''or path in ("/bots", "/theme", "/app") or path.startswith("/app/")
                or path.startswith("/sellers")):'''
if owner_old not in panel:
    if '"/app"' not in panel[panel.find("def _handle_post"):]:
        raise SystemExit("owner gate missing")
else:
    panel = panel.replace(owner_old, owner_new, 1)

owner_old2 = '''or path in ("/bots", "/theme"):'''
owner_new2 = '''or path in ("/bots", "/theme", "/app") or path.startswith("/app/"):'''
if owner_old2 not in panel:
    if 'path.startswith("/app/")' not in panel[panel.find("def _handle_post"):]:
        raise SystemExit("owner inner gate missing")
else:
    panel = panel.replace(owner_old2, owner_new2, 1)

get_old = '''        if path == "/theme":
            if not sess_is_owner(sess):
                return self.redirect("/")
            return self.theme_page(sess)
'''
get_new = '''        if path == "/app/download":
            if not sess_is_owner(sess):
                return self.redirect("/")
            return self.send_built_apk()
        if path == "/app":
            if not sess_is_owner(sess):
                return self.redirect("/")
            return self.app_page(sess)
        if path == "/theme":
            if not sess_is_owner(sess):
                return self.redirect("/")
            return self.theme_page(sess)
'''
if 'path == "/app"' not in panel:
    if get_old not in panel:
        raise SystemExit("theme get missing")
    panel = panel.replace(get_old, get_new, 1)

post_old = '''        if path == "/theme":
            preset = (form.get("preset") or "").strip()
'''
post_new = '''        if path == "/app":
            if not sess_is_owner(sess):
                return self.redirect("/")
            brand, problem = appfactory.validate_brand(form)
            if problem or brand is None:
                return self.app_page(sess, err=problem or "Проверьте поля.")
            appfactory.save_brand(brand)
            try:
                built = appfactory.build(brand)
            except Exception as exc:
                sys.stderr.write(f"app build: {exc}\\n")
                lines = [ln.strip() for ln in str(exc).splitlines() if ln.strip()]
                short = lines[-1] if lines else "Сборка не удалась."
                return self.app_page(sess, err=short[:400])
            return self.app_page(sess, msg=f"Готово: {built.name}. Скачайте файл и установите его на телефон.")

        if path == "/theme":
            preset = (form.get("preset") or "").strip()
'''
if 'appfactory.build' not in panel:
    if post_old not in panel:
        raise SystemExit("theme post missing")
    panel = panel.replace(post_old, post_new, 1)

method = '''    def app_page(self, sess: dict, msg: str = "", err: str = "") -> None:
        csrf = esc(sess["csrf"])
        brand = appfactory.load_brand()
        notes = ""
        if msg:
            notes += f'<div class="msg ok">{esc(msg)}</div>'
        if err:
            notes += f'<div class="msg err">{esc(err)}</div>'
        built = appfactory.latest_apk()
        download = ""
        if built:
            download = (
                f'<p style="margin-top:14px"><a class="btn-yellow" href="/app/download">'
                f'Скачать {esc(built.name)}</a></p>'
            )

        def color_field(key: str, label: str) -> str:
            val = esc(brand[key])
            return (
                f'<div class="color-field"><div style="flex:1">'
                f'<label style="margin:0">{esc(label)}</label>'
                f'<input type="text" name="{key}" value="{val}" pattern="#[0-9A-Fa-f]{{6}}" '
                f'required maxlength="7" id="a-{key}"></div>'
                f'<input type="color" value="{val}" '
                f'onchange="document.getElementById(\\'a-{key}\\').value=this.value">'
                f"</div>"
            )

        inner = f"""{notes}
<div class="card">
<h2 style="margin-top:0">Своё приложение</h2>
<p class="muted">Получится файл вида TEZVPN-1.0.5.apk. Внутри будут ваше название, адрес магазина, поддержка и цвета. На иконке телефона будет то же название. Сборка занимает одну-две минуты. Если TEZVPN уже установлен, новый файл ставится поверх него.</p>
<form method="post" action="/app">
<input type="hidden" name="csrf" value="{csrf}">
<label>Название</label>
<input name="appName" value="{esc(brand['appName'])}" maxlength="24" required style="width:100%">
<label>Адрес магазина</label>
<input name="shopUrl" value="{esc(brand['shopUrl'])}" maxlength="160" required style="width:100%">
<label>Поддержка в Telegram</label>
<input name="support" value="{esc(brand['support'])}" maxlength="32" required style="width:100%" placeholder="username">
<div class="color-grid" style="margin-top:12px">
{color_field("gold", "Кнопки")}
{color_field("navy", "Фон")}
{color_field("card", "Карточки")}
</div>
<div class="row" style="margin-top:16px">
<button class="btn-yellow" type="submit">Собрать APK</button>
</div>
</form>
{download}
</div>"""
        self.respond(page(
            self.shell(
                csrf, "app", i18n.t("page_app"), inner,
                cta_href="/app/download" if built else "/app",
                cta_label="Скачать APK" if built else i18n.t("nav_app"),
            ),
            i18n.t("page_app"),
        ))

    def send_built_apk(self) -> None:
        path = appfactory.latest_apk()
        if path is None or not path.is_file():
            return self.redirect("/app")
        data = path.read_bytes()
        self.respond(
            data,
            ctype="application/vnd.android.package-archive",
            extra=[("Content-Disposition", f'attachment; filename="{path.name}"')],
        )

'''
if "def app_page" not in panel:
    anchor = "    def theme_page(self, sess: dict, msg: str = \"\", err: str = \"\") -> None:\n"
    if anchor not in panel:
        raise SystemExit("theme_page missing")
    panel = panel.replace(anchor, method + anchor, 1)

panel_path.write_text(panel, encoding="utf-8")

if '"nav_app"' not in i18n:
    lines = i18n.splitlines(keepends=True)
    out = []
    for line in lines:
        out.append(line)
        if '"nav_theme": "Цвета"' in line:
            out.append(line.replace("nav_theme", "nav_app").replace("Цвета", "Приложение"))
        elif '"page_theme": "Цвета панели"' in line:
            out.append('        "page_app": "Своё приложение",\n')
        elif '"nav_theme": "Colors"' in line:
            out.append(line.replace("nav_theme", "nav_app").replace("Colors", "App"))
        elif '"page_theme": "Panel colors"' in line:
            out.append('        "page_app": "Your app",\n')
    i18n_path.write_text("".join(out), encoding="utf-8")

print("PANEL_PATCHED")
