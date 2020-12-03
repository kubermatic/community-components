# Nvidia GPU operator installation

After a new k8s installation, the Nvidia GPU operator must be installed to run GPU tasks.
Visit the official repository to get more info about the operator: https://github.com/NVIDIA/gpu-operator/

## Prerequisites

- Nodes must not be pre-configured with NVIDIA components (driver, container runtime, device plugin).
- Node Feature Discovery (NFD) is required on each node. By default, NFD master and worker are automatically deployed.


## Installation

Note: Helm 3 should be already installed on the pharma console host, if it's not then please install it by executing the following script:
```
$ curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```
Add and update Nvidia repository
```
$ helm repo add nvidia https://nvidia.github.io/gpu-operator
$ helm repo update
```

Install the GPU operator
```
$ helm install nvidia-gpu-operator nvidia/gpu-operator --devel --wait
```

Deploy a test GPU job
Note: assigning a job to a worker node may take about 3 minutes
```
kubectl apply -f https://nvidia.github.io/gpu-operator/notebook-example.yml
kubectl get pod tf-notebook
```
