#!/bin/bash
#
# Quick deployment script for WSO2 APIM via CLI
# This script automates the command-line deployment process

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Default values
APP_INSTANCE_NAME=${APP_INSTANCE_NAME:-"wso2-apim-1"}
NAMESPACE=${NAMESPACE:-"default"}
IMAGE_REGISTRY=${IMAGE_REGISTRY:-"us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace"}
TAG=${TAG:-"4.5"}

print_info "WSO2 APIM CLI Deployment Script"
echo "=================================="
echo ""

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

if ! command -v gcloud &> /dev/null; then
    print_error "gcloud is not installed. Please install Google Cloud SDK."
    exit 1
fi

print_info "✓ Prerequisites check passed"
echo ""

# Get user input
echo "Configuration:"
read -p "Application name [${APP_INSTANCE_NAME}]: " input
APP_INSTANCE_NAME=${input:-$APP_INSTANCE_NAME}

read -p "Namespace [${NAMESPACE}]: " input
NAMESPACE=${input:-$NAMESPACE}

read -p "Enable GCP integration? (y/n) [y]: " gcp_enabled
gcp_enabled=${gcp_enabled:-y}

read -p "Enable ACP (Control Plane)? (y/n) [y]: " acp_enabled
acp_enabled=${acp_enabled:-y}

read -p "Enable APK? (y/n) [y]: " apk_enabled
apk_enabled=${apk_enabled:-y}

read -p "Enable APK Agent? (y/n) [y]: " apkagent_enabled
apkagent_enabled=${apkagent_enabled:-y}

echo ""
print_info "Configuration Summary:"
echo "  Application: ${APP_INSTANCE_NAME}"
echo "  Namespace: ${NAMESPACE}"
echo "  Registry: ${IMAGE_REGISTRY}"
echo "  Tag: ${TAG}"
echo "  GCP Integration: ${gcp_enabled}"
echo "  ACP Enabled: ${acp_enabled}"
echo "  APK Enabled: ${apk_enabled}"
echo "  APK Agent Enabled: ${apkagent_enabled}"
echo ""

read -p "Proceed with deployment? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Create namespace if it doesn't exist
print_info "Creating namespace ${NAMESPACE} (if not exists)..."
kubectl create namespace "${NAMESPACE}" 2>/dev/null || true

# Install Application CRD if not present
print_info "Checking for Application CRD..."
if ! kubectl get crd applications.app.k8s.io &> /dev/null; then
    print_info "Installing Application CRD..."
    kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
else
    print_info "✓ Application CRD already installed"
fi

# Check if mpdev is available
if command -v mpdev &> /dev/null || docker images | grep -q "cloud-marketplace-tools/k8s/dev"; then
    DEPLOYMENT_METHOD="mpdev"
else
    DEPLOYMENT_METHOD="helm"
fi

print_info "Using deployment method: ${DEPLOYMENT_METHOD}"
echo ""

if [ "$DEPLOYMENT_METHOD" == "mpdev" ]; then
    # Deploy using mpdev
    print_info "Deploying with mpdev..."
    
    # Setup mpdev alias if not already available
    if ! command -v mpdev &> /dev/null; then
        docker pull gcr.io/cloud-marketplace-tools/k8s/dev:latest
        alias mpdev='docker run --rm --net=host -v ~/.config/gcloud:/root/.config/gcloud -v ~/.kube:/root/.kube -v $(pwd):/data gcr.io/cloud-marketplace-tools/k8s/dev:latest'
    fi
    
    mpdev install \
      --deployer="${IMAGE_REGISTRY}/deployer:${TAG}" \
      --parameters="{
        \"name\": \"${APP_INSTANCE_NAME}\",
        \"namespace\": \"${NAMESPACE}\",
        \"gcp.enabled\": $([ "$gcp_enabled" == "y" ] && echo "true" || echo "false"),
        \"acp.enabled\": $([ "$acp_enabled" == "y" ] && echo "true" || echo "false"),
        \"apk.enabled\": $([ "$apk_enabled" == "y" ] && echo "true" || echo "false"),
        \"apkagent.enabled\": $([ "$apkagent_enabled" == "y" ] && echo "true" || echo "false")
      }"
else
    # Deploy using helm
    print_info "Deploying with Helm..."
    
    if [ ! -d "chart" ]; then
        print_error "Helm chart not found in current directory. Please run from gcp-deployer directory."
        exit 1
    fi
    
    helm install "${APP_INSTANCE_NAME}" \
      --namespace "${NAMESPACE}" \
      --create-namespace \
      --set gcp.enabled=$([ "$gcp_enabled" == "y" ] && echo "true" || echo "false") \
      --set acp.enabled=$([ "$acp_enabled" == "y" ] && echo "true" || echo "false") \
      --set apk.enabled=$([ "$apk_enabled" == "y" ] && echo "true" || echo "false") \
      --set apkagent.enabled=$([ "$apkagent_enabled" == "y" ] && echo "true" || echo "false") \
      ./chart
fi

print_info "✓ Deployment initiated"
echo ""

# Wait and verify
print_info "Waiting for deployment to complete (this may take several minutes)..."
sleep 30

print_info "Checking deployment status..."
echo ""

# Check Application resource
if kubectl get application "${APP_INSTANCE_NAME}" -n "${NAMESPACE}" &> /dev/null; then
    print_info "✓ Application resource created"
    kubectl get application "${APP_INSTANCE_NAME}" -n "${NAMESPACE}"
else
    print_warn "Application resource not found yet"
fi

echo ""

# Check pods
print_info "Checking pods..."
kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name="${APP_INSTANCE_NAME}" || \
  kubectl get pods -n "${NAMESPACE}"

echo ""

# Check services
print_info "Checking services..."
kubectl get services -n "${NAMESPACE}" -l app.kubernetes.io/name="${APP_INSTANCE_NAME}" || \
  kubectl get services -n "${NAMESPACE}"

echo ""
print_info "Deployment Summary"
echo "=================="
echo "Application: ${APP_INSTANCE_NAME}"
echo "Namespace: ${NAMESPACE}"
echo ""
echo "To check status:"
echo "  kubectl get application ${APP_INSTANCE_NAME} -n ${NAMESPACE}"
echo "  kubectl get pods -n ${NAMESPACE}"
echo ""
echo "To view logs:"
echo "  kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/name=${APP_INSTANCE_NAME} --tail=100"
echo ""
echo "To access the application:"
echo "  kubectl port-forward -n ${NAMESPACE} service/wso2-apim 9443:9443"
echo "  Then visit: https://localhost:9443"
echo ""
echo "To uninstall:"
if [ "$DEPLOYMENT_METHOD" == "mpdev" ]; then
    echo "  mpdev delete --name=${APP_INSTANCE_NAME} --namespace=${NAMESPACE}"
else
    echo "  helm uninstall ${APP_INSTANCE_NAME} -n ${NAMESPACE}"
fi
echo ""
