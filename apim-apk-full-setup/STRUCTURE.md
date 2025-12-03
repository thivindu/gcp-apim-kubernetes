# GCP Deployer - Complete Structure Summary

## ✅ Successfully Created Structure

The `gcp-deployer/` directory has been created with all necessary files for deploying WSO2 APIM on Google Cloud Platform.

## 📁 Directory Structure

```
gcp-deployer/
├── Dockerfile                      # Deployer container image definition
├── Makefile                        # Build automation (advanced usage)
├── schema.yaml                     # GCP Marketplace schema with all parameters
├── .dockerignore                   # Docker build exclusions
├── build.sh                        # ⭐ Automated build script
├── quick-deploy.sh                 # ⭐ One-command deployment script
├── deployer_envsubst.yaml          # Environment variable substitutions
├── parameters.yaml.example         # Example parameter configuration
├── README.md                       # Comprehensive documentation
├── GETTING-STARTED.md              # ⭐ Step-by-step deployment guide
├── apptest/
│   └── deployer/
│       └── schema.yaml            # Application test schema
└── chart/                         # Complete Helm chart with dependencies
    ├── Chart.yaml
    ├── values.yaml
    ├── templates/
    │   └── _helpers.tpl
    └── charts/                    # All chart dependencies included
        ├── wso2am-acp-4.5.0-1.tgz
        ├── apk-helm-1.3.0-1.tgz
        └── apim-apk-agent-1.3.0.tgz
```

## 🚀 Quick Start Commands

### 1. Simplest Way (Recommended)
```bash
cd gcp-deployer
export PROJECT=your-gcp-project-id
./quick-deploy.sh
```

### 2. Manual Steps
```bash
cd gcp-deployer
export PROJECT=your-gcp-project-id

# Build
./build.sh

# Deploy
mpdev install \
  --deployer=gcr.io/$PROJECT/wso2-apim/deployer:4.5.0 \
  --parameters='{"name": "wso2-apim-1", "namespace": "default", "gcp.enabled": true}'
```

## 📋 What Each File Does

### Essential Files

| File              | Purpose                                   |
| ----------------- | ----------------------------------------- |
| `Dockerfile`      | Defines the deployer container image      |
| `schema.yaml`     | GCP Marketplace parameter definitions     |
| `chart/`          | Complete Helm chart with all dependencies |
| `build.sh`        | Automated build and push to GCR           |
| `quick-deploy.sh` | Interactive deployment wizard             |

### Documentation

| File                      | Purpose                              |
| ------------------------- | ------------------------------------ |
| `README.md`               | Detailed documentation and reference |
| `GETTING-STARTED.md`      | Step-by-step beginner guide          |
| `parameters.yaml.example` | Parameter template                   |

### Supporting Files

| File                           | Purpose                     |
| ------------------------------ | --------------------------- |
| `Makefile`                     | Advanced build automation   |
| `.dockerignore`                | Docker build exclusions     |
| `deployer_envsubst.yaml`       | mpdev testing configuration |
| `apptest/deployer/schema.yaml` | Application testing schema  |

## 🎯 Key Features

✅ **Complete Helm Chart**: All dependencies (wso2am-acp, apk-helm, apim-apk-agent) included  
✅ **GCP Integration**: FileStore, persistent volumes, and GCP-specific configs  
✅ **Automated Scripts**: Build and deploy with single commands  
✅ **Comprehensive Docs**: Multiple levels of documentation  
✅ **Marketplace Ready**: Follows GCP Marketplace best practices  
✅ **Configurable**: Extensive parameter support via schema.yaml  

## 📝 Configuration Parameters

The deployer supports extensive configuration through `schema.yaml`:

### Core Parameters
- Application name and namespace
- Service account configuration
- GCP integration toggle

### GCP FileStore Configuration
- Storage capacity
- FileStore names and IPs for:
  - CarbonDB instances (1 & 2)
  - Solr instances (1 & 2)

### Component Toggles
- ACP (API Manager Control Plane)
- APK (API Platform for Kubernetes)
- APK Agent

## 🔧 Prerequisites

Before using the deployer, ensure you have:

1. **GCP Project** with billing enabled
2. **GKE Cluster** running (or create one)
3. **Tools installed**:
   - gcloud CLI
   - kubectl
   - Docker
   - Helm 3.x

## 📚 Documentation Hierarchy

1. **This file**: Quick overview and structure
2. **GETTING-STARTED.md**: Complete step-by-step guide for beginners
3. **README.md**: Comprehensive reference documentation
4. **parameters.yaml.example**: Configuration template

## ✨ Next Steps

### For First-Time Users
→ Read `GETTING-STARTED.md` for complete setup instructions

### For Experienced Users
→ Run `./quick-deploy.sh` or customize `parameters.yaml.example`

### For Advanced Configuration
→ Review `schema.yaml` for all available parameters
→ Check `README.md` for detailed configuration options

## 🎓 Common Usage Patterns

### Standard Deployment
```bash
export PROJECT=my-gcp-project
cd gcp-deployer
./quick-deploy.sh
```

### Custom Configuration
```bash
cp parameters.yaml.example my-config.yaml
# Edit my-config.yaml
./build.sh
mpdev install --deployer=gcr.io/$PROJECT/wso2-apim/deployer:4.5.0 \
  --parameters="$(cat my-config.yaml)"
```

### Development/Testing
```bash
./build.sh
mpdev install --deployer=gcr.io/$PROJECT/wso2-apim/deployer:4.5.0 \
  --parameters='{"name": "test", "namespace": "test"}'
```

## 🐛 Troubleshooting

See `GETTING-STARTED.md` for detailed troubleshooting section covering:
- Image pull errors
- Deployment issues
- Permission problems
- Pod failures
- Common configuration mistakes

## 📖 Additional Resources

- [GCP Marketplace Docs](https://cloud.google.com/marketplace/docs/kubernetes-apps)
- [WSO2 APIM Docs](https://apim.docs.wso2.com/)
- [Kubernetes Application CRD](https://github.com/kubernetes-sigs/application)

## ✅ Verification Checklist

- [x] Dockerfile created
- [x] Schema.yaml with GCP parameters
- [x] Chart directory with all dependencies
- [x] Build automation scripts
- [x] Deployment scripts
- [x] Comprehensive documentation
- [x] Example configurations
- [x] Testing support files

---

**Status**: ✅ Ready to use!

**Recommended starting point**: Run `./quick-deploy.sh` after setting `export PROJECT=your-gcp-project-id`
