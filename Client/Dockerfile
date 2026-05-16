# =============================================================================
# FRONTEND DOCKERFILE - Next.js Application
# Multi-stage build with Next.js standalone output
# =============================================================================

# Stage 1: Dependencies
FROM node:21-alpine AS deps

LABEL stage=deps
LABEL description="Frontend dependency installation"

RUN apk add --no-cache libc6-compat

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci


# Stage 2: Build
FROM node:21-alpine AS builder

LABEL stage=builder
LABEL description="Frontend TypeScript/Next.js build"

# Build-time args (NEXT_PUBLIC_* must be available at build time for Next.js inlining)
ARG BACKEND_URL
ARG AUTH_KEY
ARG JWT_KEY
ARG NEXT_PUBLIC_FRONTEND_GOOGLE_CLIENT_ID
ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
ARG NEXT_PUBLIC_DOMAIN

ENV BACKEND_URL=${BACKEND_URL:-http://localhost:3500}
ENV AUTH_KEY=${AUTH_KEY:-}
ENV JWT_KEY=${JWT_KEY:-}
ENV NEXT_PUBLIC_FRONTEND_GOOGLE_CLIENT_ID=${NEXT_PUBLIC_FRONTEND_GOOGLE_CLIENT_ID:-}
ENV NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=${NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY:-}
ENV NEXT_PUBLIC_DOMAIN=${NEXT_PUBLIC_DOMAIN:-http://localhost:3000}

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build


# Stage 3: Production Runner (Next.js standalone)
FROM node:21-alpine AS runner

LABEL maintainer="devops@ecommerce.com"
LABEL description="Production Next.js frontend (standalone)"

RUN apk add --no-cache libc6-compat curl

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Runtime BACKEND_URL (non-secret, baked for convenience; secrets like AUTH_KEY/JWT_KEY come from .env at runtime)
ARG BACKEND_URL
ENV BACKEND_URL=${BACKEND_URL:-http://localhost:3500}

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

RUN mkdir .next && chown nextjs:nodejs .next

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl --fail http://127.0.0.1:3000/ || exit 1

EXPOSE 3000

ENV HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
