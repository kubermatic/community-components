# Kubeone AWS EKS-D Example

As an AWS partner, we are proud that our open source cluster lifecycle management tool Kubermatic KubeOne is part of 
the first batch of distributions to offer out-of-the-box support for Amazon EKS Distro. Thanks to Kubermatic KubeOne’s 
Terraform integration and ease of use, users can install EKS Distro on AWS and Amazon Linux 2 with minimal operational 
effort.  
 
## Setup

### Service Account
We need a Service Account in AWS to use KubeOne, you can find the policy you need for Demo purpose in the `policy.json`
file.

### Credentials & configuration
First you have to fill your AWS service credentials in the `credentials.yaml` and the `aws_credentials.sh` file. 
You will find these in the `credentials` folder.

The Terraform variables can be found in the `tf-infra` folder. 
The configuration in the terraform.tfvars is completed for this cluster.

#### Installation

We can use the Makefile in the main folder to do all the installation

First we create the infrastructure:

```
make k1-tf-apply
```

Now we run the KubeOne installer

```
make k1-apply
```
And you are done!
Have Phun!

## Teardown

To remove everything just run
```
make k1-tf-destroy
```