## See https://github.com/kubermatic/kubeone/releases
KUBEONE_VERSION ?= 1.13.6
BASE_TAG ?= ${KUBEONE_VERSION}
BASE_IMAGE = quay.io/kubermatic-labs/kubeone-tooling
# https://github.com/kubermatic/kubermatic-virtualization/releases
KUBEV_VERSION ?= v1.2.0-patch
# https://github.com/kubermatic/kubermatic/releases
KKP_VERSION ?= v2.30.6

DOCKER_REPO ?= quay.io/kubermatic/kubermatic-virtualization-tooling
DOCKER_EXTRA_FLAG ?=
DOCKER_BUILD_EXTRA_FLAG ?=
CONTAINER_NAME ?= kubev-${KUBEV_VERSION}

# Credentials for kubermatic-ee-downloader (request from sales@kubermatic.com).
# The file is sourced as a shell .env (supports quotes / comments / export):
#   KUBEV_USERNAME=<your-username>
#   KUBEV_PASSWORD=<your-password>
# See: https://docs.kubermatic.com/kubermatic-virtualization/v1.1.0/getting-kubermatic-virtualization/
# Optional: if this file is absent, docker-build runs without the download
# credentials (use when already logged in or building from a local binary).
KUBEV_ENV_FILE ?= .local/kubev.crypt.env

FINAL_TAG ?= kubev-${KUBEV_VERSION}_kkp-${KKP_VERSION}
TAG_DATE ?= ${FINAL_TAG}-$(shell date -I)
PLATFORM ?= linux/amd64
# Derived from PLATFORM (linux/amd64 -> linux-amd64); used for kubermatic-installer download URL.
BIN_ARCH ?= $(subst /,-,${PLATFORM})

.PHONY: docker-release docker-build

docker-build:
	@KUBEV_SECRETS=""; \
	if [ -f ${KUBEV_ENV_FILE} ]; then \
		echo "Using kubev credentials from ${KUBEV_ENV_FILE}"; \
		set -a; . ./${KUBEV_ENV_FILE}; set +a; \
		KUBEV_SECRETS="--secret id=kubev_username,env=KUBEV_USERNAME --secret id=kubev_password,env=KUBEV_PASSWORD"; \
	else \
		echo "NOTE: ${KUBEV_ENV_FILE} not found - building without kubev credentials (assuming already logged in or using a local binary)"; \
	fi; \
	docker buildx build --platform ${PLATFORM} --pull --load ${DOCKER_BUILD_EXTRA_FLAG} \
		$${KUBEV_SECRETS} \
		--build-arg BASE_TAG=${BASE_TAG} \
		--build-arg BASE_IMAGE=${BASE_IMAGE} \
		--build-arg BIN_ARCH=${BIN_ARCH} \
		--build-arg KUBEV_VERSION=${KUBEV_VERSION} \
		--build-arg KKP_VERSION=${KKP_VERSION} \
		-t ${DOCKER_REPO}:${TAG_DATE} .

docker-build-local-kubev-bin: build-kubev
	DOCKER_BUILD_EXTRA_FLAG='--file local-kubev.Dockerfile' make docker-build

docker-run-local: docker-build
	docker run --platform ${PLATFORM} -it --rm --name ${CONTAINER_NAME} ${DOCKER_EXTRA_FLAG} \
	 	-v $(shell pwd)/../:/home/kubermatic/mnt ${DOCKER_REPO}:${TAG_DATE} bash
docker-run-local-root: docker-build
	docker run --platform ${PLATFORM} -it --user 0 --rm --name ${CONTAINER_NAME} ${DOCKER_EXTRA_FLAG} \
		-v $(shell pwd)/../:/home/kubermatic/mnt ${DOCKER_REPO}:${TAG_DATE} bash

docker-build-and-run-local-root: docker-build-local-kubev-bin
	docker run --platform ${PLATFORM} -it --user 0 --rm --name ${CONTAINER_NAME} ${DOCKER_EXTRA_FLAG} \
		-v $(shell pwd)/../:/home/kubermatic/mnt ${DOCKER_REPO}:${TAG_DATE} bash

docker-run:
	docker pull --platform ${PLATFORM} ${DOCKER_REPO}:latest
	docker run --platform ${PLATFORM} -it --rm --name ${CONTAINER_NAME} ${DOCKER_EXTRA_FLAG} \
		-v $(shell pwd)/../:/home/kubermatic/mnt ${DOCKER_REPO}:latest bash
docker-run-root:
	docker pull --platform ${PLATFORM} ${DOCKER_REPO}:latest
	docker run --platform ${PLATFORM} -it --user 0 --rm --name ${CONTAINER_NAME} ${DOCKER_EXTRA_FLAG} \
		-v $(shell pwd)/../:/home/kubermatic/mnt ${DOCKER_REPO}:latest bash

docker-clean:
	docker rm -f ${CONTAINER_NAME}

# update latest, version ref and set unique tag
docker-release: docker-build
	docker tag ${DOCKER_REPO}:${TAG_DATE} ${DOCKER_REPO}:${FINAL_TAG}
	docker push ${DOCKER_REPO}:${FINAL_TAG}
	docker push ${DOCKER_REPO}:${TAG_DATE}

docker-release-local-build: docker-build-local-kubev-bin
	docker tag ${DOCKER_REPO}:${TAG_DATE} ${DOCKER_REPO}:${FINAL_TAG}
	docker push ${DOCKER_REPO}:${FINAL_TAG}
	docker push ${DOCKER_REPO}:${TAG_DATE}


docker-release-latest: docker-release
	docker tag ${DOCKER_REPO}:${TAG_DATE} ${DOCKER_REPO}:latest
	docker push ${DOCKER_REPO}:latest

build-kubev:
	rm -rf ./git-submodules/kubermatic-virtualization/bin .local/bin
	cd ./git-submodules/kubermatic-virtualization \
		&& make kubermatic-virtualization
	mkdir -p .local && mv ./git-submodules/kubermatic-virtualization/bin/ .local/