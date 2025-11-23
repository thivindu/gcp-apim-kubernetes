# WSO2 APIM Stack Helm Chart

A unified Helm chart for deploying the complete WSO2 API Manager stack on Kubernetes, including:
- WSO2 API Manager All-in-One (APIM) v4.5.0 **(Patched for sub-chart compatibility)**
- WSO2 APK (API Platform for Kubernetes) v1.3.0
- WSO2 APIM-APK Agent v1.3.0
- Nginx Ingress Controller v1.14.0 (optional)

> **Note**: This chart includes a patched version of the official WSO2 APIM chart. See [PATCHING-NOTES.md](./PATCHING-NOTES.md) for details.

## Prerequisites

- Kubernetes cluster (1.24+)
- Helm 3.x installed
- kubectl configured to access your cluster
- Sufficient cluster resources (CPU, Memory, Storage)

## Quick Start

### 1. Add Required Helm Repositories

The chart uses dependencies from multiple sources:

```bash
# Add WSO2 repository (for reference, we use a patched local chart)
helm repo add wso2 https://helm.wso2.com

# Add WSO2 APK repository  
helm repo add wso2apk https://github.com/wso2/apk/releases/download/1.3.0-1

# Add WSO2 APK Agent repository
helm repo add wso2apkagent https://github.com/wso2/product-apim-tooling/releases/download/1.3.0

# Update repositories
helm repo update
```

### 2. Update Helm Dependencies

Download the required chart dependencies:

```bash
cd helm-charts/wso2-apim-kubernetes
helm dependency update
```

This will download the APK and APK Agent charts. The APIM chart is included as a patched local chart in `charts/wso2am-all-in-one-patched/`.

### 3. Install the Stack

Install the complete stack with default values:

```bash
# Create namespace if it doesn't exist
kubectl create namespace apim-kubernetes

# Install the chart
helm install wso2-stack . -n apim-kubernetes
```

Or with custom values:

```bash
helm install wso2-apim-kubernetes . -n apim-kubernetes -f custom-values.yaml
```

### 4. Verify Installation

Check the status of all components:

```bash
# Check helm release
helm list -n apim-kubernetes

# Check pods
kubectl get pods -n apim-kubernetes -w

# Check nginx ingress controller (if enabled)
kubectl get pods -n ingress-nginx
```

## Installation Order

The chart installs components in the following order:

1. **Namespace**: Creates the `apim-kubernetes` namespace (if `namespace.create: true`)
2. **Nginx Ingress Controller**: Deployed if `nginxIngress.enabled: true`
3. **Sub-charts** (installed in parallel):
   - WSO2 APIM All-in-One (from https://helm.wso2.com)
   - WSO2 APK
   - WSO2 APIM-APK Agent

## Configuration

### Basic Configuration

The main configuration options are in `values.yaml`:

```yaml
# Namespace configuration
namespace:
  create: true
  name: apim-kubernetes

# Enable/disable components
nginxIngress:
  enabled: true

apim:
  enabled: true

apk:
  enabled: true

apkagent:
  enabled: true
```

### Using External Values Files

Each sub-chart can load values from the official WSO2 values files. To use them, create a custom `values.yaml`:

```yaml
apim:
  # Values for wso2am-all-in-one chart from https://helm.wso2.com
  # You can override any values from the official chart here
  
apk:
  # Values for apk-helm chart
  # Add overrides for: https://raw.githubusercontent.com/wso2/apk/main/helm-charts/samples/apk/1.3.0-values.yaml

apkagent:
  # Values for apim-apk-agent chart
  # Add overrides for: https://raw.githubusercontent.com/wso2/apk/main/helm-charts/samples/apim-apk-agent/cp/1.3.0-values.yaml
```

### Advanced Configuration

#### Disable Nginx Ingress Installation

If you already have nginx ingress controller installed:

```yaml
nginxIngress:
  enabled: false
```

#### Disable Specific Components

To install only certain components:

```yaml
apim:
  enabled: true
apk:
  enabled: false
apkagent:
  enabled: false
```

#### Use Different Namespace

```yaml
namespace:
  create: true
  name: my-custom-namespace
```

## Upgrading

To upgrade the stack:

```bash
# Update dependencies first
helm dependency update

# Upgrade the release
helm upgrade wso2-apim-kubernetes . -n apim-kubernetes
```

## Uninstalling

To completely remove the stack:

```bash
# Uninstall the helm release
helm uninstall wso2-apim-kubernetes -n apim-kubernetes

# Delete the namespace (if desired)
kubectl delete namespace apim-kubernetes

# Optionally, remove nginx ingress controller
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.0/deploy/static/provider/cloud/deploy.yaml
```

## Troubleshooting

### Check Nginx Ingress Controller

If the nginx ingress controller is enabled but not working:

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
# List all resources
kubectl get all -n apim-kubernetes

# Check specific pod logs
kubectl logs <pod-name> -n apim-kubernetes

# Describe pods for events
kubectl describe pod <pod-name> -n apim-kubernetes
```

### Helm Debug

```bash
# Dry run to see what will be installed
helm install wso2-apim-kubernetes . -n apim-kubernetes --dry-run --debug

# Check rendered templates
helm template wso2-apim-kubernetes . -n apim-kubernetes
```

## Chart Structure

```
wso2-apim-kubernetes/
├── Chart.yaml              # Chart metadata and dependencies
├── values.yaml             # Default configuration values
├── charts/                 # Downloaded dependency charts (after helm dependency update)
├── templates/
│   ├── _helpers.tpl       # Template helpers
│   ├── namespace.yaml     # Namespace creation
│   ├── deployment.yaml    # Dummy deployment for GCP Marketplace billing
│   ├── serviceaccount.yaml # ServiceAccount for dummy deployment
│   └── nginx-ingress.yaml # Nginx ingress controller manifest (conditionally deployed)
└── README.md
```

## Repository Information

This chart pulls dependencies from the following repositories:

- **WSO2 APIM**: https://helm.wso2.com
- **WSO2 APK**: https://github.com/wso2/apk/releases
- **WSO2 APIM-APK Agent**: https://github.com/wso2/product-apim-tooling/releases

## Original Installation Commands

This chart replaces the following manual installation commands:

```bash
# Add repositories
helm repo add wso2 https://helm.wso2.com
helm repo add wso2apk https://github.com/wso2/apk/releases/download/1.3.0-1
helm repo add wso2apkagent https://github.com/wso2/product-apim-tooling/releases/download/1.3.0
helm repo update

# Install charts separately
helm install apim wso2/wso2am-all-in-one --version 4.5.0-1 -f apim-values.yaml -n apim-kubernetes

helm install apk wso2apk/apk-helm --version 1.3.0 \
  -f https://raw.githubusercontent.com/wso2/apk/main/helm-charts/samples/apk/1.3.0-values.yaml -n apim-kubernetes

helm install apim-apk-agent wso2apkagent/apim-apk-agent --version 1.3.0 \
  -f https://raw.githubusercontent.com/wso2/apk/main/helm-charts/samples/apim-apk-agent/cp/1.3.0-values.yaml -n apim-kubernetes

# Install nginx ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.0/deploy/static/provider/cloud/deploy.yaml
```

## License

This chart is provided as-is. Please refer to WSO2's licensing for their components.

## Support

For issues with:
- WSO2 components: Refer to [WSO2 Documentation](https://apim.docs.wso2.com/)
- This chart: Create an issue in the repository
