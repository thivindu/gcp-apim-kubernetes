# Quick Installation Guide

## Prerequisites Checklist

✅ Kubernetes cluster 1.24+ running  
✅ Helm 3.x installed  
✅ kubectl configured  
✅ At least 8GB RAM, 4 CPU cores available in cluster  

## Installation Steps

### 1. Clone or Navigate to Repository

```bash
cd /path/to/gcp-apim-kubernetes/helm-charts/wso2-apim-kubernetes
```

### 2. Add Helm Repositories (Optional - for reference)

```bash
helm repo add wso2 https://helm.wso2.com
helm repo add wso2apk https://github.com/wso2/apk/releases/download/1.3.0-1
helm repo add wso2apkagent https://github.com/wso2/product-apim-tooling/releases/download/1.3.0
helm repo update
```

### 3. Update Dependencies

```bash
helm dependency update
```

This downloads:
- `apk-helm-1.3.0-1.tgz` (from GitHub)
- `apim-apk-agent-1.3.0.tgz` (from GitHub)

The APIM chart is already included locally as a patched version in `charts/wso2am-all-in-one-patched/`.

### 4. Create Namespace

```bash
kubectl create namespace apim-kubernetes
```

### 5. Install the Chart

**Basic installation (all components enabled):**

```bash
helm install wso2-stack . -n apim-kubernetes
```

**Custom installation with values file:**

```bash
helm install wso2-stack . -n apim-kubernetes -f custom-values.yaml
```

**Install with specific components disabled:**

```bash
# Only APIM and APK (no APK Agent)
helm install wso2-stack . -n apim-kubernetes \
  --set apkagent.enabled=false

# Only APIM (no APK, no Agent)
helm install wso2-stack . -n apim-kubernetes \
  --set apk.enabled=false \
  --set apkagent.enabled=false

# Enable nginx ingress
helm install wso2-stack . -n apim-kubernetes \
  --set nginxIngress.enabled=true
```

### 6. Verify Installation

```bash
# Check all pods
kubectl get pods -n apim-kubernetes

# Check services
kubectl get svc -n apim-kubernetes

# Check ingress (if enabled)
kubectl get ingress -n apim-kubernetes

# Get deployment status
helm status wso2-stack -n apim-kubernetes
```

### 7. Access the Services

Once pods are running, you can access:

**APIM Management Console:**
- URL: `https://am.wso2.com` (configure DNS or use port-forward)
- Default credentials: `admin` / `admin`

**Port Forwarding (for local testing):**

```bash
# APIM Management Console
kubectl port-forward -n apim-kubernetes svc/wso2-stack-apim-am-service 9443:9443

# Access at: https://localhost:9443/carbon
```

## Troubleshooting

### Check Logs

```bash
# APIM logs
kubectl logs -n apim-kubernetes -l deployment=wso2-stack-apim-am -f

# APK logs
kubectl logs -n apim-kubernetes -l app.kubernetes.io/name=apk-helm -f

# APK Agent logs
kubectl logs -n apim-kubernetes -l app=apim-apk-agent -f
```

### Common Issues

**Pods stuck in Pending:**
- Check PV/PVC status: `kubectl get pvc -n apim-kubernetes`
- Check node resources: `kubectl describe nodes`

**ImagePullBackOff:**
- Verify image pull secrets if using private registry
- Check network connectivity to Docker registries

**CrashLoopBackOff:**
- Check pod logs for specific errors
- Verify resource limits and requests
- Ensure PVCs are bound and accessible

## Upgrade

```bash
# Upgrade to new values
helm upgrade wso2-stack . -n apim-kubernetes -f new-values.yaml

# Upgrade with specific values
helm upgrade wso2-stack . -n apim-kubernetes \
  --set apim.wso2.apim.version=4.5.0
```

## Uninstall

```bash
# Uninstall the release
helm uninstall wso2-stack -n apim-kubernetes

# Delete namespace (optional - this deletes PVCs too!)
kubectl delete namespace apim-kubernetes
```

## Chart Configuration

### Key Configuration Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `apim.enabled` | Enable WSO2 APIM | `true` |
| `apk.enabled` | Enable WSO2 APK | `true` |
| `apkagent.enabled` | Enable APK Agent | `true` |
| `nginxIngress.enabled` | Install nginx ingress | `false` |
| `namespace.name` | Kubernetes namespace | `apim-kubernetes` |

See [values.yaml](./values.yaml) for complete configuration options.

## Resources Created

The chart creates approximately **199 Kubernetes resources** including:
- Deployments/StatefulSets
- Services (ClusterIP, NodePort, LoadBalancer)
- ConfigMaps and Secrets
- ServiceAccounts and RBAC
- PersistentVolumeClaims
- Ingress resources
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
