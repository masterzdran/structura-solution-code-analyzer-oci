#!/bin/bash
set -euo pipefail

# Base version
BASE_VERSION="0.1.0"

# Timestamp in UTC
TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")

# Full version tag
VERSION="${BASE_VERSION}-${TIMESTAMP}"
IMAGE_NAME="structura-solution-code-analyzer-oci"
DOCKERHUB_USER="masterzdran"  # Replace with your Docker Hub username

# Full image tag
TAG="${DOCKERHUB_USER}/${IMAGE_NAME}:${VERSION}"

echo "🔧 Building Docker image: $TAG"
docker build -t "$TAG" .

echo "✅ Build complete: $TAG"
