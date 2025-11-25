# WSO2 APIM Stack Helm Chart

A unified umbrella Helm chart for deploying the complete WSO2 API Manager stack on Kubernetes, including:
- **WSO2 API Manager ACP (APIM-ACP)** v4.5.0 - API Control Plane
- **WSO2 APK (API Platform for Kubernetes)** v1.3.0 - Data Plane
- **WSO2 APIM-APK Agent** v1.3.0 - Integration Agent

This chart orchestrates three sub-charts as dependencies to provide a complete API Management solution.

## Architecture

```
wso2-apim (umbrella chart v4.5.0)
│
├── acp (wso2am-acp v4.5.0-1)
│   └── API Control Plane - Management console, publisher, devportal
│
├── apk (apk-helm v1.3.0-1)
│   └── Data Plane - Gateway runtime, router, enforcer
│
└── apkagent (apim-apk-agent v1.3.0)
    └── Agent - Connects Control Plane with Data Plane
```

All components are deployed to the **default namespace** (configurable via Helm release namespace).

## Prerequisites

- **Kubernetes cluster** 1.24+ (1.27+ recommended)
- **Helm** 3.8+ installed
- **kubectl** configured to access your cluster
- **NGINX Ingress Controller** (automatically installed by this chart)
- **Minimum Resources**: 8GB RAM, 4 CPU cores
- **Storage**: Persistent volume support (if using StatefulSets)

## Quick Start

### 1. Navigate to Chart Directory

```bash
cd helm-charts/wso2-apim-kubernetes
```

### 2. Update Chart Dependencies

Download required sub-charts:

```bash
helm dependency update
```

This downloads:
- `wso2am-acp-4.5.0-1.tgz` - From local charts directory
- `apk-helm-1.3.0-1.tgz` - From WSO2 APK GitHub releases
- `apim-apk-agent-1.3.0.tgz` - From WSO2 Product APIM Tooling GitHub releases

### 3. Install the Stack

**Basic installation (all components enabled):**

```bash
helm install apim .
```

**With custom namespace:**

```bash
helm install apim . --namespace wso2 --create-namespace
```

**With custom values:**

```bash
helm install apim . -f custom-values.yaml
```

### 4. Verify Installation

```bash
# Check helm release
helm list

# Watch pods come up
kubectl get pods -w

# Check all resources
kubectl get all

# Check ingress resources  
kubectl get ingress

# Check specific component pods
kubectl get pods -l app.kubernetes.io/instance=apim
```

## Chart Dependencies

This umbrella chart has three sub-chart dependencies defined in `Chart.yaml`:

| Sub-chart | Version | Repository | Alias | Condition |
|-----------|---------|------------|-------|-----------|
| wso2am-acp | 4.5.0-1 | file://charts | acp | acp.enabled |
| apk-helm | 1.3.0-1 | GitHub | apk | apk.enabled |
| apim-apk-agent | 1.3.0 | GitHub | apkagent | apkagent.enabled |

## Configuration

### Basic Configuration

Enable or disable components in `values.yaml`:

```yaml
acp:
  enabled: true    # WSO2 APIM Control Plane

apk:
  enabled: true    # WSO2 APK Data Plane

apkagent:
  enabled: true    # Integration Agent
```

### Component-Specific Configuration

#### ACP (API Control Plane)

```yaml
acp:
  wso2:
    apim:
      version: "4.5.0"
      secureVaultEnabled: false
      portOffset: 0
      configurations:
        # Add APIM TOML configurations here
        userStore: |
          [user_store]
          type = "database"
```

#### APK (Data Plane)

```yaml
apk:
  wso2:
    apk:
      auth:
        enabled: true
        enableServiceAccountCreation: true
        serviceAccountName: wso2apk-platform
      webhooks:
        validatingwebhookconfigurations: false
        mutatingwebhookconfigurations: false
```

#### APK Agent

```yaml
apkagent:
  replicaCount: 1
  image:
    repository: wso2/apim-apk-agent
    tag: 1.3.0
  controlPlane:
    serviceURL: https://apim-acp-1-service.default.svc.cluster.local:9443/
    username: admin
    password: admin
    environmentLabels: Default_apk
  dataPlane:
    k8ResourceEndpoint: https://apim-wso2-apk-config-ds-service.default.svc.cluster.local:9443/api/configurator/apis/generate-k8s-resources
    namespace: default
```

### Resource Configuration

Adjust resources for each component:

```yaml
apkagent:
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"
```

## Advanced Configuration

### Disable Specific Components

Install only the components you need:

```yaml
acp:
  enabled: true    # Control Plane only
apk:
  enabled: false
apkagent:
  enabled: false
```

