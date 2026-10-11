"""One paid access can be online on 3 devices. Each device gets its own peer."""
from pathlib import Path
import re
import shutil

ROOT = Path("/root/vpn-panel")
CORE = ROOT / "awgcore.py"
SHOP = ROOT / "webshop.py"
PANEL = ROOT / "panel.py"

HELPERS = '''
DEVICES_PER_CONFIG = 3


def device_limit_for(spec: dict | None) -> int:
    """At least 3 devices on one access. Larger tariffs stay larger."""
    base = _devices((spec or {}).get("devices"), 1)
    return max(DEVICES_PER_CONFIG, base)


def _slot_table(conn) -> None:
    conn.execute(
        """CREATE TABLE IF NOT EXISTS shop_peer_slots (
            ref TEXT NOT NULL,
            fp TEXT NOT NULL,
            slot INTEGER NOT NULL,
            created INTEGER NOT NULL,
            PRIMARY KEY (ref, fp)
        )"""
    )


def _add_peers(srv: dict, names: list[str], need: int, display: str, expires: str = "") -> list[str]:
    """Add missing peers. Existing names stay. Does not restart the node."""
    names = [n for n in names if n]
    if len(names) >= need or not srv:
        return names
    listed, _problem = list_clients(srv)
    taken = set(names)
    for item in listed or []:
        if isinstance(item, dict) and item.get("name"):
            taken.add(str(item["name"]))
    try:
        free = max(0, server_limit(srv) - len(taken))
    except Exception:
        free = need
    room = min(need, len(names) + free)
    created = list(names)
    display = (display or "client").strip()[:24]
    for i in range(len(names), room):
        note = f"{display}-{i + 1}"
        name = client_name_for(secrets.token_hex(3), taken, note)
        if not NAME_RE.match(name):
            name = ("d" + secrets.token_hex(4) + str(i + 1))[:32]
        args = ["add", name]
        if expires:
            args.append(f"--expires={expires}")
        rc, data = manage_json(srv, *args)
        if rc != 0 and expires == "365d":
            rc, data = manage_json(srv, "add", name, "--expires=360d")
        if rc != 0:
            break
        provision_client(srv, name)
        if ".conf" not in client_bundle(srv, name):
            run_manage(srv, "remove", name, "--yes")
            forget(srv)
            break
        taken.add(name)
        created.append(name)
    forget(srv)
    return created


def ensure_order_peers(row) -> list[str]:
    """Make sure a fulfilled order has one peer per device slot."""
    if row is None:
        return []
    names = split_client_names(row["client"] if row["client"] else "")
    if not row["sid"] or row["sid"] not in servers():
        return names
    plans = shop_plans(order_seller(row))
    spec = plans.get(row["plan"]) or {}
    need = device_limit_for(spec)
    if len(names) >= need:
        return names
    with _shop_lock:
        fresh = shop_get_order(row["id"])
        if fresh is not None and fresh["client"]:
            names = split_client_names(fresh["client"])
        if len(names) >= need:
            return names
        srv = servers().get(row["sid"])
        display = (row["tg_name"] or "client") if row["tg_name"] is not None else "client"
        names = _add_peers(srv, names, need, str(display), str(spec.get("expires") or ""))
        joined = ",".join(names)
        if fresh is None or joined != (fresh["client"] or ""):
            with db() as conn:
                conn.execute(
                    "UPDATE shop_orders SET client=? WHERE id=?",
                    (joined, row["id"]),
                )
    return names


def expand_key_peers(code: str) -> None:
    row = get_key(code)
    if row is None or not row["client"] or row["sid"] not in servers():
        return
    names = split_client_names(row["client"])
    if len(names) >= DEVICES_PER_CONFIG:
        return
    with _shop_lock:
        row = get_key(code)
        if row is None or not row["client"]:
            return
        names = split_client_names(row["client"])
        if len(names) >= DEVICES_PER_CONFIG:
            return
        srv = servers().get(row["sid"])
        names = _add_peers(srv, names, DEVICES_PER_CONFIG, (row["note"] or "key")[:24], "")
        with db() as conn:
            conn.execute(
                "UPDATE keys SET client=? WHERE code=?",
                (",".join(names), code),
            )


def pick_peer_for_fp(ref: str, fp: str, names: list[str]) -> tuple[int, str]:
    """Bind this phone to a free slot. Empty error means the slot is usable."""
    names = [n for n in names if n]
    if not names:
        return 0, "Конфиг ещё не готов."
    fp = _norm_fp(fp)
    if not fp:
        return 0, ""
    with db() as conn:
        _slot_table(conn)
        row = conn.execute(
            "SELECT slot FROM shop_peer_slots WHERE ref=? AND fp=?",
            (ref, fp),
        ).fetchone()
        if row is not None and int(row["slot"]) < len(names):
            return int(row["slot"]), ""
        used = {
            int(r["slot"])
            for r in conn.execute(
                "SELECT slot FROM shop_peer_slots WHERE ref=?", (ref,)
            )
        }
        for slot in range(len(names)):
            if slot not in used:
                conn.execute(
                    "INSERT OR REPLACE INTO shop_peer_slots (ref, fp, slot, created) VALUES (?,?,?,?)",
                    (ref, fp, slot, int(time.time())),
                )
                return slot, ""
    return 0, f"К этому конфигу уже подключены {len(names)} устройства."


'''

