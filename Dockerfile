FROM node:22-alpine AS deps

WORKDIR /app

COPY app/package*.json ./

RUN npm ci --omit=dev


FROM node:22-alpine AS runtime

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

RUN apk upgrade --no-cache && \
    addgroup -S appgroup && \
    adduser -S appuser -G appgroup && \
    rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/bin/npm \
           /usr/local/bin/npx \
           /opt/yarn* \
           /usr/local/bin/yarn \
           /usr/local/bin/yarnpkg \
           /usr/local/lib/node_modules/corepack \
           /usr/local/bin/corepack

COPY --from=deps /app/node_modules ./node_modules
COPY app/server.js ./server.js
COPY app/package*.json ./

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
