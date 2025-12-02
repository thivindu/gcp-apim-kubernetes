# WSO2 APIM on Google Cloud Platform Kubernetes

[![GCP Marketplace](https://img.shields.io/badge/GCP-Marketplace-blue)](https://console.cloud.google.com/marketplace)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.24+-blue)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-3.x-blue)](https://helm.sh/)

Production-ready deployment of WSO2 API Manager on Google Cloud Platform Kubernetes.

## 🚀 Quick Start

### Deploy via GCP Marketplace Console
Visit the [GCP Marketplace](https://console.cloud.google.com/marketplace) and search for "WSO2 APIM".

### Deploy via Command Line

```bash
# Clone deployment assets
git clone https://github.com/sgayangi/gcp-apim-kubernetes.git
cd gcp-apim-kubernetes/gcp-deployer

# Run interactive deployment
./deploy-cli.sh
```

## 📋 Prerequisites

- Google Cloud Platform account with billing enabled
- GKE cluster (Kubernetes 1.24+)
- `kubectl` configured to access your cluster
- `gcloud` CLI installed and authenticated
- `Helm 3.x` (optional, for Helm-based deployment)

## 📦 Repository Structure

```
gcp-apim-kubernetes/
├── gcp-deployer/              # GCP Marketplace deployer image
│   ├── chart/                # Packaged Helm chart
│   ├── schema.yaml           # Marketplace schema
│   ├── Dockerfile            # Deployer image definition
│   ├── deploy-cli.sh         # Quick deployment script
│   ├── CLI-DEPLOYMENT.md     # Detailed CLI guide
│   ├── GETTING-STARTED.md    # Step-by-step guide
│   └── data-test/            # Verification tests
├── helm-charts/              # Source Helm charts
│   └── wso2-apim-kubernetes/ # Main chart
├── terraform/                # Terraform deployment (optional)
└── DEPLOY-README.md          # This file
```

## 🎯 Deployment Options

### Option 1: GCP Marketplace UI
1. Go to [GCP Marketplace](https://console.cloud.google.com/marketplace)
2. Search for "WSO2 APIM"
3. Click "Configure" and follow the wizard

### Option 2: Command Line (mpdev)

```bash
export APP_INSTANCE_NAME=wso2-apim-1
export NAMESPACE=default

mpdev install \
  --deployer=us-docker.pkg.dev/wso2-marketplace-public/wso2-marketplace/deployer:4.5 \
  --parameters='{
    "name": "'${APP_INSTANCE_NAME}'",
    "namespace": "'${NAMESPACE}'",
    "gcp.enabled": true,
    "acp.enabled": true,
    "apk.enabled": true,
    "apkagent.enabled": true
  }'
```

### Option 3: Helm

```bash
cd gcp-deployer

helm install wso2-apim-1 \
  --namespace default \
  --create-namespace \
  --set gcp.enabled=true \
  --set acp.enabled=true \
  --set apk.enabled=true \
  --set apkagent.enabled=true \
  ./chart
```

## 📚 Documentation

- **[CLI Deployment Guide](gcp-deployer/CLI-DEPLOYMENT.md)** - Complete command-line deployment instructions
- **[Getting Started](gcp-deployer/GETTING-STARTED.md)** - Detailed setup and configuration guide
- **[Main README](gcp-deployer/README.md)** - Deployer image documentation
- **[WSO2 APIM Docs](https://apim.docs.wso2.com/)** - Official product documentation

## ⚙️ Configuration

The deployment supports various configuration options:

### Core Components
- **ACP (API Manager Control Plane)** - Main API management functionality
- **APK (API Platform for Kubernetes)** - Kubernetes-native API management
- **APK Agent** - Integration agent between APIM and APK

### GCP Integration
- FileStore for persistent storage
- GCP-specific networking and security
- Cloud SQL integration (optional)
- Secrets Manager integration (optional)

### Example Configuration

```yaml
gcp:
  enabled: true
  fs:
    capacity: 1Ti

acp:
  enabled: true
  deployment:
    replicas: 2

apk:
  enabled: true

apkagent:
  enabled: true
```

## 🔍 Verification

After deployment, verify the installation:

```bash
# Check application status
kubectl get application wso2-apim-1 -n default

# Check pods
kubectl get pods -n default -l app.kubernetes.io/name=wso2-apim-1

# Check services
kubectl get services -n default

# View logs
kubectl logs -n default -l app.kubernetes.io/name=wso2-apim-1 --tail=100
```

## 🌐 Accessing the Application

### Get Service Endpoint

```bash
# For LoadBalancer service
kubectl get service -n default -l app.kubernetes.io/name=wso2-apim-1

# Port forward for local testing
kubectl port-forward -n default service/wso2-apim 9443:9443
```

Then access at: `https://localhost:9443`

## 🔧 Troubleshooting

### Common Issues

**Image Pull Errors:**
```bash
gcloud auth configure-docker us-docker.pkg.dev
```

**Permission Issues:**
Ensure your GKE cluster has the necessary IAM permissions for the service accounts.

**Resource Constraints:**
```bash
kubectl describe nodes
kubectl top nodes
```

### Get Help

- Check [Troubleshooting Guide](gcp-deployer/GETTING-STARTED.md#troubleshooting)
- View [GitHub Issues](https://github.com/sgayangi/gcp-apim-kubernetes/issues)
- Consult [WSO2 Documentation](https://apim.docs.wso2.com/)

## 🔄 Updating

```bash
# Using Helm
helm upgrade wso2-apim-1 --namespace default ./chart

# Using mpdev
mpdev upgrade --name=wso2-apim-1 --namespace=default
```

## 🗑️ Uninstalling

```bash
# Using kubectl
kubectl delete application wso2-apim-1 -n default

# Using Helm
helm uninstall wso2-apim-1 -n default

# Using mpdev
mpdev delete --name=wso2-apim-1 --namespace=default
```

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## 🔗 Links

- [GCP Marketplace Listing](https://console.cloud.google.com/marketplace)
- [WSO2 APIM Website](https://wso2.com/api-manager/)
- [WSO2 Documentation](https://apim.docs.wso2.com/)
- [GitHub Repository](https://github.com/sgayangi/gcp-apim-kubernetes)
- [Issue Tracker](https://github.com/sgayangi/gcp-apim-kubernetes/issues)

## 📞 Support

For enterprise support, contact [WSO2](https://wso2.com/contact/).

---

**Public Cloning Endpoint:** `https://github.com/sgayangi/gcp-apim-kubernetes.git`

For CLI deployment, clone this repository and follow the [CLI Deployment Guide](gcp-deployer/CLI-DEPLOYMENT.md).
