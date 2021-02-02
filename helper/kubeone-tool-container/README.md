## kubeone-tool-container

a docker container based on the latest ubuntu with tools included to work with kubeOne and kubernetes

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
docker run  --name  kubeone-tool-container -p 22:22 -t -d kubeone-tool-container
#get IP address
sudo docker inspect -f "{{ .NetworkSettings.IPAddress }}" kubeone-tool-container
#conect into the container
ssh kubermatic@IP of previous command

```

You can optionally set a user password on container run for the kubermatic user:
``` 
docker run -e PASS=hallo --name  kubeone-tool-container -p 22:22  -t -d kubeone-tool-container
```