### Custom Values Per Sub-chart

Override any sub-chart values using the alias prefix:

```yaml
acp:
  # All wso2am-acp chart values
  kubernetes:
    ingressClass: "nginx"
  wso2:
    deployment:
      replicas: 2

apk:
  # All apk-helm chart values
  wso2:
    apk:
      dp:
        enabled: true

apkagent:
  # All apim-apk-agent chart values
  replicaCount: 2
```

## Upgrading

### Update Dependencies

```bash
helm dependency update
```

### Upgrade Release

```bash
helm upgrade apim . -f custom-values.yaml
```

### Rolling Back

```bash
helm rollback apim
```

## Uninstalling

Remove the complete stack:

```bash
# Uninstall the release
helm uninstall apim

# Clean up PVCs if needed
kubectl delete pvc --all

# Remove namespace (if custom namespace was used)
kubectl delete namespace wso2
```

## Troubleshooting

### Check Sub-chart Status

```bash
# List all pods
kubectl get pods

# Check logs for ACP
kubectl logs -l app.kubernetes.io/name=wso2am-acp

# Check logs for APK
kubectl logs -l app.kubernetes.io/name=apk

# Check logs for APK Agent
kubectl logs -l app.kubernetes.io/name=apim-apk-agent
```

### Common Issues

**Dependency Download Failed:**
```bash
# Clear Helm cache
rm -rf ~/.cache/helm

# Update dependencies again
helm dependency update
```

**Pods Stuck in Pending:**
```bash
# Check PVC status
kubectl get pvc

# Check node resources
kubectl describe nodes

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

**ImagePullBackOff:**
```bash
# Check if imagePullSecrets are configured
kubectl get secrets

# Verify image exists
kubectl describe pod <pod-name> | grep -A5 Events
```

**Ingress Not Working:**
```bash
# Verify NGINX Ingress Controller
kubectl get pods -n ingress-nginx

# Check ingress resources
kubectl get ingress -o yaml

# Verify DNS/hostname configuration
kubectl describe ingress
```

**Connection Issues Between Components:**
```bash
# Verify service endpoints
kubectl get svc
kubectl get endpoints

# Test connectivity from within cluster
kubectl run test-pod --rm -it --image=busybox -- sh
# Then: wget -O- http://service-name:port
```

### Validation

```bash
# Render templates without installing
helm template apim . --debug

# Dry run installation
helm install apim . --dry-run --debug

# Check dependency status
helm dependency list
```

## Chart Structure

```
wso2-apim-kubernetes/
├── Chart.yaml              # Chart metadata and dependencies
├── values.yaml             # Default configuration values
├── values-bk.yaml          # Backup/alternative values
├── charts/                 # Sub-chart archives (after helm dependency update)
│   ├── wso2am-acp-4.5.0-1.tgz
│   ├── apk-helm-1.3.0-1.tgz
│   └── apim-apk-agent-1.3.0.tgz
├── templates/
│   └── _helpers.tpl        # Template helper functions
├── README.md               # This file
├── INSTALL.md              # Quick installation guide
└── PATCHING-NOTES.md       # Patching and maintenance notes
```

## Default Services Created

After installation, the following services are created in the default namespace:

### ACP Services
- `apim-acp-1-service` - APIM Control Plane (ports: 9443, 8243, 8280, 5672)

### APK Services
- `apim-wso2-apk-config-ds-service` - APK Config Deployer
- `apim-wso2-apk-adapter-service` - APK Adapter
- `apim-wso2-apk-common-controller-service` - Common Controller
- `apim-wso2-apk-gateway-service` - Gateway Runtime
- `apim-wso2-apk-router-service` - Envoy Router
- `apim-wso2-apk-ratelimiter-service` - Rate Limiter

### APK Agent Services
- `apim-apk-agent-service` - APK Agent

## Accessing the Deployment

### Default URLs (after configuring DNS/hosts file)

- **Publisher Portal**: https://am.wso2.com/publisher
- **Developer Portal**: https://am.wso2.com/devportal
- **Admin Portal**: https://am.wso2.com/admin
- **Gateway**: https://api.am.wso2.com

**Default Credentials**: `admin` / `admin`

### Configure DNS

Add entries to your `/etc/hosts` file:

```bash
<EXTERNAL-IP>  am.wso2.com
<EXTERNAL-IP>  api.am.wso2.com
<EXTERNAL-IP>  idp.am.wso2.com
```

Get the external IP:

```bash
kubectl get ingress
# or
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

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


## Support

For issues with:
- WSO2 components: Refer to [WSO2 Documentation](https://apim.docs.wso2.com/)
- This chart: Create an issue in the repository
