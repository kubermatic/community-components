## See https://github.com/kubermatic/kubeone/releases
UI_VERSION ?= 0.1.1

KUBEONE_VERSION ?= 1.8.3
### TODO transfer to kubermatic repo
DOCKER_REPO ?= 'quay.io/toschneck/kubermatic-dev-ui'
FINAL_TAG ?= ${UI_VERSION}
TAG_DATE ?= ${UI_VERSION}-$(shell date -I)
.PHONY: docker-release docker-build

DEP_DOCKER_REPO=quay.io/toschneck/kubermatic-dev-ui
DEP_FINAL_TAG=base-debian-xfce-vnc-k1-${KUBEONE_VERSION}
DEP_TAG_DATE=base-debian-xfce-vnc-k1-${KUBEONE_VERSION}-$(shell date -I)

docker-build-dep:
	cd ../kubeone-tool-container && \
 	KUBEONE_VERSION=${KUBEONE_VERSION} DOCKER_REPO=${DEP_DOCKER_REPO} FINAL_TAG=${DEP_FINAL_TAG} TAG_DATE=${DEP_TAG_DATE} CONTAINER_USER=headless CONTAINER_USER_HOME=/headless \
	BASE_IMAGE=consol/debian-xfce-vnc@sha256:108675d167724b9f0ecbda8464ff66c8fbe42ccd0eb5647c4f8fc8205a9c136d \
    make docker-build docker-release

docker-build: docker-build-dep
	docker build --pull --build-arg BASE_IMAGE=${DEP_DOCKER_REPO}:${DEP_TAG_DATE} -t ${DOCKER_REPO}:${TAG_DATE} .

docker-run-local: docker-build
	docker run -it --rm -p 6901:6901 -p 5901:5901 -v $(shell pwd):/headless/mnt ${DOCKER_REPO}:${TAG_DATE} bash
docker-run-local-root: docker-build
	docker run -it --user 0 --rm -p 6901:6901 -p 5901:5901 -v $(shell pwd):/headless/mnt ${DOCKER_REPO}:${TAG_DATE} bash

docker-run:
	docker run -it -v $(shell pwd):/headless/mnt ${DOCKER_REPO}:${UI_VERSION} bash
docker-run-root:
	docker run -it --user 0 -v $(shell pwd):/headless/mnt ${DOCKER_REPO}:${UI_VERSION} bash

# update latest, version ref and set unique tag
docker-release: docker-build
	docker tag ${DOCKER_REPO}:${TAG_DATE} ${DOCKER_REPO}:${FINAL_TAG}
	docker push ${DOCKER_REPO}:${FINAL_TAG}
	docker push ${DOCKER_REPO}:${TAG_DATE}

docker-release-latest: docker-release
	docker tag ${DOCKER_REPO}:${TAG_DATE} ${DOCKER_REPO}:latest
	docker push ${DOCKER_REPO}:latest
