FROM ghcr.io/openclaw/openclaw:latest

USER root

COPY session-sync.py /home/node/session-sync.py
COPY --chmod=755 start.sh /home/node/start.sh

ENV HOME=/home/node
ENV OPENCLAW_DIR=/home/node/.openclaw

USER node
WORKDIR /home/node

EXPOSE 18789

HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:18789/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["/home/node/start.sh"]
