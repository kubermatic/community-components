## kubeone-tool-container

a docker container based on [golang:1.15](https://hub.docker.com/_/golang) with tools included to work with kubeOne and kuberntes

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

### usage:

```
docker build -t kubeone-tool-container .
docker run  --name  kubeone-tool-container -t -d kubeone-tool-container
docker exec -it kubeone-tool-container /bin/bash
```

Image is currently NOT updated automatically at [quay.io > kubermatic-labs > kubeone-tooling](https://quay.io/repository/kubermatic-labs/kubeone-tooling?tab=tags), but you find the latest version at:
```
docker run --name  kubeone-tool-container -it quay.io/kubermatic-labs/kubeone-tooling
```