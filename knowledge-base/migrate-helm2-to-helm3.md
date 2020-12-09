# How to migrate Helm releases from Helm2 to Helm 3

This document shows you how to migrate Heml releases from using Helm version 2.x with Tiller to being managed by Helm version 3.x in place.

## Prerequisites

- having Helm version 3.x installed locally (all calls to `helm` in this tutorial assume that it's using Helm version 3.x)
- having access to the Kubernetes cluster where you want to migrate Helm releases to use Helm3
- Know the Tiller namespace that Helm version 2.x uses (this tutorial will use the namespace `kubermatic` for this)

## Pre-migration steps

### Use Helm version 2.x to get list of releases

Just to not forget any installed Helm releases we want to migrate let's get a list of them:

```bash
helm2 list > releases.txt
```

### Install Helm 2to3 plugin

This plugin will do all the migration work for you. For installing it execute the following steps:

```bash
helm plugin install https://github.com/helm/helm-2to3
```

## Migration

The Helm 2to3 plugin has 3 major subcommands (`move config`, `convert`, `cleanup`).

### Migrate your local config (optional)

With the following commands `helm 2to3` will migrate your local Helm version 2.x config to Helm version 3.x config including plugins.

```bash
# show all the changes that are about to happen
helm3 2to3 move config --dry-run

# and then execute the changes
helm3 2to3 move config
```

### Convert Helm releases to being managed by Helm3

First get your list of all the installed Helm releases:

```bash
cat releases.txt
```

Then for each release execute the following steps:

```bash
# This will again show all the changes being made for the s3-exporter release
helm3 2to3 convert s3-exporter --dry-run --tiler-ns kubermaitc --delete-v2-releases

# Execute the changes
helm3 2to3 convert s3-exporter --tiler-ns kubermatic --delete-v2-releases
```

This will convert the Helm2 release custom resources to the Helm3 specific ones and changes the OwnerReferences of all managed resource to the newly created custom resources. After migration this will automatically delete the Helm2 release custom resources.

### Cleanup old CRDs and Tiller

To delete old Helm2 CRDs and the Tiller deployment run the following step:

```bash
helm3 2to3 cleanup --tiller-ns kubermatic
```

