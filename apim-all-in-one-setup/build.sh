#!/bin/bash

# Build script for WSO2 APIM GCP Marketplace Deployer
# This script automates the process of building and pushing the deployer image

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required environment variables are set
if [ -z "$PROJECT" ]; then
    print_error "PROJECT environment variable is not set"
    echo "Usage: export PROJECT=your-gcp-project-id"
    exit 1
fi

# Set default values
APP_ID=${APP_ID:-"wso2-apim"}
RELEASE=${RELEASE:-"4.5.0"}
TRACK=${TRACK:-"4.5"}  # Semantic minor version for Marketplace
REGISTRY=${REGISTRY:-"gcr.io/$PROJECT"}
MARKETPLACE_TOOLS_TAG=${MARKETPLACE_TOOLS_TAG:-"latest"}

print_info "Building WSO2 APIM Deployer Image"
print_info "Project: $PROJECT"
print_info "Registry: $REGISTRY"
print_info "App ID: $APP_ID"
print_info "Release: $RELEASE"
print_info "Track: $TRACK"

# Check if chart directory exists
if [ ! -d "chart" ]; then
    print_warn "Chart directory not found. Copying from helm-charts..."
    if [ -d "../helm-charts/wso2-apim-kubernetes" ]; then
        cp -r ../helm-charts/wso2-apim-kubernetes chart
        print_info "Chart copied successfully"
    else
        print_error "Source chart not found at ../helm-charts/wso2-apim-kubernetes"
        exit 1
    fi
fi

# Check if chart dependencies are present
if [ ! -d "chart/charts" ] || [ -z "$(ls -A chart/charts)" ]; then
    print_warn "Chart dependencies not found. Running helm dependency update..."
    cd chart
    helm dependency update
    cd ..
    print_info "Dependencies updated"
fi

# Build the Docker image
print_info "Building Docker image..."
docker build \
    --build-arg MARKETPLACE_TOOLS_TAG="$MARKETPLACE_TOOLS_TAG" \
    --tag "$REGISTRY/$APP_ID/deployer:$RELEASE" \
    --tag "$REGISTRY/$APP_ID/deployer:$TRACK" \
    -f Dockerfile .



if [ $? -eq 0 ]; then
    print_info "Docker image built successfully"
else
    print_error "Docker build failed"
    exit 1
fi

# Configure Docker authentication
if [[ "$REGISTRY" == *"pkg.dev"* ]]; then
    # Artifact Registry
    print_info "Configuring Docker authentication for Artifact Registry..."
    LOCATION=$(echo "$REGISTRY" | cut -d'/' -f1 | cut -d'-' -f1)
    gcloud auth configure-docker ${LOCATION}-docker.pkg.dev --quiet
else
    # Container Registry (GCR)
    print_info "Configuring Docker authentication for GCR..."
    gcloud auth configure-docker --quiet
fi

# Push the images
print_info "Pushing image: $REGISTRY/$APP_ID/deployer:$RELEASE"
docker push "$REGISTRY/$APP_ID/deployer:$RELEASE"

print_info "Pushing image: $REGISTRY/$APP_ID/deployer:$TRACK"
docker push "$REGISTRY/$APP_ID/deployer:$TRACK"

if [ $? -eq 0 ]; then
    print_info "Images pushed successfully"
    echo ""
    print_info "Deployer image is ready at:"
    echo "  $REGISTRY/$APP_ID/deployer:$RELEASE (full version)"
    echo "  $REGISTRY/$APP_ID/deployer:$TRACK (track/minor version)"
else
    print_error "Failed to push images"
    exit 1
fi

# Print next steps
echo ""
print_info "Next steps:"
echo "1. Test the deployment with mpdev:"
echo "   mpdev install --deployer=$REGISTRY/$APP_ID/deployer:$RELEASE \\"
echo "     --parameters='{\"name\": \"wso2-apim-test\", \"namespace\": \"default\", \"gcp.enabled\": true}'"
echo ""
echo "2. Or deploy directly with kubectl:"
echo "   kubectl apply -f <your-application-manifest.yaml>"
