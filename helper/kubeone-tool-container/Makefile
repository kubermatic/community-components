
## See https://github.com/kubermatic/kubermatic-installer/releases
KUBEONE_VERSION ?= 1.2.0-beta.0
DOCKER_REPO ?= 'quay.io/kubermatic-labs/kubeone-tooling'
FINAL_TAG ?= kubeone-${KUBEONE_VERSION}
TAG_DATE ?= kubeone-${KUBEONE_VERSION}-$(shell date -I)

.PHONY: docker-release docker-build

docker-build:
	docker build --build-arg kubeone_version=${KUBEONE_VERSION} -t ${DOCKER_REPO}:${TAG_DATE} .

docker-run-local: docker-build
	docker run -it -v $(shell pwd):/home/kubermatic/mnt ${DOCKER_REPO}:${TAG_DATE} bash

docker-release: docker-build
	docker tag ${DOCKER_REPO}:${TAG_DATE} ${DOCKER_REPO}:${FINAL_TAG}
	docker tag ${DOCKER_REPO}:${TAG_DATE} ${DOCKER_REPO}:latest
	docker push ${DOCKER_REPO}:${TAG_DATE}
	docker push ${DOCKER_REPO}:${FINAL_TAG}
	docker push ${DOCKER_REPO}:latest
