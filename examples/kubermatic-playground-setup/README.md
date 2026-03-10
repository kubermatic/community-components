# KubeOne & KKP setup

A bunch of scripts to set up a [KubeOne](https://kubeone.io) cluster on AWS and install KKP into it.
This is meant for Kubermatic-internal development/testing purposes primarily.
(For external usage you'd have to provide your AWS credentials differently.)

It implements the KubeOne cluster setup for AWS as documented [here](https://docs.kubermatic.com/kubeone/v1.12/tutorials/creating-clusters/).

## Prerequisites

The following CLI tools must be installed on your host:
* make
* AWS CLI
* Vault client CLI
* jq
* yq
* Terraform
* KubeOne
* kubectl
* helm

## Usage

### Setup

This section explains how to create/upgrade a Kubernetes cluster.
The process is idempotent so that you can repeat it whenever you change the configuration or want to upgrade your cluster.

1. Specify your individual Terraform configuration within `00-terraform/terraform.tfvars`, e.g.:
```
aws_region = "eu-central-1"
cluster_name = "johndoe-k1-kkp"
ssh_public_key_file = "~/.ssh/id_rsa.pub"
```
Please make sure to configure a `cluster_name` that is unique across the company by prefixing it with your name.

2. Create the basic AWS infrastructure (EC2 instances, load balancer etc) using Terraform:
```sh
make terraform-apply
```
In case the infrastructure cannot be created initially due to an IP conflict, destroy and recreate it (`make terraform-destroy terraform-apply`), allocating a new random CIDR block.

3. Use KubeOne to set up a Kubernetes control plane on the EC2 instances:
```sh
make kubeone-apply
```

4. Generate the configuration files (if not exist):
```sh
make kkp-values
```
Optionally you can change the generated admin password within the `20-kkp/password` file afterwards.

5. Install KKP master and seed components into the KubeOne Kubernetes cluster:
```sh
make kkp-apply
```
Once DNS has propagated (can take a few minutes), you can browse the KKP dashboard at `https://{cluster_name}.lab.kubermatic.io`.

6. Install the Monitoring & Logging (MLA) stack (not working yet):
```sh
make kkp-apply-seed-mla kkp-apply-usercluster-mla
```

### Destroying the cluster & infrastructure

1. Destroy all user clusters first (if you installed KKP previously):
```sh
make kkp-destroy-userclusters
```

2. Destroy the KubeOne Kubernetes cluster:
```sh
make kubeone-destroy
```

3. Destroy the AWS infrastructure:
```sh
make terraform-destroy
```
Please make sure to destroy the Kubernetes cluster gracefully prior to destroying the AWS infrastructure.
Otherwise EC2 instances and volumes may be left behind, requiring you to remove them manually.
