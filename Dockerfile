FROM node:24-bookworm-slim

ARG CACHEBUST=20260313c
# Installer git + Python3 (git requis par npm install -g openclaw)
RUN echo "cachebust=$CACHEBUST" && apt-get update && apt-get install -y git openssh-client python3 --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw@latest

# Copier les scripts
COPY session-sync.py /app/session-sync.py
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

RUN groupadd -r openclaw && useradd -r -g openclaw -m -d /home/node node
USER node
WORKDIR /home/node

EXPOSE 18789

HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:18789/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["/app/start.sh"]
