WORK_DIR := $(dir $(abspath $(MAKEFILE_LIST)))
## See https://github.com/kubermatic/kubermatic-installer/releases
# default value, overwrite for chosen KKP release
KKP_VERSION ?= 'v2.21.4'
KKP_ADDON_CUSTOM_REPO ?= 'quay.io/kubermatic/ps-addons'
# default value, overwrite to build a new addon version for the same KKP version
TAG_POST_FIX ?= '2023-01-02'
TAG ?= ${KKP_VERSION}-${TAG_POST_FIX}

.PHONY: docker-release docker-build

docker-build:
	docker build --build-arg KKP_VERSION=${KKP_VERSION} -t ${KKP_ADDON_CUSTOM_REPO}:${TAG} .

docker-release: docker-build
	docker push ${KKP_ADDON_CUSTOM_REPO}:${TAG}

############## ARGOCD ADDON

.PHONY: kustomize-build-argocd
kustomize-build-argocd:
	docker run --rm --volume ${WORK_DIR}:/src \
	  k8s.gcr.io/kustomize/kustomize:v4.4.0 \
	  build /src/kustomize/argocd/ > custom-addon/argocd/00-manifest.yaml

############## FLUX2 ADDON

.PHONY: kustomize-build-flux2
kustomize-build-flux2:
	docker run --rm --volume ${WORK_DIR}:/src \
	  k8s.gcr.io/kustomize/kustomize:v4.4.0 \
	  build /src/kustomize/flux2/ > custom-addon/flux2/00-manifest.yaml

############## TRIDENT ADDON
TRIDENT_INSTALLER_REPO ?= 'quay.io/kubermatic-labs/trident-installer'
## See https://github.com/NetApp/trident/releases
TRIDENT_VERSION ?= 20.07.0
## See https://hub.docker.com/r/bitnami/kubectl/tags
BITNAMI_KUBECTL_VERSION ?= 1.19

.PHONY: trident-installer-docker-build
trident-installer-docker-build:
	docker build \
		--build-arg TRIDENT_VERSION=${TRIDENT_VERSION} \
		--build-arg BITNAMI_KUBECTL_VERSION=${BITNAMI_KUBECTL_VERSION} \
		-t ${TRIDENT_INSTALLER_REPO}:${TRIDENT_VERSION} custom-addon/trident-installer

.PHONY: trident-installer-docker-release
trident-installer-docker-release: trident-installer-docker-build
	docker push ${TRIDENT_INSTALLER_REPO}:${TRIDENT_VERSION}


HELM_OPERATOR_VERSION ?= 1.2.0

.PHONY: sync-helm-operator-manifests
sync-helm-operator-manifests:
	mkdir -p custom-addon/helm-operator || true

	curl -L https://raw.githubusercontent.com/fluxcd/helm-operator/${HELM_OPERATOR_VERSION}/deploy/crds.yaml \
		> custom-addon/helm-operator/crds.yaml
	
	curl -L https://raw.githubusercontent.com/fluxcd/helm-operator/${HELM_OPERATOR_VERSION}/deploy/rbac.yaml \
		> custom-addon/helm-operator/rbac.yaml

	curl -L https://raw.githubusercontent.com/fluxcd/helm-operator/${HELM_OPERATOR_VERSION}/deploy/deployment.yaml \
		| sed 's/# - --enabled-helm-versions=v3/- --enabled-helm-versions=v3/' \
		> custom-addon/helm-operator/deployment.yaml


############## THEIA-IDE ADDON
THEIA_REPO ?= 'quay.io/kubermatic-labs/theia-ide'
THEIA_TAG = $(shell date -I)
.PHONY: theia-docker-build
theia-docker-build:
	docker build -t ${THEIA_REPO}:${THEIA_TAG} custom-addon/theia-ide

.PHONY: theia-docker-release
theia-docker-release: theia-docker-build
	docker push ${THEIA_REPO}:${THEIA_TAG}

