FROM ghcr.io/openclaw/openclaw:latest

# Copier les scripts de session sync
COPY session-sync.py /app/session-sync.py
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENV HOME=/home/node
ENV OPENCLAW_DIR=/home/node/.openclaw

EXPOSE 18789

HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:18789/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["/app/start.sh"]
