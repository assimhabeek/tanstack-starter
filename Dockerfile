# Stage 1: Build
FROM node:20-slim AS builder
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
WORKDIR /build

COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY app/package.json ./app/
RUN pnpm install --frozen-lockfile

COPY app/ ./app/
WORKDIR /build/app
RUN pnpm build 

# Stage 2: Runtime (Ultra Clean)
FROM node:20-slim
WORKDIR /app

# We only copy .output. Because of 'noExternal', 
# instrument.server.mjs now has everything it needs inside the folder.
COPY --from=builder /build/app/.output ./

ENV PORT=3000
ENV HOST=0.0.0.0

EXPOSE 3000
ENV NODE_ENV=production

# Recommended: Sentry runs as a loader, but the files are internal to the bundle
CMD ["node", "--import", "./server/instrument.server.mjs", "./server/index.mjs"]