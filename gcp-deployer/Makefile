include ../crd.Makefile
include ../gcloud.Makefile
include ../var.Makefile
include ../app.Makefile

CHART_NAME := wso2-apim-kubernetes

APP_ID ?= wso2-apim

# The digest should be updated automatically, or tag should be removed for the latest.
TRACK ?= 4.5

# Marketplace Tools tag or digest.
MARKETPLACE_TOOLS_TAG ?= latest

# Registry for deployer image
REGISTRY ?= gcr.io/$(PROJECT)

# Image URL for the deployer image
APP_DEPLOYER_IMAGE ?= $(REGISTRY)/$(APP_ID)/deployer:$(RELEASE)
APP_DEPLOYER_IMAGE_TRACK_TAG ?= $(REGISTRY)/$(APP_ID)/deployer:$(TRACK)

# Main image
APP_MAIN_IMAGE ?= docker.wso2.com/wso2am:4.5.0

NAME ?= wso2-apim-1

APP_PARAMETERS ?= { \
  "name": "$(NAME)", \
  "namespace": "$(NAMESPACE)", \
  "gcp.enabled": true, \
  "acp.enabled": true, \
  "apk.enabled": true, \
  "apkagent.enabled": true \
}

# app_v2.Makefile provides the main targets for installing the application.
# It requires several APP_* variables defined above, and thus must be included after.
include ../app_v2.Makefile

# Build structure. The app/build target builds the deployer image.
# This is the main target for building the deployer image.

app/build:: .build/deployer/helm \
            .build/$(CHART_NAME)/$(TRACK)

.build/deployer/helm: deployer/* \
                      chart/* \
                      chart/charts/* \
                      chart/templates/* \
                      schema.yaml \
                      apptest/deployer/schema.yaml \
                      .build/var/APP_DEPLOYER_IMAGE \
                      .build/var/APP_DEPLOYER_IMAGE_TRACK_TAG \
                      .build/var/MARKETPLACE_TOOLS_TAG \
                      .build/var/REGISTRY \
                      .build/var/TRACK \
                      | .build/deployer
	$(call print_target)
	docker build \
	    --build-arg REGISTRY="$(REGISTRY)/$(APP_ID)" \
	    --build-arg TAG="$(RELEASE)" \
	    --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f Dockerfile .
	docker tag "$(APP_DEPLOYER_IMAGE)" "$(APP_DEPLOYER_IMAGE_TRACK_TAG)"
	docker push "$(APP_DEPLOYER_IMAGE)"
	docker push "$(APP_DEPLOYER_IMAGE_TRACK_TAG)"
	@touch "$@"

.build/$(CHART_NAME)/$(TRACK): .build/var/REGISTRY \
                                .build/var/TRACK
	$(call print_target)
	@mkdir -p "$@"
