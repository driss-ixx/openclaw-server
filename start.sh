#!/bin/bash
# start.sh — Script de démarrage OpenClaw sur Railway
set -e

SYNC="/home/node/session-sync.py"

echo "🚀 OpenClaw démarrage..."

# Restaurer la session depuis Supabase
if [ -n "$SUPABASE_SERVICE_KEY" ]; then
  echo "📥 Restauration session depuis Supabase..."
  python3 "$SYNC" restore || echo "⚠️  Pas de session sauvegardée, démarrage fresh"
else
  echo "⚠️  SUPABASE_SERVICE_KEY manquant — session locale uniquement"
fi

# Lancer l'auto-save en arrière-plan (toutes les 5 min)
if [ -n "$SUPABASE_SERVICE_KEY" ]; then
  python3 "$SYNC" watch 5 &
  SYNC_PID=$!
  echo "💾 Auto-save lancé (PID $SYNC_PID)"
fi

# Trap SIGTERM pour sauvegarder avant l'arrêt
cleanup() {
  echo "🛑 Arrêt détecté — sauvegarde session finale..."
  [ -n "$SUPABASE_SERVICE_KEY" ] && python3 "$SYNC" save || true
  exit 0
}
trap cleanup SIGTERM SIGINT

# Limiter la mémoire Node.js pour le free tier (1GB RAM)
export NODE_OPTIONS="--max-old-space-size=850"

echo "🤖 Lancement OpenClaw gateway..."
openclaw gateway run --bind lan --port 18789 --force
