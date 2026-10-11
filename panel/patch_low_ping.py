"""Send new clients to the closest stable server and cut extra latency."""
import subprocess
import awgcore as core

# Lower number is chosen first. Measured from the client network:
# s6 ~350 ms stable, s5 similar but drops packets, the rest ~480-530 ms.
PRIORITY = {
    "s6": 0,
    "s5": 4,
    "s2": 6,
    "s1": 7,
    "s4": 9,
}

PROBE = r"""
python3 - << 'PY'
from pathlib import Path
from collections import Counter
mtu, dns = Counter(), Counter()
root = Path("/root/awg")
n = 0
if root.exists():
    for p in root.glob("*.conf"):
        n += 1
        for line in p.read_text(errors="replace").splitlines():
            s = line.strip()
            if s.upper().startswith("MTU"):
                mtu[s.replace(" ", "")] += 1
            elif s.upper().startswith("DNS"):
                dns[s.split("=", 1)[-1].strip()] += 1
print("FILES", n)
print("MTU", dict(mtu))
print("DNS", dict(dns))
PY
"""

FIX = r"""
sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null
sysctl -w net.core.default_qdisc=fq >/dev/null
printf '%s\n' 'net.core.default_qdisc=fq' 'net.ipv4.tcp_congestion_control=bbr' > /etc/sysctl.d/99-tez-latency.conf
if ip link show awg0 >/dev/null 2>&1; then
  tc qdisc replace dev awg0 root fq || true
fi
python3 - << 'PY'
from pathlib import Path
changed = 0
root = Path("/root/awg")
if root.exists():
    for p in root.glob("*.conf"):
        lines = p.read_text(errors="replace").splitlines(keepends=True)
        out = []
        dirty = False
        for line in lines:
            raw = line.strip().replace(" ", "")
            if raw.upper().startswith("MTU=") and raw.upper() not in ("MTU=1280",):
                try:
                    val = int(raw.split("=", 1)[1])
                except ValueError:
                    val = 0
                if val > 1280:
                    out.append("MTU = 1280\n")
                    dirty = True
                    continue
            out.append(line if line.endswith("\n") else line + "\n")
        if dirty:
            p.write_text("".join(out), encoding="utf-8")
            changed += 1
print("MTU_UPDATED", changed)
PY
"""


def run(srv: dict, script: str) -> str:
    if srv.get("kind") == "ssh":
        cmd = core.ssh_prefix(srv) + [script]
    else:
        cmd = ["bash", "-lc", script]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    except subprocess.TimeoutExpired:
        return "TIMEOUT"
    text = ((res.stdout or "") + (res.stderr or "")).strip()
    return "\n".join(
        line for line in text.splitlines()
        if not any(x in line for x in ("PrivateKey", "PresharedKey", "BEGIN "))
    )[-500:]


def main() -> None:
    for sid, pri in PRIORITY.items():
        err = core.set_server_priority(sid, pri)
        print(f"PRI {sid} {pri} {err or 'OK'}")
    for sid, srv in core.servers().items():
        if not core.accepts_shop_clients(srv):
            print(f"SKIP {sid}")
            continue
        print(f"== {sid}")
        print(run(srv, PROBE) or "NO_PROBE")
        print(run(srv, FIX) or "FIX_OK")
    print("PING_PATCHED")


if __name__ == "__main__":
    main()