NEW_CONFIG = '''def config_payload(row, fp: str = "") -> dict | None:
    if row is None or (row["status"] or "") != "fulfilled" or not row["client"]:
        return None
    sid = row["sid"] or ""
    srv = core.servers().get(sid)
    if not srv:
        return None
    names = core.ensure_order_peers(row)
    if not names:
        return None
    slot, limit_err = core.pick_peer_for_fp(f"order:{row['id']}", fp, names)
    if limit_err:
        return {
            "sid": sid,
            "devices": [],
            "error": limit_err,
            "limit": len(names),
            "slot": 0,
        }
    picked = [names[slot]] if fp else list(names)
    devices = []
    for name in picked:
        bundle = core.client_bundle(srv, name)
        conf = bundle.get(".conf")
        vpnuri = bundle.get(".vpnuri")
        sub = bundle.get(".sub")
        png = bundle.get(".png") or bundle.get(".vpnuri.png")
        devices.append({
            "name": name,
            "vpnuri": vpnuri.decode("utf-8", "replace").strip() if vpnuri else "",
            "sub": sub.decode("utf-8", "replace").strip() if sub else "",
            "conf": conf.decode("utf-8", "replace") if conf else "",
            "has_qr": bool(png),
            "qr_url": f"/api/qr/{urllib.parse.quote(sid)}/{urllib.parse.quote(name)}" if png else "",
        })
    return {
        "sid": sid,
        "devices": devices,
        "error": "",
        "limit": len(names),
        "slot": slot + 1,
    }


'''


def backup(path: Path) -> None:
    dest = path.with_name(path.name + ".bak-slots")
    if not dest.exists():
        shutil.copy2(path, dest)


