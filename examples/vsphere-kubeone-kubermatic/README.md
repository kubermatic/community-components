# An example config for setting up Kubermatic on vSphere with KubeOne

## Requirements

in the KubeOne folder you will find all the things you need for running KubeOne. 

Before getting started, make sure that you’ve the following prerequisites satisfied:

- [Installed KubeOne](https://docs.kubermatic.com/kubeone/master/getting_kubeone/) 
- Installed [Terraform v0.12+](https://learn.hashicorp.com/terraform/getting-started/install.html)
- vSphere Credentials
- An SSH key and the ssh-agent configured as described in the [KubeOne](https://docs.kubermatic.com/kubeone/master/prerequisites/ssh/) documentation
- [Helm (version 3)](https://www.helm.sh/)
- [Kubermatic Installer](https://docs.kubermatic.com/kubermatic/master/installation/install_kubermatic/)

## Setting up the Seed cluster with KubeOne

In the KubeOne folder you will find all the information to install your seed cluster with KubeOne and Terraform, it is required to fill in some information.

### Credentials 

Please complete your credential and network details in the following files
```
KubeOne/vsphere.credentials
KubeOne/kubeone.yaml
KubeOne/tf-infra/terraform.tfvars

```
Also please generate a secret for the [metallb](https://metallb.universe.tf/installation/) `` KubeOne/addons/11_metallb-secret.yaml`` and 
define your ip range in `` KubeOne/addons/13_metallb-config.yaml``

### Run installation
You can now run the installation easily from the KubeOne folder with the following commands.

Create the machines with the help of Terraform
```
make k1-tf-apply
```

Install the Cluster with the help of KubeOne
```
make k1-apply
```

When this is finished you will receive a KUBECONFIG you can now use to connect to your cluster.

## Installing Kubermatic

The next step is to run the Kubermatic installer.

### Credentials

Here we also need to enrich some config files with credentials.
Also we need a certificate for your domain as well. You can use a wide range of certificates for this, from selfsigned to pre created or even letsencryp certificates

In this example we use the way of a self signed certificate that is created with [easy-rsa](https://github.com/OpenVPN/easy-rsa).

Complete the configuration of the following files:
``` 
Kubermatic/setup/values.yaml
Kubermatic/setup/kubermatic.operator.config.yaml
Kubermatic/setup/settings/00_kubermaticsettings.yaml
Kubermatic/setup/settings/11_seed-cluster.yaml
Kubermatic/setup/settings/20_presets.yaml
```

Also add your ca to the ``Kubermatic/setup/secret.ca.yaml``

### Installation

Now you cann just run 

``` 
export KUBECONFIG=./PATH/TO/KUBECONFIG/GENERATEDBY/KUBEONE 
PATH/TO/KUBERMATIC/INSTALLLER/kubermatic-installer deploy --config Kubermatic/setup/kubermatic.operator.config.yaml --helm-values Kubermatic/setup/values.yaml
```

Follow the instructions of the Kubermatic installer and create the configs and secrets by running the following.

``` 
kubectl create -f Kubermatic/setup/secret.ca.yaml
kubectl create -f Kubermatic/setup/certmanager.issuer.yaml
kubectl create -f Kubermatic/setup/settings
```
And you are finished
