# Baremetal node provisioning with OSM

This method allows you to provision a baremetal machine as a Kubernetes node, using the provisioning logic of OSM as provided by the specific OSP.  

The approach is currently a bit hacky. We are creating a machine-deployment with provider GCE, but with a bogus config, so nothing is actually provisioned on GCE. This machine-deployment though forces Machine-Controller to create suitable OSM configuration, which we then download and use for provisioning on the baremetal machine.

## Requirements
* A local Linux machine
  * [yq installed](https://github.com/mikefarah/yq/#install) on it 
  * This repository checked out
* Access to the remote machine
  * SSH access to the remote machine
  * or password access and a ssh key pair available
* A KKP user-cluster 
  * When you create a new user-cluster, choose the KubeAdm provider

## Install OS onto remote machine

The nodes need to be prepared with a fresh installation of your OS.
[Ubuntu Server 22.04.2](https://releases.ubuntu.com/22.04.2/ubuntu-22.04.2-live-server-amd64.iso) was used for this example.

## Tweak OSP
Have a look at the provided OSP for Ubuntu under [./manifests/01_osp-ubuntu-edge.yaml](./manifests/01_osp-ubuntu-edge.yaml) to check for specific changes necessary in this context. 
Most notably, updating the hostname was turned off, as this caused Ubuntu's network config to break. So make sure your machine has a suitable hostname during installation.

If you need a different OSP, grab one of [the default ones](https://github.com/kubermatic/operating-system-manager/tree/main/deploy/osps/default), store it under [./manifests/](./manifests/) and adapt for your needs.  
Then make sure [02_machinedeployment.yaml](./manifests/02_machinedeployment.yaml) references the correct OSP.

## Add SSH public key to PC

The following provision script will be executed on your local machine and needs ssh-access to the remote machine. If not already done, please [add your public ssh key](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04) to the remote machine.

## Ensure access to user-cluster

0. Create user-cluster using the KubeAdm provider.  

1. Download the kubeconfig file from KKP. If using the UI, there is a green "Get Kubeconfig" button top-right. If using the API, go to https://\<kkp-domain\>/api/v2/projects/\<project-id\>/clusters/\<cluster-id\>/kubeconfig.

2. Set the following env var
```
$ export KUBECONFIG=$(pwd)/kubeconfig-admin-xyz
```

## Run provisioning script

Now we are ready to execute the provisioning script. 
```
$ make bootstrap
```

It will ask you for the IP and username of the remote machine. 

First, it downloads the provisioning steps (as cloud-init file) from KKP.
Then, it uploads this cloud-init file, alongside a remote-provisioning script to the remote machine.
After that's done, the remote-provisioning script gets executed remotely via ssh. It does not much more than running `cloud-init --file <cloud-init file> init`.

At the final stage, kubectl is used to approve pending certificate requests (the certs used for secure communication between the Kubelet and the Kubernetes API). 


## Check cluster nodes

After a short while the new node should appear.

```
$ kubectl get nodes
```