def patch_core() -> None:
    text = CORE.read_text(encoding="utf-8")
    if "def device_limit_for(" not in text:
        anchor = "def fulfill_shop_order(oid: str)"
        if anchor not in text:
            raise SystemExit("fulfill anchor missing")
        text = text.replace(anchor, HELPERS + anchor, 1)
        text = text.replace(
            "need = _devices(spec.get(\"devices\"), 1)\n",
            "need = device_limit_for(spec)\n",
            1,
        )
    old_claim = '''        if row["client"]:
            if row["sid"] in servers():
                touch_key(code)
                return row, ""
'''
    new_claim = '''        if row["client"]:
            if row["sid"] in servers():
                expand_key_peers(code)
                touch_key(code)
                return get_key(code), ""
'''
    if old_claim in text:
        text = text.replace(old_claim, new_claim, 1)
    old_ret = '''                (now, sid, name, now, code),
            )
        return get_key(code), ""
'''
    new_ret = '''                (now, sid, name, now, code),
            )
        expand_key_peers(code)
        return get_key(code), ""
'''
    if old_ret in text and "expand_key_peers(code)\n        return get_key(code), \"\"" not in text:
        text = text.replace(old_ret, new_ret, 1)
    old_revoke = '''    if drop_client and row["client"] and row["sid"] in servers():
        srv = servers()[row["sid"]]
        rc, out = run_manage(srv, "remove", row["client"], "--yes")
        drop_stack_client(srv, row["client"])
        forget(srv)
        if rc != 0:
            problem = f"Клиент {row['client']} не удалён с сервера: {out[:200]}"
'''
    new_revoke = '''    if drop_client and row["client"] and row["sid"] in servers():
        srv = servers()[row["sid"]]
        for name in split_client_names(row["client"]):
            rc, out = run_manage(srv, "remove", name, "--yes")
            drop_stack_client(srv, name)
            if rc != 0:
                problem = f"Клиент {name} не удалён с сервера: {out[:200]}"
        forget(srv)
'''
    if old_revoke in text:
        text = text.replace(old_revoke, new_revoke, 1)
    CORE.write_text(text, encoding="utf-8")
    print("CORE_OK")


def patch_shop() -> None:
    text = SHOP.read_text(encoding="utf-8")
    if "def config_payload(row, fp: str = \"\")" not in text:
        start = text.find("def config_payload(row)")
        end = text.find("\ndef trial_payload(")
        if start < 0 or end < 0:
            raise SystemExit("config_payload block missing")
        text = text[:start] + NEW_CONFIG + text[end + 1 :]
    old_state = '''            return self.json({
                "plans": plans_payload(t),
                "pay": pay_info(t),
                "order": order_dict(row) if row else None,
                "orders": orders,
                "config": config_payload(row),
'''
    new_state = '''            cfg = config_payload(row, fp)
            if cfg and cfg.get("error") and not flash:
                flash = cfg["error"]
            return self.json({
                "plans": plans_payload(t),
                "pay": pay_info(t),
                "order": order_dict(row) if row else None,
                "orders": orders,
                "config": cfg,
'''
    if old_state in text:
        text = text.replace(old_state, new_state, 1)
    old_api = "            cfg = config_payload(row)\n"
    new_api = "            cfg = config_payload(row, _fp)\n"
    if old_api in text:
        text = text.replace(old_api, new_api, 1)
    old_js = '''  if(!cfg || !cfg.devices || !cfg.devices.length){
    box.innerHTML = '<p class="muted">Конфиг ещё собирается…</p>';
    return;
  }
  box.innerHTML = '';
  cfg.devices.forEach((d, i) => {
    const card = document.createElement('div');
    card.className = 'card';
    card.style.margin = '10px 0';
    const h = document.createElement('h2');
    h.style.margin = '0 0 6px';
    h.textContent = `Устройство ${i+1}: ${d.name}`;
'''
    new_js = '''  if(cfg && cfg.error){
    box.textContent = '';
    const err = document.createElement('p');
    err.className = 'muted';
    err.textContent = cfg.error;
    box.appendChild(err);
    return;
  }
  if(!cfg || !cfg.devices || !cfg.devices.length){
    box.innerHTML = '<p class="muted">Конфиг ещё собирается…</p>';
    return;
  }
  box.innerHTML = '';
  const note = document.createElement('p');
  note.className = 'muted';
  note.textContent = 'Один доступ открывается на ' + (cfg.limit || 3) + ' устройствах. На каждом телефоне откройте кабинет — подставится свой конфиг.';
  box.appendChild(note);
  cfg.devices.forEach((d, i) => {
    const card = document.createElement('div');
    card.className = 'card';
    card.style.margin = '10px 0';
    const h = document.createElement('h2');
    h.style.margin = '0 0 6px';
    const n = (cfg.devices.length === 1 && cfg.slot) ? cfg.slot : (i + 1);
    h.textContent = 'Устройство ' + n + ' из ' + (cfg.limit || cfg.devices.length);
'''
    if old_js in text:
        text = text.replace(old_js, new_js, 1)
    elif "Один доступ открывается на" not in text:
        raise SystemExit("config js missing")
    SHOP.write_text(text, encoding="utf-8")
    print("SHOP_OK")


