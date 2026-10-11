"""Helpers for the admin panel.

Public registration creates a client cabinet (own servers), not a staff login.
The login form stays password-only.
"""

from __future__ import annotations

import json
import os
import re
from pathlib import Path

import awgcore as core

STAFF_FILE = Path("/root/vpn-panel/staff.json")
EMAIL_RE = re.compile(r"^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,24}$")

# key, label shown in the access form, path opened from the menu
PERMS: list[tuple[str, str, str]] = [
    ("home", "Обзор", "/"),
    ("servers", "Серверы", "/"),
    ("add", "Добавить сервер", "/add"),
    ("shop", "Магазин и заказы", "/shop"),
    ("keys", "Ссылки", "/keys"),
    ("cabinets", "Кабинеты", "/cabinets"),
    ("partners", "Партнёры", "/partners"),
    ("books", "Книги", "/books"),
    ("bots", "Боты", "/bots"),
    ("app", "Приложение", "/app"),
    ("theme", "Цвета панели", "/theme"),
    ("sellers", "Клиенты", "/sellers"),
]
PERM_KEYS = {key for key, _label, _href in PERMS}


def required_perm(path: str) -> str | None:
    """Section required to open this path. None means any logged-in staff may pass."""
    if path in ("/", "/logout", "/favicon.ico"):
        return None
    if path == "/seller":
        return "seller"
    if path == "/add" or path.startswith("/job/"):
        return "add"
    if path.startswith("/s/"):
        return "servers"
    if path == "/shop" or path.startswith("/shop/"):
        return "shop"
    if path.startswith("/keys"):
        return "keys"
    if path.startswith("/cabinets"):
        return "cabinets"
    if path.startswith("/partners"):
        return "partners"
    if path.startswith("/books"):
        return "books"
    if path.startswith("/bots"):
        return "bots"
    if path == "/theme":
        return "theme"
    if path == "/app" or path.startswith("/app/"):
        return "app"
    if path.startswith("/sellers"):
        return "sellers"
    if path == "/access" or path.startswith("/access/"):
        return "owner"
    return None


def allows(sess: dict | None, perm: str) -> bool:
    if not sess:
        return False
    if sess.get("role", "owner") == "owner":
        return True
    if sess.get("role") != "staff":
        return False
    return perm in set(sess.get("perms") or [])


def owner_area(sess: dict | None, perm: str) -> bool:
    """Owner sections. Sellers stay out. Staff need the matching checkbox."""
    if perm == "owner":
        return bool(sess) and sess.get("role", "owner") == "owner"
    return allows(sess, perm)


def landing(sess: dict | None) -> str:
    if not sess or sess.get("role") != "staff":
        return "/"
    have = set(sess.get("perms") or [])
    for key, _label, href in PERMS:
        if key in have and key != "servers":
            return href
    if "servers" in have:
        return "/"
    return ""


def _load() -> dict:
    try:
        data = json.loads(STAFF_FILE.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}
    return data if isinstance(data, dict) else {}


def _save(data: dict) -> None:
    STAFF_FILE.parent.mkdir(parents=True, exist_ok=True)
    tmp = STAFF_FILE.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    tmp.chmod(0o600)
    tmp.replace(STAFF_FILE)


def list_staff() -> list[dict]:
    rows = []
    for login, row in _load().items():
        if not isinstance(row, dict):
            continue
        rows.append({
            "login": login,
            "title": str(row.get("title") or login),
            "perms": [p for p in (row.get("perms") or []) if p in PERM_KEYS],
            "servers": _clean_servers(row.get("servers") or []),
            "enabled": bool(row.get("enabled", True)),
        })
    rows.sort(key=lambda item: (item["enabled"], item["login"]))
    return rows


def _clean_perms(selected: list[str]) -> list[str]:
    return [key for key, _label, _href in PERMS if key in set(selected)]


def _clean_servers(selected: list) -> list[str]:
    known = core.servers()
    out: list[str] = []
    for sid in selected or []:
        sid = str(sid or "")
        if sid in known and sid not in out:
            out.append(sid)
    return out


def _owner_hash() -> str:
    for key, value in os.environ.items():
        if key.endswith("PASSWORD_HASH") and str(value).startswith("scrypt$"):
            return str(value)
    return ""


def _password_used(password: str, skip: str) -> bool:
    if core.seller_password_taken(password, skip_staff=skip):
        return True
    for login, row in _load().items():
        if login == skip or not isinstance(row, dict):
            continue
        stored = str(row.get("password_hash") or "")
        if stored and core.check_password(password, stored):
            return True
    return False


def save_staff(login: str, title: str, password: str, perms: list[str], enabled: bool,
               servers: list | None = None) -> str:
    login = str(login or "").strip().lower()
    if not EMAIL_RE.fullmatch(login) or len(login) > 80:
        return "Укажите почту, например name@mail.com."
    title = " ".join(str(title or "").split())[:40]
    if len(title) < 2:
        title = login.split("@", 1)[0][:40]
    data = _load()
    row = data.get(login) if isinstance(data.get(login), dict) else None
    if row is None and len(password or "") < 8:
        return "Пароль: минимум 8 символов."
    if row is None:
        row = {}
    if password:
        if len(password) < 8:
            return "Новый пароль: минимум 8 символов."
        if _password_used(password, login):
            return "Такой пароль уже используется. Задайте другой."
        row["password_hash"] = core.hash_password(password)
    elif not row.get("password_hash"):
        return "Пароль: минимум 8 символов."
    row["title"] = title
    row["email"] = login
    row["perms"] = _clean_perms(perms)
    row["servers"] = _clean_servers(servers if servers is not None else row.get("servers") or [])
    row["enabled"] = bool(enabled)
    data[login] = row
    _save(data)
    return ""


def register(email: str, password: str) -> str:
    """Public signup. The person gets an empty cabinet and later adds their own servers."""
    return core.register_client(email, password)


def delete_staff(login: str) -> str:
    login = str(login or "").strip().lower()
    data = _load()
    if login not in data:
        return "Такого сотрудника нет."
    data.pop(login, None)
    _save(data)
    return ""


def authenticate_password(password: str) -> dict | None:
    """Find a client by password alone. Empty when nobody matches."""
    return core.client_by_password(password)


def find_staff(password: str) -> dict | None:
    """Find an employee by password alone. Empty when nobody matches."""
    password = password or ""
    if len(password) < 8:
        return None
    found: tuple[str, dict] | None = None
    for login, row in _load().items():
        if not isinstance(row, dict):
            continue
        stored = str(row.get("password_hash") or "")
        if not stored or not core.check_password(password, stored):
            continue
        if found is not None:
            return None
        found = (login, row)
    if found is None:
        return None
    login, row = found
    return {
        "login": login,
        "title": str(row.get("title") or login),
        "perms": [p for p in (row.get("perms") or []) if p in PERM_KEYS],
        "servers": _clean_servers(row.get("servers") or []),
        "enabled": bool(row.get("enabled", True)),
    }
