#!/bin/bash
# Quick Start Deployment Script for WSO2 APIM on GKE
# This script provides the essential commands to deploy WSO2 APIM

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}WSO2 APIM GKE Deployment - Quick Start${NC}"
echo -e "${GREEN}========================================${NC}"

# Configuration
PROJECT_ID="wso2-marketplace-public"
CLUSTER_NAME="wso2-apim-gke-test"
REGION="us-east1"

echo ""
echo -e "${YELLOW}Step 1: Authenticate with GCP${NC}"
echo "Run these commands:"
echo "  gcloud auth login"
echo "  gcloud auth application-default login"
echo "  gcloud config set project $PROJECT_ID"
echo ""
read -p "Press Enter when authentication is complete..."

echo ""
echo -e "${YELLOW}Step 2: Enable Required APIs${NC}"
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  compute.googleapis.com \
  container.googleapis.com \
  config.googleapis.com
echo -e "${GREEN}✓ APIs enabled${NC}"

echo ""
echo -e "${YELLOW}Step 3: Initialize Terraform${NC}"
cd "$(dirname "$0")"
terraform init
echo -e "${GREEN}✓ Terraform initialized${NC}"

echo ""
echo -e "${YELLOW}Step 4: Validate Configuration${NC}"
terraform validate
echo -e "${GREEN}✓ Configuration valid${NC}"

echo ""
echo -e "${YELLOW}Step 5: Review Deployment Plan${NC}"
echo "This will show you what resources will be created..."
terraform plan
echo ""
read -p "Does the plan look correct? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 6: Deploy Infrastructure${NC}"
echo -e "${RED}This will take approximately 20-30 minutes...${NC}"
terraform apply
echo -e "${GREEN}✓ Deployment complete!${NC}"

echo ""
echo -e "${YELLOW}Step 7: Get Cluster Credentials${NC}"
gcloud container clusters get-credentials $CLUSTER_NAME \
  --region $REGION \
  --project $PROJECT_ID
echo -e "${GREEN}✓ Cluster credentials configured${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"

echo ""
echo -e "${YELLOW}Verification Commands:${NC}"
echo ""
echo "Check cluster info:"
echo "  kubectl cluster-info"
echo ""
echo "Check nodes:"
echo "  kubectl get nodes"
echo ""
echo "Check ingress controller:"
echo "  kubectl get pods -n ingress-nginx"
echo "  kubectl get svc -n ingress-nginx"
echo ""
echo "Check WSO2 APIM pods:"
echo "  kubectl get pods -A | grep wso2"
echo ""
echo "Check Helm releases:"
echo "  helm list -A"
echo ""
echo "Get ingress external IP:"
echo "  kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
echo ""
echo -e "${GREEN}For detailed troubleshooting, see DEPLOYMENT-GUIDE.md${NC}"
