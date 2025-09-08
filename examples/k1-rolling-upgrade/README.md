# K1 Rolling Upgrade

This script, `rolling-upgrade.sh`, is an example to demonstrate how to upgrade the control plane nodes of a KubeOne cluster, in a rolling upgrade fashion.

**NOTE: This script is only tested with OpenStack. For other cloud providers, you need to update the script accordingly.**

## Prerequisites

- A KubeOne cluster
- A machine with the KubeOne CLI installed

## Usage

1. Update the following variables in the script based on your file structure:

```bash
export KUBECONFIG="${GIT_ROOT}/kubeconfig"
TERRAFORM_DIR="${GIT_ROOT}/examples/terraform/${CLOUD_PROVIDER}"
CONFIG_DIR="${GIT_ROOT}/examples/terraform/${CLOUD_PROVIDER}/${CLUSTER_NAME}"
```

2. Run the script:

```bash
./rolling-upgrade.sh <cluster-name>
```
