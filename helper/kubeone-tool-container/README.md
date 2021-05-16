## kubeone-tool-container

a docker container based on the latest ubuntu with tools included to work with kubeOne and kubernetes:

Docker Image:`quay.io/kubermatic-labs/kubeone-tooling`

### included packages:

- [terraform](https://www.terraform.io/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)
- [jq](https://stedolan.github.io/jq/)
- [yq](https://mikefarah.gitbook.io/yq/)
- [KubeOne](https://docs.kubermatic.com/kubeone)
- [AWS CLI 2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest)
- [GCloud SDK](https://cloud.google.com/sdk/docs)
- [fubectl](https://github.com/kubermatic/fubectl)
- [govc](https://github.com/vmware/govmomi/tree/master/govc)

### Makefile usage:

For local usage you could simply execute:
```bash
### use the pre-build quay.io images
make docker-run
make docker-run-root

### build and run images locally
make docker-run-local
make docker-run-local-root
```

### Manual Usage
To build and run the images you can:
```
docker build -t local/kubeone-tool-container .
```
To temporary run the container:
```
docker run -v $(shell pwd):/home/kubermatic/mnt -it local/kubeone-tool-container
```
To run the container and "keep it running":
```
docker run  --name  kubeone-tool-container -v $(shell pwd):/home/kubermatic/mnt -t -d local/kubeone-tool-container
docker exec -it kubeone-tool-container
```

## Note
For projects, you can modify the mount command and e.g. mount your project directory:
```
docker run  --name  kubeone-tool-container -v /path/to/project:/home/kubermatic/mnt -t -d quay.io/kubermatic-labs/kubeone-tooling
docker exec -it kubeone-tool-container
```

Image is currently NOT updated automatically at [quay.io > kubermatic-labs > kubeone-tooling](https://quay.io/repository/kubermatic-labs/kubeone-tooling?tab=tags), but you find the latest version at: `quay.io/kubermatic-labs/kubeone-tooling`
```
make docker-release
```