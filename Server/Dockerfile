# =============================================================================
# BACKEND DOCKERFILE - Express.js / TypeScript API
# Production-grade multi-stage build with Alpine, non-root user, and healthcheck
# =============================================================================

# Stage 1: Build
FROM node:21-alpine AS build

LABEL stage=build
LABEL description="Build stage for Express backend"

RUN apk add --no-cache libc6-compat

WORKDIR /app

# Copy dependency manifests first (layer caching optimization)
COPY package.json package-lock.json ./

# Install ALL dependencies (dev + prod for TypeScript compilation)
RUN npm ci

# Copy source code
COPY . .

# Compile TypeScript to JavaScript
RUN npx tsc -p .

# Prune dev dependencies to reduce final image size
RUN npm prune --omit=dev


# Stage 2: Production Runner
FROM node:21-alpine AS runner

LABEL maintainer="devops@ecommerce.com"
LABEL description="Production Express.js backend container"

# Security: create non-root user
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 appuser --ingroup appgroup

# Install only runtime OS dependencies
RUN apk add --no-cache tini

WORKDIR /app

# Copy only production artifacts from build stage
COPY --from=build --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=build --chown=appuser:appgroup /app/package.json ./
COPY --from=build --chown=appuser:appgroup /app/index.js ./
COPY --from=build --chown=appuser:appgroup /app/routes.js ./
COPY --from=build --chown=appuser:appgroup /app/routes ./routes
COPY --from=build --chown=appuser:appgroup /app/controller ./controller
COPY --from=build --chown=appuser:appgroup /app/data ./data
COPY --from=build --chown=appuser:appgroup /app/middleware ./middleware
COPY --from=build --chown=appuser:appgroup /app/utils ./utils
COPY --from=build --chown=appuser:appgroup /app/validators ./validators

# Security: run as non-root
USER appuser

# Environment variables (set at runtime, not build time for secrets)
ENV NODE_ENV=production \
    PORT=3500 \
    NODE_OPTIONS="--max-http-header-size=16384"

# Healthcheck to verify the API is responding
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:3500/health

# Expose API port
EXPOSE 3500

# Use tini as init for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]

# Start the server
CMD ["node", "index.js"]
