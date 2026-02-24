#!/bin/bash
# Standalone Trivy Scanner for Docker Images
# Usage: ./trivy-scan-image.sh <image-name> [report-dir] [severities]

set -euo pipefail

# Configuration
IMAGE_NAME="${1:-}"
REPORT_DIR="${2:-scan-reports}"
SEVERITIES="${3:-CRITICAL,HIGH,MEDIUM}"

# Extended timeout for large images (especially with conda/CUDA)
TIMEOUT="${4:-30m}"

TRIVY_OPTS="--scanners vuln,misconfig --ignore-unfixed --timeout ${TIMEOUT}"
TRIVY_FORMAT_JSON="json"
TRIVY_FORMAT_TABLE="table"

# Validation
if [ -z "$IMAGE_NAME" ]; then
    echo "❌ Error: Image name required"
    echo "Usage: $0 <image-name> [report-dir] [severities] [timeout]"
    echo ""
    echo "Examples:"
    echo "  $0 ml-module:latest"
    echo "  $0 ml-module:latest scan-reports CRITICAL,HIGH"
    echo "  $0 ml-module:latest scan-reports CRITICAL,HIGH,MEDIUM 45m"
    exit 1
fi

mkdir -p "$REPORT_DIR"

command -v trivy >/dev/null 2>&1 || { echo "❌ Trivy not found. Install: brew install trivy"; exit 1; }

# Check if image exists
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "❌ Image not found: $IMAGE_NAME"
    echo "Available images:"
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
IMAGE_SIZE=$(docker images --format "{{.Size}}" "$IMAGE_NAME")

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Trivy Security Scanner - Standalone                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration:"
echo "  Image: $IMAGE_NAME"
echo "  Size: $IMAGE_SIZE"
echo "  Report dir: $REPORT_DIR"
echo "  Severities: $SEVERITIES"
echo "  Timeout: $TIMEOUT"
echo "  Timestamp: $TIMESTAMP"
echo ""

# ========================================================================
# Step 1: Trivy Image Scan (JSON)
# ========================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[1/3] Scanning image (JSON report)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SCAN_START=$(date +%s)

trivy image \
    $TRIVY_OPTS \
    --severity "$SEVERITIES" \
    --format "$TRIVY_FORMAT_JSON" \
    --output "$REPORT_DIR/trivy-image-${TIMESTAMP}.json" \
    "$IMAGE_NAME"

SCAN_END=$(date +%s)
SCAN_DURATION=$((SCAN_END - SCAN_START))

if [ $? -eq 0 ]; then
    echo "✅ JSON scan complete (${SCAN_DURATION}s)"
    echo "   Report: $REPORT_DIR/trivy-image-${TIMESTAMP}.json"
    
    # Parse vulnerability counts if jq is available
    if command -v jq >/dev/null 2>&1; then
        CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$REPORT_DIR/trivy-image-${TIMESTAMP}.json" 2>/dev/null || echo "0")
        HIGH=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "$REPORT_DIR/trivy-image-${TIMESTAMP}.json" 2>/dev/null || echo "0")
        MEDIUM=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' "$REPORT_DIR/trivy-image-${TIMESTAMP}.json" 2>/dev/null || echo "0")
        echo "   Vulnerabilities: CRITICAL=$CRITICAL, HIGH=$HIGH, MEDIUM=$MEDIUM"
    fi
else
    echo "❌ JSON scan failed"
fi

echo ""

# ========================================================================
# Step 2: Trivy Image Scan (Table - Console)
# ========================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[2/3] Scanning image (table output)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

trivy image \
    $TRIVY_OPTS \
    --severity "$SEVERITIES" \
    --format "$TRIVY_FORMAT_TABLE" \
    "$IMAGE_NAME" | tee "$REPORT_DIR/trivy-table-${TIMESTAMP}.txt"

echo ""

# ========================================================================
# Step 3: Trivy Image Scan (SARIF for GitHub)
# ========================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[3/3] Generating SARIF report (GitHub compatible)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

trivy image \
    $TRIVY_OPTS \
    --severity "$SEVERITIES" \
    --format sarif \
    --output "$REPORT_DIR/trivy-sarif-${TIMESTAMP}.sarif" \
    "$IMAGE_NAME"

if [ $? -eq 0 ]; then
    echo "✅ SARIF report generated"
    echo "   Report: $REPORT_DIR/trivy-sarif-${TIMESTAMP}.sarif"
fi

echo ""

# ========================================================================
# Summary
# ========================================================================
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Scan Complete ✅                                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Summary:"
echo "  Image: $IMAGE_NAME"
echo "  Size: $IMAGE_SIZE"
echo "  Scan time: ${SCAN_DURATION}s"
echo "  Reports:"
echo "    - JSON: $REPORT_DIR/trivy-image-${TIMESTAMP}.json"
echo "    - Table: $REPORT_DIR/trivy-table-${TIMESTAMP}.txt"
echo "    - SARIF: $REPORT_DIR/trivy-sarif-${TIMESTAMP}.sarif"
echo ""
echo "Next steps:"
echo "  1. Review JSON report: cat $REPORT_DIR/trivy-image-${TIMESTAMP}.json | jq"
echo "  2. View table: cat $REPORT_DIR/trivy-table-${TIMESTAMP}.txt"
echo "  3. Upload SARIF to GitHub Security tab (if using GitHub)"
echo ""
