
# Baremetal hosting

## SSH
user: `ubuntu`
machines: [`hosts.txt`](./hosts.txt)


## Nodes Provisioning

1. Setup Kubeadm Cluster at Kubermatic: https://example.kubermatic.com/
1. Download kubeconfig
1. Initial Nodes with same version as control plane
```
# USE same as control plane
./01_setup-install-multi-client-ssh.sh 1.18.10
```
1. Create kubeadm join token, with the [`kubeadm/Dockerfile`](kubeadm/Dockerfile)
```
docker build -t local/kubeadm --build-arg K8S_VERSION=1.18.10 .
docker run -it -v ~/Downloads/kubeconfig-admin-996rx7v7bb:/kubeconfig local/kubeadm  kubeadm token --kubeconfig kubeconfig create --print-join-command
```
1. Copy output of docker container `kubeadm join ... --token .. -discovery-token-ca-cert-hash ...` and execute join node script:
```
./02_setup-join-multi-client-ssh.sh ''
```

### For Demo
If needed the [`./tf-infra`](tf-infra) contains some code for create a few "simulated" VMs on vSphere.