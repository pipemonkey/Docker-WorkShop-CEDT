# syntax=docker/dockerfile:1.7

# =============================================================================
# Builder stage — installs production dependencies only, on a fresh Node base.
# =============================================================================

# Step 4a: pinned Node base image and named builder stage.
FROM node:24.22.2-bookworm-slim AS builder
#   Do NOT use `node:latest` — we want reproducible builds across the cohort.

WORKDIR /app

# Step 4b: install locked production dependencies.
COPY app/package*.json ./
RUN npm ci --omit=dev

# Step 4c: copy the app source into /app.
COPY app/ ./

# =============================================================================
# Runtime stage — slim final image. Nothing from builder's caches leaks in.
# =============================================================================

# Step 4d: use the same base image for the runtime.
FROM node:24.22.2-bookworm-slim

WORKDIR /app

# Step 4e: copy the installed app from the builder stage.
COPY --from=builder /app /app

ENV NODE_ENV=production
EXPOSE 3000

# Step 4f: probe http://localhost:3000/health.
#   The slim image does not ship with curl or wget.
#   Use Node's built-in http module instead:
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"

# Step 4g: start the application.
CMD ["node", "src/index.js"]
