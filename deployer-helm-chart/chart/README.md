# WSO2 APIM Stack Helm Chart

A unified Helm chart for deploying the complete WSO2 API Manager stack on Kubernetes, including:
- WSO2 API Manager ACP (APIM-ACP) v4.5.0
- WSO2 APK (API Platform for Kubernetes) v1.3.0
- WSO2 APIM-APK Agent v1.3.0

All components are deployed to the **default namespace**.

## Prerequisites

- Kubernetes cluster (1.24+)
- Helm 3.x installed
- kubectl configured to access your cluster
- **NGINX Ingress Controller** installed manually in your cluster
- Sufficient cluster resources (CPU, Memory, Storage)

## Quick Start

### 1. Install NGINX Ingress Controller

**Important:** NGINX Ingress Controller must be installed manually before deploying this Helm chart.

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.0/deploy/static/provider/cloud/deploy.yaml

# Verify NGINX Ingress installation
kubectl get pods --namespace=ingress-nginx

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### 2. Add Required Helm Repositories

The chart uses dependencies from multiple sources:

```bash
# Add WSO2 repository
helm repo add wso2 https://helm.wso2.com

# Add WSO2 APK repository  
helm repo add wso2apk https://github.com/wso2/apk/releases/download/1.3.0-1

# Add WSO2 APK Agent repository
helm repo add wso2apkagent https://github.com/wso2/product-apim-tooling/releases/download/1.3.0

# Update repositories
helm repo update
```

### 3. Update Helm Dependencies

Download the required chart dependencies:

```bash
cd helm-charts/wso2-apim-kubernetes
helm dependency update
```

This will download:
- `wso2am-acp-4.5.0-5.tgz` (APIM-ACP)
- `apk-helm-1.3.0-1.tgz` (APK)
- `apim-apk-agent-1.3.0.tgz` (APK Agent)

### 4. Install the Stack

Install the complete stack in the default namespace:

```bash
# Install the chart (deploys to default namespace)
helm install apim .
```

Or with custom values:

```bash
helm install apim . -f custom-values.yaml
```

### 5. Verify Installation

Check the status of all components:

```bash
# Check helm release
helm list

# Check pods in default namespace
kubectl get pods -w

# Check nginx ingress controller
kubectl get pods -n ingress-nginx

# Check services
kubectl get svc
```

## Installation Order

The chart installs components in the following order:

1. **Prerequisites**: NGINX Ingress Controller (must be installed manually before chart installation)
2. **Sub-charts** (installed in the default namespace):
   - WSO2 APIM-ACP v4.5.0
   - WSO2 APK v1.3.0
   - WSO2 APIM-APK Agent v1.3.0

## Configuration

### Basic Configuration

The main configuration options are in `values.yaml`:

```yaml
# Enable/disable components
acp:
  enabled: true

apk:
  enabled: true

apkagent:
  enabled: true
```

**Note:** All components are deployed to the default namespace. NGINX Ingress Controller must be installed separately.

### Using External Values Files

Each sub-chart can load values from the official WSO2 values files. To use them, create a custom `values.yaml`:

```yaml
acp:
  # Values for wso2am-acp chart from https://helm.wso2.com
  # You can override any values from the official chart here
  
apk:
  # Values for apk-helm chart
  # Add overrides for: https://raw.githubusercontent.com/wso2/apk/main/helm-charts/samples/apk/1.3.0-values.yaml

apkagent:
  # Values for apim-apk-agent chart
  # Add overrides for: https://raw.githubusercontent.com/wso2/apk/main/helm-charts/samples/apim-apk-agent/cp/1.3.0-values.yaml
```

### Advanced Configuration

#### Disable Specific Components

To install only certain components:

```yaml
acp:
  enabled: true
apk:
  enabled: false
apkagent:
  enabled: false
```

## Upgrading

To upgrade the stack:

```bash
# Update dependencies first
helm dependency update

# Upgrade the release
helm upgrade apim .
```

## Uninstalling

To completely remove the stack:

```bash
# Uninstall the helm release
helm uninstall apim

# Optionally, remove nginx ingress controller (if you want to clean up completely)
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.0/deploy/static/provider/cloud/deploy.yaml
```

## Troubleshooting

### Check Nginx Ingress Controller

Verify the NGINX Ingress Controller is running properly:

```bash
# Check nginx pods
kubectl get pods -n ingress-nginx

# Check nginx logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Check nginx service
kubectl get svc -n ingress-nginx
```

### Check Sub-chart Status

```bash
# List all resources in default namespace
kubectl get all

# Check specific pod logs
kubectl logs <pod-name>

# Describe pods for events
kubectl describe pod <pod-name>
```

### Helm Debug

```bash
# Dry run to see what will be installed
helm install apim . --dry-run --debug

# Check rendered templates
helm template apim .
```

## Chart Structure

```
wso2-apim-kubernetes/
├── Chart.yaml              # Chart metadata and dependencies
├── values.yaml             # Default configuration values
├── charts/                 # Downloaded dependency charts (after helm dependency update)
│   ├── apim-apk-agent-1.3.0.tgz
│   ├── apk-helm-1.3.0-1.tgz
│   └── wso2am-acp-4.5.0-5.tgz
├── templates/
│   └── _helpers.tpl       # Template helpers
└── README.md
```

**Note:** This chart deploys all components to the **default namespace**. NGINX Ingress Controller must be installed manually before deploying this chart.

## Repository Information

This chart pulls dependencies from the following repositories:

- **WSO2 APIM**: https://helm.wso2.com
- **WSO2 APK**: https://github.com/wso2/apk/releases
- **WSO2 APIM-APK Agent**: https://github.com/wso2/product-apim-tooling/releases

## Original Installation Commands

This chart replaces the following manual installation commands:

```bash
# 1. Install NGINX Ingress Controller (REQUIRED - must be done first)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.0/deploy/static/provider/cloud/deploy.yaml

# 2. Add repositories
helm repo add wso2 https://helm.wso2.com
helm repo add wso2apk https://github.com/wso2/apk/releases/download/1.3.0-1
helm repo add wso2apkagent https://github.com/wso2/product-apim-tooling/releases/download/1.3.0
helm repo update

# 3. Install charts separately in default namespace
helm install acp wso2/wso2am-acp --version 4.5.0-5 -f apim-values.yaml

helm install apk wso2apk/apk-helm --version 1.3.0-1 \
  -f https://raw.githubusercontent.com/wso2/apk/main/helm-charts/samples/apk/1.3.0-values.yaml

helm install apkagent wso2apkagent/apim-apk-agent --version 1.3.0 \
  -f https://raw.githubusercontent.com/wso2/apk/main/helm-charts/samples/apim-apk-agent/cp/1.3.0-values.yaml
```

With this unified chart, all three components can be installed with a single command:

```bash
# After installing NGINX Ingress manually
helm install wso2-apim-kubernetes .
```

## License

This chart is provided as-is. Please refer to WSO2's licensing for their components.

## Support

For issues with:
- WSO2 components: Refer to [WSO2 Documentation](https://apim.docs.wso2.com/)
- This chart: Create an issue in the repository
