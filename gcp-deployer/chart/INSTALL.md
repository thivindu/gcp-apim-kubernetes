# Quick Installation Guide

## Prerequisites Checklist

✅ Kubernetes cluster 1.24+ running  
✅ Helm 3.x installed  
✅ kubectl configured  
✅ **NGINX Ingress Controller installed** (see step 1 below)  
✅ At least 8GB RAM, 4 CPU cores available in cluster  

## Installation Steps

### 1. Install NGINX Ingress Controller (REQUIRED)

**This must be done before installing the Helm chart.**

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.0/deploy/static/provider/cloud/deploy.yaml

# Verify NGINX Ingress installation
kubectl get pods --namespace=ingress-nginx

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### 2. Clone or Navigate to Repository

```bash
cd /path/to/gcp-apim-kubernetes/helm-charts/wso2-apim-kubernetes
```

### 3. Add Helm Repositories

```bash
helm repo add wso2 https://helm.wso2.com
helm repo add wso2apk https://github.com/wso2/apk/releases/download/1.3.0-1
helm repo add wso2apkagent https://github.com/wso2/product-apim-tooling/releases/download/1.3.0
helm repo update
```

### 4. Update Dependencies

```bash
helm dependency update
```

This downloads:
- `wso2am-acp-4.5.0-5.tgz` (APIM-ACP from WSO2)
- `apk-helm-1.3.0-1.tgz` (APK from GitHub)
- `apim-apk-agent-1.3.0.tgz` (APK Agent from GitHub)

### 5. Install the Chart

**All components will be deployed to the default namespace.**

**Basic installation (all components enabled):**

```bash
helm install apim .
```

**Custom installation with values file:**

```bash
helm install apim . -f custom-values.yaml
```

### 6. Verify Installation

```bash
# Check all pods in default namespace
kubectl get pods -w

# Check services
kubectl get svc

# Check ingress resources
kubectl get ingress

# Check NGINX Ingress Controller
kubectl get pods -n ingress-nginx

# Get deployment status
helm status apim
```

### 7. Access the Services

Once pods are running, you can access:

**APIM-ACP Publisher:**
- URL: https://am.wso2.com/publisher
- Default credentials: `admin` / `admin`

**Note:** Access URLs depend on your ingress configuration and DNS setup. Check the ingress resources:

```bash
kubectl get ingress
```

## Troubleshooting

### Check NGINX Ingress Controller

```bash
# Verify NGINX is running
kubectl get pods -n ingress-nginx

# Check NGINX logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Check Logs

```bash
# List all pods in default namespace
kubectl get pods

# APIM-ACP logs
kubectl logs -f <acp-pod-name>

# APK logs
kubectl logs -f <apk-pod-name>

# APK Agent logs
kubectl logs -f <apkagent-pod-name>
```

### Common Issues

**NGINX Ingress not installed:**
- Error: Ingress resources cannot be created
- Solution: Install NGINX Ingress Controller (see Step 1)

**Pods stuck in Pending:**
- Check PV/PVC status: `kubectl get pvc`
- Check node resources: `kubectl describe nodes`

**ImagePullBackOff:**
- Verify image pull secrets if using private registry
- Check network connectivity to Docker registries

**CrashLoopBackOff:**
- Check pod logs for specific errors: `kubectl logs <pod-name>`
- Verify resource limits and requests
- Ensure PVCs are bound and accessible

## Upgrade

```bash
# Update dependencies
helm dependency update

# Upgrade to new values
helm upgrade apim . -f new-values.yaml
```

## Uninstall

```bash
# Uninstall the release
helm uninstall apim

# Optionally remove NGINX Ingress Controller
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.0/deploy/static/provider/cloud/deploy.yaml
```

## Chart Configuration

### Key Configuration Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `acp.enabled` | Enable WSO2 APIM-ACP | `true` |
| `apk.enabled` | Enable WSO2 APK | `true` |
| `apkagent.enabled` | Enable APK Agent | `true` |

**Note:** All components are deployed to the **default namespace**. NGINX Ingress Controller must be installed separately.

See [values.yaml](./values.yaml) for complete configuration options.

## Resources Created

The chart creates resources in the **default namespace** including:
- Deployments/StatefulSets for APIM-ACP, APK, and APK Agent
- Services (ClusterIP, NodePort, LoadBalancer)
- ConfigMaps and Secrets
- ServiceAccounts and RBAC
- PersistentVolumeClaims
- Ingress resources (requires NGINX Ingress Controller)
- Custom Resource Definitions (CRDs)

## Next Steps

1. Configure persistent storage for production
2. Set up TLS certificates for ingress
3. Configure external databases (MySQL/PostgreSQL)
4. Set up monitoring and logging
5. Configure backup and disaster recovery

## Support

For issues related to:
- **Chart itself**: Check [PATCHING-NOTES.md](./PATCHING-NOTES.md)
- **WSO2 APIM**: https://docs.wso2.com/display/AM450/
- **WSO2 APK**: https://apk.docs.wso2.com/
