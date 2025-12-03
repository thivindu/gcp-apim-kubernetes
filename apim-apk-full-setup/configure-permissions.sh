#!/bin/bash

# Configure permissions for GCP Marketplace deployer image
# This script ensures the deployer image is accessible for verification

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check required variables
if [ -z "$PROJECT" ]; then
    print_error "PROJECT environment variable is not set"
    echo "Usage: export PROJECT=your-gcp-project-id"
    exit 1
fi

APP_ID=${APP_ID:-"wso2-apim"}
RELEASE=${RELEASE:-"4.5.0"}
TRACK=${TRACK:-"4.5"}

# Detect registry type
if [[ "$REGISTRY" == *"pkg.dev"* ]]; then
    REGISTRY_TYPE="artifact-registry"
    # Extract repository info from registry path
    # Expected format: us-docker.pkg.dev/PROJECT/REPOSITORY
    LOCATION=$(echo "$REGISTRY" | cut -d'/' -f1 | cut -d'-' -f1)
    REPOSITORY=$(echo "$REGISTRY" | cut -d'/' -f3)
    print_info "Using Artifact Registry"
    print_info "Location: $LOCATION"
    print_info "Repository: $REPOSITORY"
else
    REGISTRY_TYPE="gcr"
    print_info "Using Container Registry (GCR)"
fi

print_info "Configuring permissions for deployer image..."
print_info "Project: $PROJECT"
print_info "Registry: $REGISTRY"
print_info "Image: $APP_ID/deployer:$TRACK"

# Make the image publicly readable (required for Marketplace verification)
print_info "Making deployer image publicly readable..."

if [ "$REGISTRY_TYPE" == "artifact-registry" ]; then
    # For Artifact Registry
    print_info "Granting public read access to Artifact Registry repository..."
    
    gcloud artifacts repositories add-iam-policy-binding "$REPOSITORY" \
        --location="$LOCATION" \
        --member="allUsers" \
        --role="roles/artifactregistry.reader" \
        --project="$PROJECT" 2>&1 | grep -v "WARNING" || true
    
    print_info "✓ Artifact Registry permissions configured"
else
    # For GCR
    print_info "Granting public read access to GCR bucket..."
    
    gsutil iam ch allUsers:objectViewer "gs://artifacts.${PROJECT}.appspot.com" 2>&1 | grep -v "WARNING" || true
    
    print_info "✓ GCR permissions configured"
fi

# Grant Cloud Marketplace Service Account access (if available)
MARKETPLACE_SA="cloud-commerce-partner@system.gserviceaccount.com"

print_info "Granting access to Cloud Marketplace service account..."

if [ "$REGISTRY_TYPE" == "artifact-registry" ]; then
    gcloud artifacts repositories add-iam-policy-binding "$REPOSITORY" \
        --location="$LOCATION" \
        --member="serviceAccount:$MARKETPLACE_SA" \
        --role="roles/artifactregistry.reader" \
        --project="$PROJECT" 2>&1 | grep -v "WARNING" || true
else
    gsutil iam ch "serviceAccount:$MARKETPLACE_SA:objectViewer" "gs://artifacts.${PROJECT}.appspot.com" 2>&1 | grep -v "WARNING" || true
fi

print_info "✓ Marketplace service account access granted"

# Verify the image exists
print_info "Verifying deployer image exists..."

IMAGE_PATH="$REGISTRY/$APP_ID/deployer:$TRACK"

if gcloud container images describe "$IMAGE_PATH" --project="$PROJECT" &>/dev/null; then
    print_info "✓ Image found: $IMAGE_PATH"
    
    # Get image digest
    DIGEST=$(gcloud container images describe "$IMAGE_PATH" --project="$PROJECT" --format="value(image_summary.digest)")
    print_info "Image digest: $DIGEST"
    print_info "Full image reference: $REGISTRY/$APP_ID/deployer@$DIGEST"
else
    print_error "Image not found: $IMAGE_PATH"
    print_error "Please build and push the image first using ./build.sh"
    exit 1
fi

echo ""
print_info "=== Configuration Complete ==="
echo ""
echo "Your deployer image is now configured for GCP Marketplace verification."
echo ""
echo "Image details:"
echo "  Path: $IMAGE_PATH"
echo "  Digest: $DIGEST"
echo ""
echo "Next steps:"
echo "1. Use this image path in your Marketplace submission"
echo "2. Run the verification test"
echo "3. If verification fails, check the logs for specific issues"
echo ""
print_warn "Note: Making the image publicly readable is required for Marketplace verification."
print_warn "Ensure this aligns with your security requirements."
