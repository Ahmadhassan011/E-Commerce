#!/bin/bash
# =============================================================================
# scripts/build.sh — Build all Docker images for E-Commerce
# =============================================================================

set -euo pipefail

echo "=== Building E-Commerce Docker Images ==="

echo ""
echo "--- Building Backend ---"
docker build \
  -t ecommerce-backend:latest \
  -f Server/Dockerfile \
  ./Server

echo ""
echo "--- Building Frontend ---"
docker build \
  -t ecommerce-frontend:latest \
  --build-arg BACKEND_URL="${BACKEND_URL:-http://localhost:3500}" \
  --build-arg AUTH_KEY="${AUTH_KEY:-}" \
  --build-arg JWT_KEY="${JWT_KEY:-}" \
  --build-arg NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY="${NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY:-pk_test_placeholder}" \
  --build-arg NEXT_PUBLIC_FRONTEND_GOOGLE_CLIENT_ID="${NEXT_PUBLIC_FRONTEND_GOOGLE_CLIENT_ID:-}" \
  --build-arg NEXT_PUBLIC_DOMAIN="${NEXT_PUBLIC_DOMAIN:-http://localhost:3000}" \
  -f Client/Dockerfile \
  ./Client

echo ""
echo "=== Build Complete ==="
echo "Images:"
echo "  ecommerce-backend:latest"
echo "  ecommerce-frontend:latest"
echo ""
echo "Run: docker compose up -d"
