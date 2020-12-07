
## See https://github.com/kubermatic/kubermatic-installer/releases
KUBERMATIC_VERSION ?= v2.15.0-rc.3
ADDON_CUSTOM_REPO ?= 'quay.io/kubermatic/ps-addons'
ADDON_CUSTOM_REPO_OS ?= ${ADDON_CUSTOM_REPO}
TAG ?= ${KUBERMATIC_VERSION}-4
OSTAG = openshift-${TAG}

.PHONY: docker-release docker-build

docker-build:
	docker build --build-arg KUBERMATIC_VERSION=${KUBERMATIC_VERSION} -t ${ADDON_CUSTOM_REPO}:${TAG} .
	docker build --build-arg KUBERMATIC_VERSION=${KUBERMATIC_VERSION} -f Dockerfile.openshift -t ${ADDON_CUSTOM_REPO_OS}:${OSTAG}  .

docker-release: docker-build
	docker push ${ADDON_CUSTOM_REPO}:${TAG}
	docker push ${ADDON_CUSTOM_REPO}:${OSTAG}

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

