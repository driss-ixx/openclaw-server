#!/usr/bin/env python3
"""
session-sync.py — Sauvegarde/restaure la session OpenClaw dans Supabase
Usage:
  python3 session-sync.py save    # Sauvegarde ~/.openclaw vers Supabase
  python3 session-sync.py restore # Restaure depuis Supabase vers ~/.openclaw
"""

import os, sys, tarfile, base64, json, io, urllib.request, urllib.error

SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://iagsrbmeviwmozauhenk.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")
OPENCLAW_DIR = os.environ.get("OPENCLAW_DIR", os.path.expanduser("~/.openclaw"))
SESSION_ID   = os.environ.get("OPENCLAW_SESSION_ID", "main")

# Dossiers critiques à sauvegarder (pas les logs ni les sessions de chat)
INCLUDE_PATHS = [
    "devices",
    "credentials",
    "identity",
    "openclaw.json",
    "workspace/USER.md",
    "workspace/AGENTS.md",
    "workspace/MEMORY.md",
    "workspace/HEARTBEAT.md",
    "workspace/SOUL.md",
    "workspace/TOOLS.md",
    "workspace/BOOTSTRAP.md",
    "workspace/IDENTITY.md",
]

def supabase_request(method, path, body=None):
    url = f"{SUPABASE_URL}/rest/v1/{path}"
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal" if method in ("POST", "PATCH") else "",
    })
    try:
        with urllib.request.urlopen(req) as r:
            resp = r.read()
            return json.loads(resp) if resp else {}
    except urllib.error.HTTPError as e:
        print(f"❌ Supabase error {e.code}: {e.read().decode()}", file=sys.stderr)
        sys.exit(1)

def save():
    print("📦 Compression de la session OpenClaw...")
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as tar:
        for rel in INCLUDE_PATHS:
            full = os.path.join(OPENCLAW_DIR, rel)
            if os.path.exists(full):
                tar.add(full, arcname=rel)
                print(f"  ✓ {rel}")
            else:
                print(f"  - {rel} (absent)")

    encoded = base64.b64encode(buf.getvalue()).decode()
    size_kb = len(buf.getvalue()) // 1024
    print(f"📊 Taille compressée : {size_kb} KB")

    # Lire aussi openclaw.json séparément pour inspection facile
    config_path = os.path.join(OPENCLAW_DIR, "openclaw.json")
    config_json = open(config_path).read() if os.path.exists(config_path) else None

    print("☁️  Upload vers Supabase...")
    supabase_request("POST", "openclaw_session", {
        "id": SESSION_ID,
        "session_tar": encoded,
        "config_json": config_json,
        "updated_at": "now()"
    })
    # Upsert si déjà existant
    supabase_request("PATCH", f"openclaw_session?id=eq.{SESSION_ID}", {
        "session_tar": encoded,
        "config_json": config_json,
        "updated_at": "now()"
    })
    print(f"✅ Session sauvegardée ({size_kb} KB) → Supabase openclaw_session[{SESSION_ID}]")

def restore():
    print("🔍 Récupération session depuis Supabase...")
    rows = supabase_request("GET", f"openclaw_session?id=eq.{SESSION_ID}&select=session_tar,updated_at")
    if not rows:
        print("⚠️  Aucune session trouvée dans Supabase. Première exécution ?")
        return False

    row = rows[0]
    print(f"📅 Dernière sauvegarde : {row.get('updated_at', '?')}")
    encoded = row["session_tar"]
    data = base64.b64decode(encoded)
    size_kb = len(data) // 1024
    print(f"📦 Décompression ({size_kb} KB)...")

    os.makedirs(OPENCLAW_DIR, exist_ok=True)
    buf = io.BytesIO(data)
    with tarfile.open(fileobj=buf, mode="r:gz") as tar:
        tar.extractall(OPENCLAW_DIR)
    print(f"✅ Session restaurée dans {OPENCLAW_DIR}")
    return True

def auto_save_loop(interval_minutes=5):
    """Sauvegarde automatique toutes les N minutes (pour le serveur)"""
    import time
    print(f"🔄 Auto-save activé (toutes les {interval_minutes} min)")
    while True:
        time.sleep(interval_minutes * 60)
        try:
            save()
        except Exception as e:
            print(f"⚠️  Auto-save échoué : {e}", file=sys.stderr)

if __name__ == "__main__":
    if not SUPABASE_KEY:
        print("❌ SUPABASE_SERVICE_KEY manquant", file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1] if len(sys.argv) > 1 else "help"

    if cmd == "save":
        save()
    elif cmd == "restore":
        restore()
    elif cmd == "watch":
        minutes = int(sys.argv[2]) if len(sys.argv) > 2 else 5
        auto_save_loop(minutes)
    else:
        print(__doc__)
