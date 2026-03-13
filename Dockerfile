FROM node:24-bookworm-slim

RUN npm install -g openclaw@latest

RUN groupadd -r openclaw && useradd -r -g openclaw -m -d /home/node node

USER node
WORKDIR /home/node

# Config is mounted at /home/node/.openclaw (Render persistent disk)
# On first run: openclaw gateway run → scan QR code via Render shell

EXPOSE 18789

HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:18789/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["openclaw", "gateway", "run", "--bind", "lan", "--port", "18789", "--force"]
