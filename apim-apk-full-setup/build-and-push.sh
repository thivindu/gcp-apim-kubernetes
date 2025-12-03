#!/bin/bash
set -e

echo "=== Building GCP Deployer Image ==="

# Navigate to gcp-deployer directory
cd "$(dirname "$0")"

# Package individual helm charts
echo "Packaging individual helm charts..."
cd chart/charts

# Package apim-apk-agent
if [ -d "apim-apk-agent" ]; then
    echo "Packaging apim-apk-agent..."
    COPYFILE_DISABLE=1 tar -czf apim-apk-agent-1.1.0.tgz --exclude='._*' --exclude='.DS_Store' apim-apk-agent/
fi

# Package apk-helm
if [ -d "apk-helm" ]; then
    echo "Packaging apk-helm..."
    COPYFILE_DISABLE=1 tar -czf apk-helm-1.3.0-1.tgz --exclude='._*' --exclude='.DS_Store' apk-helm/
fi

# Package wso2am-acp
if [ -d "wso2am-acp" ]; then
    echo "Packaging wso2am-acp..."
    COPYFILE_DISABLE=1 tar -czf wso2am-acp-4.5.0-1.tgz --exclude='._*' --exclude='.DS_Store' wso2am-acp/
fi

cd ../..

# Package the main chart
echo "Packaging main chart..."
COPYFILE_DISABLE=1 tar -czf chart.tar.gz --exclude='._*' --exclude='.DS_Store' chart/

# Build Docker image for amd64 (disable attestations)
echo "Building Docker image for linux/amd64..."
docker buildx build --platform linux/amd64 \
    --provenance=false \
    --sbom=false \
    --build-arg MARKETPLACE_TOOLS_TAG=latest \
    --output type=docker \
    --tag us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer:4.5-temp \
    -f Dockerfile .

# Push the image as a single manifest
echo "Pushing Docker image..."
docker push us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer:4.5-temp

# Extract SHA256 from the pushed image
echo "Extracting image SHA256..."
export IMAGE_SHA=$(docker inspect --format='{{index .RepoDigests 0}}' us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer:4.5-temp | cut -d'@' -f2)

echo "=== Build and push complete ==="
echo "Image: us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer@$IMAGE_SHA"

# Mutate image with marketplace annotation
echo "Adding marketplace annotation..."
export PATH="$(go env GOPATH)/bin:$PATH"
MUTATED_IMAGE=$(crane mutate \
  --annotation com.googleapis.cloudmarketplace.product.service.name=services/wso2-apim-apk.endpoints.wso2-marketplace-public.cloud.goog \
  us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer@$IMAGE_SHA)

echo "Mutated image: $MUTATED_IMAGE"

# Extract the new SHA from the mutated image
MUTATED_SHA=$(echo $MUTATED_IMAGE | cut -d'@' -f2)

# Copy the mutated manifest to final tags
echo "Tagging mutated image with 4.5 and 4.5.0..."
crane copy us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer@$MUTATED_SHA \
  us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer:4.5
crane copy us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer@$MUTATED_SHA \
  us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer:4.5.0

# Clean up temp tags
docker rmi us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer:4.5-temp 2>/dev/null || true
crane delete us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer:4.5-temp 2>/dev/null || true

echo "=== All operations complete ==="
echo "Final manifest SHA: $MUTATED_SHA"
echo "Tags: 4.5, 4.5.0"
