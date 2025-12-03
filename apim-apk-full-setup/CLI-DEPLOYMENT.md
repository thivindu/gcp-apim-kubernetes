# Deploying WSO2 APIM via Command Line

This guide explains how to deploy WSO2 APIM Kubernetes application using command-line tools.

## Clone Deployment Assets

First, clone the deployment repository:

```bash
git clone https://github.com/sgayangi/gcp-apim-kubernetes.git
cd gcp-apim-kubernetes/gcp-deployer
```

## Prerequisites

1. **kubectl** - Kubernetes command-line tool
2. **gcloud** - Google Cloud SDK
3. **A GKE cluster** - Running Kubernetes cluster
4. **Application CRD** - Installed on your cluster

## Step 1: Install Application CRD

The Application CRD is required for Marketplace applications:

```bash
kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
```

## Step 2: Set Environment Variables

```bash
# Your GCP project
export PROJECT_ID=your-gcp-project-id

# Name for your application instance
export APP_INSTANCE_NAME=wso2-apim-1

# Kubernetes namespace
export NAMESPACE=default

# Image registry (use the Marketplace images)
export IMAGE_REGISTRY=us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace

# Image tag
export TAG=4.5
```

## Step 3: Create Namespace (if needed)

```bash
kubectl create namespace "${NAMESPACE}" || true
```

## Step 4: Configure GCP Settings (Optional)

If you want to use GCP-specific features like FileStore:

```bash
# Enable GCP integration
export GCP_ENABLED=true

# FileStore configuration (if using)
export FILESTORE_CAPACITY=1Ti
export CARBONDB1_FILESTORE_NAME=wso2-apim-filestore
export CARBONDB1_FILESHARE_NAME=carbondb1
export CARBONDB1_IP=10.0.0.2
```

## Step 5: Deploy Using kubectl

### Option A: Using Application Resource

Create an application manifest file `wso2-apim-app.yaml`:

```yaml
apiVersion: app.k8s.io/v1beta1
kind: Application
metadata:
  name: "${APP_INSTANCE_NAME}"
  namespace: "${NAMESPACE}"
  labels:
    app.kubernetes.io/name: "${APP_INSTANCE_NAME}"
spec:
  descriptor:
    type: WSO2 APIM
    version: "4.5.0"
    description: WSO2 API Manager on Kubernetes
    links:
    - description: User Guide
      url: https://apim.docs.wso2.com/
  selector:
    matchLabels:
      app.kubernetes.io/name: "${APP_INSTANCE_NAME}"
  componentKinds:
  - group: apps/v1
    kind: Deployment
  - group: v1
    kind: Service
  - group: v1
    kind: ConfigMap
  - group: v1
    kind: Secret
```

Apply with environment variable substitution:

```bash
cat wso2-apim-app.yaml | envsubst | kubectl apply -f -
```

### Option B: Using Helm Directly

If you have the Helm chart locally:

```bash
# Add repository (if available)
# helm repo add wso2 https://helm.wso2.com
# helm repo update

# Install with custom values
helm install "${APP_INSTANCE_NAME}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set gcp.enabled=true \
  --set acp.enabled=true \
  --set apk.enabled=true \
  --set apkagent.enabled=true \
  ./chart
```

### Option C: Using mpdev Tool (Recommended for Testing)

Install mpdev:

```bash
docker pull gcr.io/cloud-marketplace-tools/k8s/dev:latest

alias mpdev='docker run \
  --rm \
  --net=host \
  -v ~/.config/gcloud:/root/.config/gcloud \
  -v ~/.kube:/root/.kube \
  -v $(pwd):/data \
  gcr.io/cloud-marketplace-tools/k8s/dev:latest'
```

Deploy the application:

```bash
mpdev install \
  --deployer=${IMAGE_REGISTRY}/deployer:${TAG} \
  --parameters='{
    "name": "'${APP_INSTANCE_NAME}'",
    "namespace": "'${NAMESPACE}'",
    "gcp.enabled": true,
    "acp.enabled": true,
    "apk.enabled": true,
    "apkagent.enabled": true
  }'
```

## Step 6: Verify Deployment

Check application status:

```bash
kubectl get application "${APP_INSTANCE_NAME}" -n "${NAMESPACE}"
```

Check pods:

```bash
kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name="${APP_INSTANCE_NAME}"
```

Check services:

```bash
kubectl get services -n "${NAMESPACE}" -l app.kubernetes.io/name="${APP_INSTANCE_NAME}"
```

View logs:

```bash
kubectl logs -n "${NAMESPACE}" -l app.kubernetes.io/name="${APP_INSTANCE_NAME}" --tail=100
```

## Step 7: Access the Application

### Get Service Endpoint

For LoadBalancer service:

```bash
SERVICE_IP=$(kubectl get service -n "${NAMESPACE}" \
  -l app.kubernetes.io/name="${APP_INSTANCE_NAME}" \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')

echo "Application available at: https://${SERVICE_IP}:9443"
```

### Port Forward (for testing)

```bash
kubectl port-forward -n "${NAMESPACE}" \
  service/wso2-apim 9443:9443
```

Then access at: `https://localhost:9443`

## Advanced Configuration

### Custom Values File

Create `custom-values.yaml`:

```yaml
gcp:
  enabled: true
  fs:
    capacity: 1Ti

acp:
  enabled: true
  deployment:
    image: us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/wso2am-acp:4.5

apk:
  enabled: true

apkagent:
  enabled: true
```

Apply with:

```bash
helm install "${APP_INSTANCE_NAME}" \
  --namespace "${NAMESPACE}" \
  --values custom-values.yaml \
  ./chart
```

## Updating the Application

```bash
helm upgrade "${APP_INSTANCE_NAME}" \
  --namespace "${NAMESPACE}" \
  --values custom-values.yaml \
  ./chart
```

## Uninstalling

### Using kubectl

```bash
kubectl delete application "${APP_INSTANCE_NAME}" -n "${NAMESPACE}"
```

### Using Helm

```bash
helm uninstall "${APP_INSTANCE_NAME}" -n "${NAMESPACE}"
```

### Using mpdev

```bash
mpdev delete \
  --name="${APP_INSTANCE_NAME}" \
  --namespace="${NAMESPACE}"
```

### Complete Cleanup

```bash
# Delete all resources
kubectl delete all -n "${NAMESPACE}" -l app.kubernetes.io/name="${APP_INSTANCE_NAME}"

# Delete namespace (if dedicated)
kubectl delete namespace "${NAMESPACE}"
```

## Troubleshooting

### Check Deployer Logs

If using the deployer image:

```bash
kubectl logs -n "${NAMESPACE}" -l app.kubernetes.io/component=deployer
```

### Check Events

```bash
kubectl get events -n "${NAMESPACE}" --sort-by='.lastTimestamp'
```

### Describe Resources

```bash
kubectl describe application "${APP_INSTANCE_NAME}" -n "${NAMESPACE}"
kubectl describe pods -n "${NAMESPACE}" -l app.kubernetes.io/name="${APP_INSTANCE_NAME}"
```

### Common Issues

**Image Pull Errors:**
```bash
# Ensure you have access to the image registry
gcloud auth configure-docker us-docker.pkg.dev
```

**Permission Issues:**
```bash
# Check service account permissions
kubectl get serviceaccount -n "${NAMESPACE}"
kubectl describe serviceaccount <sa-name> -n "${NAMESPACE}"
```

**Resource Constraints:**
```bash
# Check cluster resources
kubectl top nodes
kubectl describe nodes
```

## Support

For more information, see:
- [WSO2 APIM Documentation](https://apim.docs.wso2.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GCP Marketplace Documentation](https://cloud.google.com/marketplace/docs)