def patch_panel() -> None:
    text = PANEL.read_text(encoding="utf-8")
    old_map = '''        by_client = {}
        for row in core.all_keys():
            if row["sid"] == sid and row["client"]:
                by_client[row["client"]] = row
'''
    new_map = '''        by_client = {}
        for row in core.all_keys():
            if row["sid"] == sid and row["client"]:
                for part in core.split_client_names(row["client"]):
                    by_client[part] = row
'''
    if old_map in text:
        text = text.replace(old_map, new_map, 1)
    old_link = '''            client_cell = esc(row["client"] or "—")
            if row["client"] and row["sid"] in core.servers():
                link = f'/s/{row["sid"]}/c/{urllib.parse.quote(row["client"])}'
                client_cell = f'<a href="{link}">{esc(row["client"])}</a>'
'''
    new_link = '''            client_cell = esc(row["client"] or "—")
            if row["client"] and row["sid"] in core.servers():
                links = []
                for part in core.split_client_names(row["client"]):
                    link = f'/s/{row["sid"]}/c/{urllib.parse.quote(part)}'
                    links.append(f'<a href="{link}">{esc(part)}</a>')
                client_cell = ", ".join(links)
'''
    if old_link in text:
        text = text.replace(old_link, new_link, 1)
    old_order = '''            client = row["client"] or "—"
            if row["client"] and row["sid"] in self.visible_servers():
                link = f'/s/{row["sid"]}/c/{urllib.parse.quote(row["client"])}'
                client = f'<a href="{link}">{esc(row["client"])}</a>'
'''
    new_order = '''            client = row["client"] or "—"
            if row["client"] and row["sid"] in self.visible_servers():
                links = []
                for part in core.split_client_names(row["client"]):
                    link = f'/s/{row["sid"]}/c/{urllib.parse.quote(part)}'
                    links.append(f'<a href="{link}">{esc(part)}</a>')
                client = ", ".join(links)
'''
    if old_order in text:
        text = text.replace(old_order, new_order, 1)
    text = text.replace("for n in (1, 2, 3, 4)", "for n in (3, 4)", 1)
    PANEL.write_text(text, encoding="utf-8")
    print("PANEL_OK")


def bump_plans() -> None:
    import awgcore as core
    plans = core.shop_plans()
    for pid, spec in plans.items():
        dev = int(spec.get("devices") or 1)
        if dev >= 3:
            print(f"PLAN {pid} {dev}")
            continue
        title = re.sub(r"\d+\s*устр\.", "3 устр.", str(spec.get("title") or pid))
        if "устр" not in title.lower():
            title = f"{title} · 3 устр."
        err = core.update_plan_prices(pid, spec["tjs"], spec["cny"], devices=3, title=title)
        print(f"PLAN {pid} -> 3 {err or 'OK'}")


if __name__ == "__main__":
    for path in (CORE, SHOP, PANEL):
        backup(path)
    patch_core()
    patch_shop()
    patch_panel()
    import py_compile
    py_compile.compile(str(CORE), doraise=True)
    py_compile.compile(str(SHOP), doraise=True)
    py_compile.compile(str(PANEL), doraise=True)
    print("COMPILE_OK")
    bump_plans()
    print("THREE_DEVICES")
