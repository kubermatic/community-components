export GOLDFLAGS=-s -w -extldflags '-zrelro -znow'
export GOFLAGS=-trimpath
export GITTAG=$(shell git describe --tags --always)
export IMAGE=changeme

.PHONY: dist/mapsecrets
dist/mapsecrets:
	export CGO_ENABLED=0
	go build -ldflags "$(GOLDFLAGS)" -o $@ ./cmd/mapsecrets

.PHONY: lint
lint:
	golangci-lint run ./...

.ONESHELL:
.PHONY: image
image: dist/mapsecrets
	container=$$(buildah from scratch)
	buildah copy $$container /etc/ssl/certs/DST_Root_CA_X3.pem /etc/ssl/certs/DST_Root_CA_X3.pem
	buildah copy $$container ./dist/mapsecrets /usr/local/bin/mapsecrets
	buildah config --entrypoint '["/usr/local/bin/mapsecrets"]' $$container
	buildah commit --format docker $$container $IMAGE
	buildah push $IMAGE
