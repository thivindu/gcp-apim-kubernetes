# Getting Started with WSO2 APIM GCP Deployer

This guide walks you through deploying WSO2 APIM on Google Cloud Platform using the GCP Marketplace deployer image.

## Quick Start (3 Simple Steps)

### 1. Set Your GCP Project
```bash
export PROJECT=your-gcp-project-id
```

### 2. Run the Build Script
```bash
cd gcp-deployer
./build.sh
```

### 3. Deploy with Quick Deploy Script
```bash
./quick-deploy.sh
```

That's it! Follow the prompts and your application will be deployed.

---

## Detailed Setup Guide

### Prerequisites Setup

#### 1. Install Required Tools

**gcloud CLI:**
```bash
# macOS
brew install google-cloud-sdk

# Verify installation
gcloud --version
```

**kubectl:**
```bash
# macOS
brew install kubectl

# Verify installation
kubectl version --client
```

**Helm:**
```bash
# macOS
brew install helm

# Verify installation
helm version
```

**Docker:**
- Download from https://www.docker.com/products/docker-desktop
- Verify: `docker --version`

#### 2. Configure GCP

```bash
# Authenticate with GCP
gcloud auth login

# Set your project
export PROJECT=your-gcp-project-id
gcloud config set project $PROJECT

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

#### 3. Create or Connect to GKE Cluster

**Create a new cluster:**
```bash
export CLUSTER_NAME=wso2-apim-cluster
export ZONE=us-central1-a

gcloud container clusters create $CLUSTER_NAME \
  --zone=$ZONE \
  --num-nodes=3 \
  --machine-type=n1-standard-4 \
  --disk-size=50GB
```

**Connect to existing cluster:**
```bash
export CLUSTER_NAME=your-cluster-name
export ZONE=your-zone

gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE
```

**Verify connection:**
```bash
kubectl cluster-info
kubectl get nodes
```

### Building the Deployer Image

#### Option 1: Automated Build (Recommended)

```bash
cd gcp-deployer
export PROJECT=your-gcp-project-id
./build.sh
```

The script will:
- Check for the Helm chart
- Copy dependencies if needed
- Build the Docker image
- Push to Google Container Registry
- Display the image location

#### Option 2: Manual Build

```bash
cd gcp-deployer

# Set variables
export PROJECT=your-gcp-project-id
export APP_ID=wso2-apim
export RELEASE=4.5.0
export REGISTRY=gcr.io/$PROJECT

# Ensure chart is present
if [ ! -d "chart" ]; then
  cp -r ../helm-charts/wso2-apim-kubernetes chart
fi

# Update dependencies
cd chart
helm dependency update
cd ..

# Build image
docker build \
  --build-arg MARKETPLACE_TOOLS_TAG=latest \
  --tag $REGISTRY/$APP_ID/deployer:$RELEASE \
  -f Dockerfile .

# Configure Docker for GCR
gcloud auth configure-docker

# Push image
docker push $REGISTRY/$APP_ID/deployer:$RELEASE
```

### Deploying the Application

#### Option 1: Quick Deploy Script

```bash
./quick-deploy.sh
```

Follow the interactive prompts to configure and deploy.

#### Option 2: Using mpdev Tool

**Install mpdev:**
```bash
docker pull gcr.io/cloud-marketplace-tools/k8s/dev:latest

# Create alias
alias mpdev='docker run --rm \
  -v ~/.config/gcloud:/root/.config/gcloud \
  -v ~/.kube:/root/.kube \
  -v $(pwd):/data \
  gcr.io/cloud-marketplace-tools/k8s/dev:latest'
```

**Deploy:**
```bash
export PROJECT=your-gcp-project-id
export REGISTRY=gcr.io/$PROJECT
export APP_ID=wso2-apim
export RELEASE=4.5.0

mpdev install \
  --deployer=$REGISTRY/$APP_ID/deployer:$RELEASE \
  --parameters='{
    "name": "wso2-apim-1",
    "namespace": "default",
    "gcp.enabled": true,
    "acp.enabled": true,
    "apk.enabled": true,
    "apkagent.enabled": true
  }'
```

#### Option 3: Custom Parameters

Create a parameters file:
```bash
cp parameters.yaml.example parameters.yaml
# Edit parameters.yaml with your settings
```

Deploy with custom parameters:
```bash
mpdev install \
  --deployer=$REGISTRY/$APP_ID/deployer:$RELEASE \
  --parameters="$(cat parameters.yaml)"
