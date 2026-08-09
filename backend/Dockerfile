# Multi-stage build — dev deps only exist in `deps`/`build`, never in the
# final image. `prisma generate` needs network access to download its
# platform engine binary (same one-time fetch noted in docs/ROADMAP.md
# Phase 2) — done once here in `deps`, then the generated client/engine
# and the `prisma` CLI itself (needed at container startup for `migrate
# deploy`) are copied into the slim runtime stage rather than
# re-fetched, so the running container never needs outbound network
# access to install anything.

FROM node:20-alpine AS deps
WORKDIR /app
# Prisma's query engine is a real native binary — without openssl present,
# `prisma generate` can't detect Alpine's libssl version and silently
# defaults to the wrong engine variant, which then fails at runtime with
# "Could not parse schema engine response" (confirmed the hard way:
# omitting this line boots cleanly but every Prisma call then crashes).
RUN apk add --no-cache openssl
COPY package.json package-lock.json ./
COPY prisma ./prisma
RUN npm ci
RUN npx prisma generate

FROM node:20-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
RUN apk add --no-cache openssl
RUN addgroup -S ditto && adduser -S ditto -G ditto
# Ownership is set per-file at COPY time (--chown) below, never via a
# separate `chown -R` over the whole node_modules tree afterward — that
# recursive walk over hundreds of packages took 30+ minutes on this
# machine's Docker Desktop/WSL2 filesystem and never finished. `chown`
# on this still-empty WORKDIR is instant since there's nothing in it yet.
RUN chown ditto:ditto /app

COPY --chown=ditto:ditto package.json package-lock.json ./
USER ditto
# Root's default npm cache dir isn't writable by this user; /tmp is.
ENV npm_config_cache=/tmp/.npm
RUN npm ci --omit=dev

# Overwrite with the already-generated Prisma client/engine and CLI from
# `deps`, rather than letting a fresh `npm ci` leave an ungenerated stub.
COPY --chown=ditto:ditto --from=deps /app/node_modules/@prisma ./node_modules/@prisma
COPY --chown=ditto:ditto --from=deps /app/node_modules/.prisma ./node_modules/.prisma
COPY --chown=ditto:ditto --from=deps /app/node_modules/prisma ./node_modules/prisma

COPY --chown=ditto:ditto --from=build /app/dist ./dist
COPY --chown=ditto:ditto prisma ./prisma
COPY --chown=ditto:ditto docker-entrypoint.sh ./
RUN chmod +x ./docker-entrypoint.sh

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

ENTRYPOINT ["./docker-entrypoint.sh"]
