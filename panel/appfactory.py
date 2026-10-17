"""Build a branded client APK for the admin panel.

The template APK already contains assets/brand.json. This module writes the
owner's name, shop address, support contact and colors into that file, sets
the phone icon label, and signs the package with the same key as TEZVPN.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path

ROOT = Path("/root/vpn-panel")
TEMPLATE = ROOT / "apk-template" / "base.apk"
KEYSTORE = ROOT / "apk-template" / "release.keystore"
BRAND_FILE = ROOT / "data" / "app_brand.json"
OUT_DIR = ROOT / "apk-out"
TOOLS = ROOT / "apk-tools"
APKTOOL = TOOLS / "apktool.jar"
VERSION = "1.0.5"

KS_PASS = "android"
KEY_ALIAS = "androiddebugkey"

DEFAULT_BRAND = {
    "appName": "SULTAN VPN",
    "shopUrl": "https://188-116-24-47.sslip.io",
    "support": "BarzuRizoev",
    "tenant": "tez",
    "gold": "#F5C518",
    "navy": "#0C2438",
    "card": "#16324F",
}

_USER = re.compile(r"^[A-Za-z0-9_]{2,32}$")
_COLOR = re.compile(r"^#[0-9A-Fa-f]{6}$")


def load_brand() -> dict[str, str]:
    brand = dict(DEFAULT_BRAND)
    try:
        saved = json.loads(BRAND_FILE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        saved = {}
    if isinstance(saved, dict):
        for key in DEFAULT_BRAND:
            value = saved.get(key)
            if isinstance(value, str) and value.strip():
                brand[key] = value.strip()
    return brand


def validate_brand(form: dict) -> tuple[dict[str, str] | None, str]:
    name = " ".join(str(form.get("appName") or "").split())
    if not (2 <= len(name) <= 24) or any(ch in name for ch in '<>&"\''):
        return None, "Название: 2–24 символа, без кавычек и знаков < > &."
    shop = str(form.get("shopUrl") or "").strip().rstrip("/")
    uri_ok = shop.startswith("https://") and " " not in shop and len(shop) <= 160
    host = shop[8:].split("/")[0] if uri_ok else ""
    if not uri_ok or "." not in host:
        return None, "Адрес магазина должен начинаться с https://."
    support = str(form.get("support") or "").strip()
    if support.startswith("@"):
        support = support[1:]
    if not _USER.match(support):
        return None, "Поддержка: имя Telegram латиницей, без @."
    colors = {}
    for key in ("gold", "navy", "card"):
        value = str(form.get(key) or "").strip()
        if not value.startswith("#"):
            value = "#" + value
        if not _COLOR.match(value):
            return None, "Цвет укажите как #RRGGBB."
        colors[key] = value.upper()
    return {
        "appName": name,
        "shopUrl": shop,
        "support": support,
        "tenant": "tez",
        "gold": colors["gold"],
        "navy": colors["navy"],
        "card": colors["card"],
    }, ""


def save_brand(brand: dict[str, str]) -> None:
    BRAND_FILE.parent.mkdir(parents=True, exist_ok=True)
    BRAND_FILE.write_text(json.dumps(brand, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def apk_filename(app_name: str) -> str:
    stem = re.sub(r"[^\w]+", "", app_name, flags=re.UNICODE) or "TEZVPN"
    return f"{stem}-{VERSION}.apk"


def latest_apk() -> Path | None:
    if not OUT_DIR.is_dir():
        return None
    files = [p for p in OUT_DIR.glob("*.apk") if p.is_file()]
    if not files:
        return None
    return max(files, key=lambda p: p.stat().st_mtime)


def _java() -> str:
    java = shutil.which("java")
    if not java:
        raise RuntimeError("На сервере нет Java. Сборка APK недоступна.")
    return java


def _tool(name: str) -> Path:
    matches = sorted(TOOLS.rglob(name))
    for path in matches:
        if path.is_file() and path.name == name:
            return path
    raise RuntimeError(f"Не найден инструмент {name}.")


def _run(cmd: list[str], cwd: Path | None = None) -> None:
    env = os.environ.copy()
    bins = [str(p.parent) for p in TOOLS.rglob("zipalign") if p.is_file()]
    if bins:
        env["PATH"] = bins[0] + os.pathsep + env.get("PATH", "")
    proc = subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=300,
    )
    if proc.returncode != 0:
        tail = (proc.stdout or "")[-1200:]
        raise RuntimeError(tail.strip() or f"Команда завершилась с кодом {proc.returncode}")


def _brand_entry(apk: Path) -> str:
    with zipfile.ZipFile(apk) as zf:
        names = [n for n in zf.namelist() if n.endswith("assets/brand.json")]
    if not names:
        raise RuntimeError("В шаблоне приложения нет файла настроек.")
    return names[0]


def _xml_attr(value: str) -> str:
    return (
        value.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def _set_launcher_name(decoded: Path, app_name: str) -> None:
    manifest = decoded / "AndroidManifest.xml"
    text = manifest.read_text(encoding="utf-8")
    label = _xml_attr(app_name)
    updated, count = re.subn(
        r'android:label="[^"]*"',
        f'android:label="{label}"',
        text,
        count=1,
    )
    if count != 1:
        raise RuntimeError("Не удалось записать название на иконку.")
    manifest.write_text(updated, encoding="utf-8")
    for strings in decoded.rglob("strings.xml"):
        raw = strings.read_text(encoding="utf-8")
        new, n = re.subn(
            r'(<string name="app_name"[^>]*>)(.*?)(</string>)',
            rf"\1{label}\3",
            raw,
            count=1,
        )
        if n:
            strings.write_text(new, encoding="utf-8")


def _sign(unsigned: Path, dest: Path) -> None:
    if not KEYSTORE.is_file():
        raise RuntimeError("Нет ключа подписи приложения.")
    aligned = dest.with_suffix(".aligned.apk")
    _run([str(_tool("zipalign")), "-p", "-f", "4", str(unsigned), str(aligned)])
    _run([
        _java(), "-Xmx256m", "-jar", str(_tool("apksigner.jar")),
        "sign",
        "--ks", str(KEYSTORE),
        "--ks-pass", f"pass:{KS_PASS}",
        "--key-pass", f"pass:{KS_PASS}",
        "--ks-key-alias", KEY_ALIAS,
        "--out", str(dest),
        str(aligned),
    ])
    aligned.unlink(missing_ok=True)
    _run([_java(), "-Xmx256m", "-jar", str(_tool("apksigner.jar")), "verify", "--verbose", str(dest)])


def build(brand: dict[str, str]) -> Path:
    if not TEMPLATE.is_file():
        raise RuntimeError("Шаблон приложения не загружен на сервер.")
    if not APKTOOL.is_file():
        raise RuntimeError("apktool не установлен.")
    payload = (json.dumps(brand, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    _brand_entry(TEMPLATE)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="tezapk-") as tmp:
        work = Path(tmp)
        decoded = work / "decoded"
        _run([
            _java(), "-Xmx512m", "-jar", str(APKTOOL),
            "d", "-f", "-s", str(TEMPLATE), "-o", str(decoded),
        ])
        _set_launcher_name(decoded, brand["appName"])
        brand_path = next(decoded.rglob("brand.json"))
        brand_path.write_bytes(payload)
        unsigned = work / "unsigned.apk"
        _run([
            _java(), "-Xmx512m", "-jar", str(APKTOOL),
            "b", str(decoded), "-o", str(unsigned),
        ])
        final = work / apk_filename(brand["appName"])
        _sign(unsigned, final)
        published = OUT_DIR / final.name
        part = published.with_suffix(".apk.part")
        shutil.copy2(final, part)
        part.replace(published)
    for old in OUT_DIR.glob("*.apk"):
        if old != published:
            old.unlink()
    return published
