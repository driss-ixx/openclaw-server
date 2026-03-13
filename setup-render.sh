#!/bin/bash
# setup-render.sh — Prépare et déploie OpenClaw sur Render.com
# Exécuter UNE SEULE FOIS depuis le Mac de Driss

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
GITHUB_USER="driss-ixx"
REPO_NAME="openclaw-server"

echo "📦 Initialisation du repo GitHub..."
cd "$REPO_DIR"

if [ ! -d ".git" ]; then
  git init
  git add .
  git commit -m "Initial OpenClaw server config"
  gh repo create "$GITHUB_USER/$REPO_NAME" --public --source=. --push
  echo "✅ Repo GitHub créé : github.com/$GITHUB_USER/$REPO_NAME"
else
  git add .
  git commit -m "Update config" --allow-empty
  git push
  echo "✅ Repo mis à jour"
fi

echo ""
echo "🚀 Étapes suivantes sur render.com :"
echo ""
echo "  1. Va sur render.com → 'New Web Service'"
echo "  2. Connecte ton GitHub → sélectionne '$REPO_NAME'"
echo "  3. Variables d'environnement à configurer :"
echo "     OPENCLAW_GATEWAY_TOKEN = (dans ~/.openclaw/openclaw.json → gateway.auth.token)"
echo "     GROQ_API_KEY           = (dans ~/.openclaw/openclaw.json → models.providers.groq.apiKey)"
echo "     OPENROUTER_API_KEY     = (dans ~/.zshrc → OPENROUTER_API_KEY)"
echo ""
echo "  4. Après le deploy → Shell Render :"
echo "     openclaw whatsapp pair"
echo "     → Scanne le QR code → WhatsApp connecté 24/7 !"
echo ""
echo "  5. UptimeRobot (gratuit) → ping le /healthz toutes les 5min"
echo "     https://uptimerobot.com"
