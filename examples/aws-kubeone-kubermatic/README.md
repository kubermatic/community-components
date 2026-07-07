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

1. Create the file `00-terraform/aws/terraform.tfvars` and specify your individual configuration in there, e.g.:
```
aws_region = "eu-central-1"
cluster_name = "johndoe-k1-kkp"
ssh_public_key_file = "~/.ssh/id_rsa.pub"
cluster_autoscaler_min_replicas = 1
cluster_autoscaler_max_replicas = 3
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

4. Configure your Email address to issue a Let's Encrypt TLS certificate
Copy `.env.example` to `.env` and fill in your Email address.

5. Generate the configuration files (if not exist):
```sh
make kkp-values
```
Optionally you can change the generated admin password within the `20-kkp/password` file afterwards.

6. Install KKP master and seed components into the KubeOne Kubernetes cluster:
```sh
make kkp-apply
```
Once DNS has propagated (can take a few minutes), you can browse the KKP dashboard at `https://{cluster_name}.lab.kubermatic.io`.

7. Install the Monitoring & Logging (MLA) stack:
```sh
make kkp-apply-seed-mla kkp-apply-usercluster-mla
```

8. Browse and log into KKP
Print the KKP URL and credentials:
```sh
make kkp-login-info
```

When creating AWS-based user clusters via the KKP Dashboard, please check the "Assign Public IP" checkbox within the 4th step ("Initial Nodes") of the user cluster creation wizard.
Otherwise machines won't join the cluster as nodes.

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
