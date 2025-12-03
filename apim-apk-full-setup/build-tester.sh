#!/bin/bash
#
# Script to build and push the test runner image for GCP Marketplace verification

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check required variables
if [ -z "$PROJECT" ]; then
    print_error "PROJECT environment variable is not set"
    echo "Usage: export PROJECT=your-gcp-project-id"
    exit 1
fi

APP_ID=${APP_ID:-"wso2-apim"}
TRACK=${TRACK:-"4.5"}
REGISTRY=${REGISTRY:-"us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace"}

TESTER_IMAGE="${REGISTRY}/${APP_ID}/tester:${TRACK}"

print_info "Building test runner image..."
print_info "Project: $PROJECT"
print_info "Image: $TESTER_IMAGE"

# Navigate to apptest/deployer directory
cd apptest/deployer

# Build the test runner image
docker build \
    --tag "${TESTER_IMAGE}" \
    -f Dockerfile .

if [ $? -eq 0 ]; then
    print_info "Test runner image built successfully"
else
    print_error "Test runner image build failed"
    exit 1
fi

# Configure Docker authentication
if [[ "$REGISTRY" == *"pkg.dev"* ]]; then
    LOCATION=$(echo "$REGISTRY" | cut -d'/' -f1 | cut -d'-' -f1)
    print_info "Configuring Docker authentication for Artifact Registry..."
    gcloud auth configure-docker ${LOCATION}-docker.pkg.dev --quiet
else
    print_info "Configuring Docker authentication for GCR..."
    gcloud auth configure-docker --quiet
fi

# Push the image
print_info "Pushing test runner image: ${TESTER_IMAGE}"
docker push "${TESTER_IMAGE}"

if [ $? -eq 0 ]; then
    print_info "✓ Test runner image pushed successfully"
    echo ""
    print_info "Test runner image is ready at:"
    echo "  ${TESTER_IMAGE}"
else
    print_error "Failed to push test runner image"
    exit 1
fi

echo ""
print_info "Don't forget to rebuild the deployer image to include the updated apptest schema!"
echo "Run: cd ../.. && ./build.sh"
