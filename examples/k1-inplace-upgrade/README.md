# K1 Rolling Upgrade

This script, `inplace-upgrade.sh`, is an example to demonstrate how to upgrade the control plane nodes of a KubeOne cluster, in the form of an in-place upgrade.

**NOTE: This script is only tested with vSphere. For other cloud providers, you need to update the script accordingly.**

## Prerequisites

- A KubeOne cluster

## Usage

1. Update the following variables in the script based on your file structure:

```bash
export KUBECONFIG="${GIT_ROOT}/kubeconfig"
```

2. Run the script:

```bash
./inplace-upgrade.sh
```