```

### Monitoring Deployment

#### Check Application Status
```bash
# List applications
kubectl get applications -n default

# Describe application
kubectl describe application wso2-apim-1 -n default
```

#### Check Pods
```bash
# List all pods
kubectl get pods -n default

# Watch pods
kubectl get pods -n default -w

# Check specific component
kubectl get pods -n default -l app.kubernetes.io/name=wso2-apim
```

#### View Logs
```bash
# All application logs
kubectl logs -n default -l app.kubernetes.io/name=wso2-apim --tail=100

# Follow logs in real-time
kubectl logs -n default -l app.kubernetes.io/name=wso2-apim --tail=100 -f

# Logs for specific pod
kubectl logs -n default <pod-name>
```

#### Check Services
```bash
# List services
kubectl get services -n default

# Get service details
kubectl describe service <service-name> -n default
```

### Accessing the Application

#### Get Service Endpoints
```bash
# Get LoadBalancer IP (if using LoadBalancer service type)
kubectl get service -n default -l app.kubernetes.io/name=wso2-apim

# Port forward for local access
kubectl port-forward -n default service/wso2-apim 9443:9443
```

Then access at: `https://localhost:9443`

### Configuration Options

#### GCP FileStore Configuration

If you need persistent storage with GCP FileStore:

1. **Create FileStore instances:**
```bash
gcloud filestore instances create wso2-apim-filestore \
  --zone=$ZONE \
  --tier=STANDARD \
  --file-share=name="carbondb1",capacity=1TB \
  --network=name=default
```

2. **Get FileStore IP:**
```bash
gcloud filestore instances describe wso2-apim-filestore --zone=$ZONE
```

3. **Update parameters with FileStore details:**
```yaml
gcp:
  fs:
    fileshares:
      carbonDB1:
        fileStoreName: "wso2-apim-filestore"
        fileShareName: "carbondb1"
        ip: "<filestore-ip>"
```

### Troubleshooting

#### Image Pull Errors

Create image pull secret:
```bash
kubectl create secret docker-registry gcr-json-key \
  --docker-server=gcr.io \
  --docker-username=_json_key \
  --docker-password="$(cat ~/key.json)" \
  --docker-email=user@example.com \
  -n default
```

#### Deployment Stuck

Check deployer logs:
```bash
kubectl logs -n default -l app.kubernetes.io/component=deployer
```

Check events:
```bash
kubectl get events -n default --sort-by='.lastTimestamp'
```

#### Pod Failures

Describe failing pod:
```bash
kubectl describe pod <pod-name> -n default
```

Check pod logs:
```bash
kubectl logs <pod-name> -n default --previous
```

#### Permission Issues

Ensure your service account has necessary permissions:
```bash
gcloud projects add-iam-policy-binding $PROJECT \
  --member=serviceAccount:<service-account>@$PROJECT.iam.gserviceaccount.com \
  --role=roles/container.admin
```

### Updating the Deployment

#### Update Configuration

```bash
# Edit the application
kubectl edit application wso2-apim-1 -n default

# Or apply updated manifest
kubectl apply -f updated-manifest.yaml
```

#### Upgrade Chart

1. Update the chart in `chart/` directory
2. Rebuild deployer image:
```bash
./build.sh
```
3. Redeploy with new image

### Cleaning Up

#### Remove Application

Using mpdev:
```bash
mpdev delete \
  --name=wso2-apim-1 \
  --namespace=default
```

Using kubectl:
```bash
kubectl delete application wso2-apim-1 -n default
```

#### Remove All Resources

```bash
# Delete namespace (if using dedicated namespace)
kubectl delete namespace wso2-apim

# Delete cluster (if no longer needed)
gcloud container clusters delete $CLUSTER_NAME --zone=$ZONE
```

### Additional Resources

- [GCP Marketplace Documentation](https://cloud.google.com/marketplace/docs/kubernetes-apps)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Helm Documentation](https://helm.sh/docs/)
- [WSO2 APIM Documentation](https://apim.docs.wso2.com/)

### Getting Help

If you encounter issues:

1. Check logs: `kubectl logs -n default -l app.kubernetes.io/name=wso2-apim`
2. Check events: `kubectl get events -n default`
3. Describe resources: `kubectl describe <resource> <name> -n default`
4. Review the main [README.md](README.md) for detailed configuration options

### Next Steps

After successful deployment:
1. Configure your API Manager instance
2. Set up SSL/TLS certificates
3. Configure external database (if needed)
4. Set up monitoring and alerting
5. Configure backups
6. Review security settings
