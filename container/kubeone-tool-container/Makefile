## See https://github.com/kubermatic/kubeone/releases
KUBEONE_VERSION ?= 1.8.3
DOCKER_REPO ?= 'quay.io/kubermatic-labs/kubeone-tooling'
FINAL_TAG ?= ${KUBEONE_VERSION}
TAG_DATE ?= ${KUBEONE_VERSION}-$(shell date -I)
BASE_IMAGE ?= amd64/ubuntu:22.04
CONTAINER_USER ?= kubermatic
CONTAINER_USER_HOME ?= /home/kubermatic
.PHONY: docker-release docker-build

docker-build:
	docker build --pull --build-arg BASE_IMAGE=${BASE_IMAGE} --build-arg kubeone_version=${KUBEONE_VERSION} --build-arg USER=${CONTAINER_USER} --build-arg USER_HOME=${CONTAINER_USER_HOME} -t ${DOCKER_REPO}:${TAG_DATE} .

docker-run-local: docker-build
	docker run -it -v $(shell pwd):/home/kubermatic/mnt ${DOCKER_REPO}:${TAG_DATE} bash
docker-run-local-root: docker-build
	docker run -it --user 0 -v $(shell pwd):/home/kubermatic/mnt ${DOCKER_REPO}:${TAG_DATE} bash

docker-run:
	docker run -it -v $(shell pwd):/home/kubermatic/mnt ${DOCKER_REPO}:${KUBEONE_VERSION} bash
docker-run-root:
	docker run -it --user 0 -v $(shell pwd):/home/kubermatic/mnt ${DOCKER_REPO}:${KUBEONE_VERSION} bash

# update latest, version ref and set unique tag
docker-release: docker-build
	docker tag ${DOCKER_REPO}:${TAG_DATE} ${DOCKER_REPO}:${FINAL_TAG}
	docker push ${DOCKER_REPO}:${FINAL_TAG}
	docker push ${DOCKER_REPO}:${TAG_DATE}

docker-release-latest: docker-release
	docker tag ${DOCKER_REPO}:${TAG_DATE} ${DOCKER_REPO}:latest
	docker push ${DOCKER_REPO}:latest
#https://github.com/derailed/k9s/releases/download/v0.24.10/k9s_v0.24.10_Linux_arm64.tar.gz
