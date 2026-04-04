# Use node-slim for small production image
FROM node:20-slim

# Install curl + ca-certificates
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# --- Download RDS CA certificate first ---
# This layer rarely changes, so Docker caches it
RUN mkdir -p /app/certs && \
    curl -fSL https://truststore.pki.rds.amazonaws.com/eu-west-3/eu-west-3-bundle.pem \
    -o /app/certs/rds-ca.pem

# --- Copy app last ---
# Copy only the already built app output to leverage layer caching
COPY app/.output ./

# Set environment variables
ENV PORT=3000
ENV HOST=0.0.0.0
ENV NODE_ENV=production
ENV DB_CA_CERT=/app/certs/rds-ca.pem

# Expose port
EXPOSE 3000

# Start app with Sentry instrumentation
CMD ["node", "--import", "./server/instrument.server.mjs", "./server/index.mjs"]