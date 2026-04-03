# We use node-slim for a tiny production image
FROM node:20-slim
WORKDIR /app

# Since CircleCI already built the app, we just copy the output
# This takes everything INSIDE app/.output and puts it INSIDE /app
COPY app/.output ./

ENV PORT=3000
ENV HOST=0.0.0.0
ENV NODE_ENV=production

EXPOSE 3000

# Start using your Sentry instrumentation
CMD ["node", "--import", "./server/instrument.server.mjs", "./server/index.mjs"]