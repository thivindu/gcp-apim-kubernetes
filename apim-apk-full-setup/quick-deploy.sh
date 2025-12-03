#!/bin/bash

# Quick deploy script for WSO2 APIM on GCP
# This script provides a streamlined deployment process

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}WSO2 APIM GCP Marketplace - Quick Deploy${NC}"
echo "=========================================="
echo ""

# Prompt for required information
read -p "Enter your GCP Project ID: " PROJECT
read -p "Enter Application Name (default: wso2-apim-1): " APP_NAME
APP_NAME=${APP_NAME:-wso2-apim-1}
read -p "Enter Namespace (default: default): " NAMESPACE
NAMESPACE=${NAMESPACE:-default}

export PROJECT
export APP_ID="wso2-apim"
export RELEASE="4.5.0"
export REGISTRY="gcr.io/$PROJECT"

echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Project: $PROJECT"
echo "  App Name: $APP_NAME"
echo "  Namespace: $NAMESPACE"
echo "  Registry: $REGISTRY"
echo ""

read -p "Proceed with build and deploy? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Aborted."
    exit 0
fi

# Build the deployer
echo ""
echo -e "${GREEN}Step 1: Building deployer image...${NC}"
./build.sh

# Install mpdev if needed
echo ""
echo -e "${GREEN}Step 2: Checking for mpdev...${NC}"
if ! command -v mpdev &> /dev/null; then
    echo "Setting up mpdev alias..."
    alias mpdev='docker run --rm \
      -v ~/.config/gcloud:/root/.config/gcloud \
      -v ~/.kube:/root/.kube \
      -v $(pwd):/data \
      gcr.io/cloud-marketplace-tools/k8s/dev:latest'
fi

# Deploy the application
echo ""
echo -e "${GREEN}Step 3: Deploying application...${NC}"
mpdev install \
  --deployer="$REGISTRY/$APP_ID/deployer:$RELEASE" \
  --parameters="{
    \"name\": \"$APP_NAME\",
    \"namespace\": \"$NAMESPACE\",
    \"gcp.enabled\": true,
    \"acp.enabled\": true,
    \"apk.enabled\": true,
    \"apkagent.enabled\": true
  }"

echo ""
echo -e "${GREEN}Deployment initiated!${NC}"
echo ""
echo "Monitor the deployment with:"
echo "  kubectl get applications -n $NAMESPACE"
echo "  kubectl get pods -n $NAMESPACE"
echo ""
echo "View logs with:"
echo "  kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=wso2-apim --tail=100 -f"
