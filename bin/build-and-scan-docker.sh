#!/bin/bash
# Build and scan ML Module Container - Option 4 (CUDA + pip)
# Fast builds (~15-20 min), minimal images (~6-7GB)
# Usage: ./build-and-scan.sh [image-tag] [report-dir]

set -euo pipefail

# Configuration
IMAGE_TAG="${1:-dxbarradas/ml-module:latest}"
DOCKERFILE="${2:-Dockerfile}"
CONTEXT="${3:-.}"
REPORT_DIR="${4:-scan-reports}"
SEVERITIES="${5:-CRITICAL,HIGH,MEDIUM}"
TIMEOUT="${6:-30m}"

TRIVY_OPTS="--scanners vuln,misconfig --ignore-unfixed --timeout ${TIMEOUT}"
TRIVY_FORMAT_JSON="json"
TRIVY_FORMAT_TABLE="table"

# Validation
mkdir -p "$REPORT_DIR"

command -v docker >/dev/null 2>&1 || { echo "❌ Docker not found"; exit 1; }
command -v trivy >/dev/null 2>&1 || { echo "❌ Trivy not found"; exit 1; }

if [ ! -f "$DOCKERFILE" ]; then
    echo "❌ Dockerfile not found: $DOCKERFILE"
    exit 1
fi

if [ ! -f "environment.yml" ]; then
    echo "❌ environment.yml not found"
    exit 1
fi

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ML Module Container Build & Scan                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration:"
echo "  Image tag: $IMAGE_TAG"
echo "  Dockerfile: $DOCKERFILE"
echo "  Context: $CONTEXT"
echo "  Report dir: $REPORT_DIR"
echo "  Timeout: $TIMEOUT"
echo ""

# ========================================================================
# Step 1: Build Docker Image
# ========================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[1/4] Building Docker image: $IMAGE_TAG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

BUILD_START=$(date +%s)

docker build \
    --pull \
    --no-cache \
    --platform=linux/amd64 \
    --progress=plain \
    -f "$DOCKERFILE" \
    -t "$IMAGE_TAG" \
    "$CONTEXT"

BUILD_END=$(date +%s)
BUILD_DURATION=$((BUILD_END - BUILD_START))

if [ $? -eq 0 ]; then
    IMAGE_SIZE=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "$IMAGE_TAG" | awk '{print $2}')
    echo ""
    echo "✅ Build successful!"
    echo "   Size: $IMAGE_SIZE"
    echo "   Time: ${BUILD_DURATION}s"
else
    echo "❌ Build failed!"
    exit 1
fi

echo ""

# ========================================================================
# Step 1.5: Extract Environment Lockfile
# ========================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[1.5/5] Extracting environment lockfile from container"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker run --rm --platform=linux/amd64 "$IMAGE_TAG" cat /opt/environment_lockfile.yml > environment_exported.yml

if [ $? -eq 0 ] && [ -f "environment_exported.yml" ]; then
    EXPORT_SIZE=$(wc -l < environment_exported.yml)
    echo "✅ Environment lockfile extracted"
    echo "   File: environment_exported.yml"
    echo "   Lines: $EXPORT_SIZE"
    echo "   Ready to commit to repo for version tracking"
else
    echo "⚠️  Warning: Could not extract environment lockfile"
fi

echo ""

# ========================================================================
# Step 2: Trivy Image Scan (JSON)
# ========================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[2/5] Scanning image with Trivy (JSON report)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

trivy image \
    $TRIVY_OPTS \
    --severity "$SEVERITIES" \
    --format "$TRIVY_FORMAT_JSON" \
    --output "$REPORT_DIR/trivy-image.json" \
    "$IMAGE_TAG"

if [ $? -eq 0 ]; then
    echo "✅ Image scan complete"
    VULN_COUNT=$(jq '.Results[0].Misconfigurations | length // 0' "$REPORT_DIR/trivy-image.json" 2>/dev/null || echo "0")
    echo "   Report: $REPORT_DIR/trivy-image.json"
fi

echo ""

# ========================================================================
# Step 3: Trivy Image Scan (Table Output)
# ========================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[3/5] Trivy Vulnerability Summary (table)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

trivy image \
    $TRIVY_OPTS \
    --severity "$SEVERITIES" \
    --format "$TRIVY_FORMAT_TABLE" \
    "$IMAGE_TAG"

echo ""

# ========================================================================
# Step 4: Trivy Filesystem Scan (build context)
# ========================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[4/5] Scanning build context with Trivy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

trivy fs \
    $TRIVY_OPTS \
    --severity "$SEVERITIES" \
    --format "$TRIVY_FORMAT_JSON" \
    --output "$REPORT_DIR/trivy-fs.json" \
    "$CONTEXT"

if [ $? -eq 0 ]; then
    echo "✅ Filesystem scan complete"
    echo "   Report: $REPORT_DIR/trivy-fs.json"
fi

echo ""

# ========================================================================
# Summary
# ========================================================================
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Build & Scan Complete ✅                                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Summary:"
echo "  Image: $IMAGE_TAG"
echo "  Size: $IMAGE_SIZE"
echo "  Build time: ${BUILD_DURATION}s"
echo "  Reports: $REPORT_DIR/"
echo ""
echo "Next steps:"
echo "  1. Review Trivy reports: ls -lh $REPORT_DIR/"
echo "  2. Commit environment lockfile: git add environment_exported.yml && git commit -m 'Update environment lockfile'"
echo "  3. Test image: docker run --rm --gpus all $IMAGE_TAG python --version"
echo "  4. Convert to Singularity: docker run -v /var/run/docker.sock:/var/run/docker.sock \\"
echo "       singularityware/singularity build ml_module.sif docker-daemon://$IMAGE_TAG"
echo ""
