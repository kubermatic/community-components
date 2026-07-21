## See https://github.com/kubermatic/kubeone/releases
UI_VERSION ?= 0.2.0

KUBEONE_VERSION ?= 1.13.5
### TODO transfer to kubermatic repo
DOCKER_REPO ?= 'quay.io/toschneck/kubermatic-dev-ui'
FINAL_TAG ?= ${UI_VERSION}
TAG_DATE ?= ${UI_VERSION}-$(shell date -I)
PLATFORM ?= linux/amd64

.PHONY: docker-release docker-build

DEP_DOCKER_REPO=quay.io/toschneck/kubermatic-dev-ui
DEP_FINAL_TAG=base-debian-xfce-vnc-k1-${KUBEONE_VERSION}
DEP_TAG_DATE=base-debian-xfce-vnc-k1-${KUBEONE_VERSION}-$(shell date -I)
CONTAINER_USER_ID=1000

# based one https://github.com/ConSol/docker-headless-vnc-container/
docker-build-dep:
	cd ../kubeone-tool-container && \
		KUBEONE_VERSION=${KUBEONE_VERSION} DOCKER_REPO=${DEP_DOCKER_REPO} FINAL_TAG=${DEP_FINAL_TAG} TAG_DATE=${DEP_TAG_DATE} \
		CONTAINER_USER_ID=${CONTAINER_USER_ID}  CONTAINER_USER=headless CONTAINER_USER_HOME=/headless \
		BASE_IMAGE=consol/debian-xfce-vnc:v2.0.4 \
		make docker-build docker-release

docker-build: docker-build-dep
	docker buildx build --platform ${PLATFORM} --pull --load \
		--build-arg BASE_IMAGE=${DEP_DOCKER_REPO}:${DEP_TAG_DATE} \
		--build-arg USER_ID=${CONTAINER_USER_ID} \
		-t ${DOCKER_REPO}:${TAG_DATE} .

docker-run-local: docker-build
	docker run -it --rm -p 6901:6901 -p 5901:5901 -v $(shell pwd):/headless/mnt ${DOCKER_REPO}:${TAG_DATE} bash
docker-run-local-root: docker-build
	docker run -it --user 0 --rm -p 6901:6901 -p 5901:5901 -v $(shell pwd):/headless/mnt ${DOCKER_REPO}:${TAG_DATE} bash

docker-run:
	docker run -it --rm -p 6901:6901 -p 5901:5901 -v $(shell pwd):/headless/mnt ${DOCKER_REPO}:latest bash
docker-run-root:
	docker run -it --user 0 --rm -p 6901:6901 -p 5901:5901 -v $(shell pwd):/headless/mnt ${DOCKER_REPO}:${UI_VERSION} bash

# update latest, version ref and set unique tag
docker-release: docker-build
	docker tag ${DOCKER_REPO}:${TAG_DATE} ${DOCKER_REPO}:${FINAL_TAG}
	docker push ${DOCKER_REPO}:${FINAL_TAG}
	docker push ${DOCKER_REPO}:${TAG_DATE}

docker-release-latest: docker-release
	docker tag ${DOCKER_REPO}:${TAG_DATE} ${DOCKER_REPO}:latest
	docker push ${DOCKER_REPO}:latest
