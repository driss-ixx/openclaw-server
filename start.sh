#!/bin/bash
# start.sh — Script de démarrage OpenClaw sur Render
# 1. Restaure la session depuis Supabase
# 2. Lance OpenClaw gateway
# 3. Auto-save session en arrière-plan toutes les 5 min

set -e

echo "🚀 OpenClaw démarrage..."

# Restaurer la session depuis Supabase
if [ -n "$SUPABASE_SERVICE_KEY" ]; then
  echo "📥 Restauration session depuis Supabase..."
  python3 /app/session-sync.py restore || echo "⚠️  Pas de session sauvegardée, démarrage fresh"
else
  echo "⚠️  SUPABASE_SERVICE_KEY manquant — session locale uniquement"
fi

# Lancer l'auto-save en arrière-plan (toutes les 5 min)
if [ -n "$SUPABASE_SERVICE_KEY" ]; then
  python3 /app/session-sync.py watch 5 &
  SYNC_PID=$!
  echo "💾 Auto-save lancé (PID $SYNC_PID)"
fi

# Trap SIGTERM pour sauvegarder avant l'arrêt
cleanup() {
  echo "🛑 Arrêt détecté — sauvegarde session finale..."
  if [ -n "$SUPABASE_SERVICE_KEY" ]; then
    python3 /app/session-sync.py save || true
  fi
  exit 0
}
trap cleanup SIGTERM SIGINT

# Démarrer OpenClaw gateway
echo "🤖 Lancement OpenClaw gateway..."
openclaw gateway run --bind lan --port 18789 --force
