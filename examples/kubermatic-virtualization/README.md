# KubeV Cluster Setup

This directory contains an example `Justfile` for managing a Kubermatic Virtualization (KubeV) cluster (example: `kubev`).

## Requirements

Before starting, verify your infrastructure meets the hardware and software requirements:
- [KubeV Requirements](https://docs.kubermatic.com/kubermatic-virtualization/main/architecture/requirements/)

## Prepare Configuration

### Print Full Config Template

Generate a full example configuration to understand all available options:

```bash
kubermatic-virtualization config print --full
```

See [Declarative Installation Docs](https://docs.kubermatic.com/kubermatic-virtualization/main/installation/declarative-installation/) for details.

Edit your cluster config at `kubev/kubev.yaml`.

### Interactive Installation (alternative)

Alternatively, use the interactive installer to generate a config:

```bash
kubermatic-virtualization install
```

See [Interactive Installation Docs](https://docs.kubermatic.com/kubermatic-virtualization/main/installation/interactive-installation/).

## Setup Steps

### 1. Start Local KubeV Tooling Container

```bash
just local-kubev-tooling-start
```

Re-attach to a running container:

```bash
just local-kubev-tooling-exec
```

Remove the container:

```bash
just local-kubev-tooling-rm
```

### 2. Load SSH Key & Environment

```bash
just load-env
```

### 3. Provision Load Balancer (Terraform)

```bash
just kubev-lb-tf-init
just kubev-lb-tf-apply
just kubev-lb-output
```

### 4. Apply KubeV Cluster

Runs `kubermatic-virtualization apply`, copies the kubeconfig, untaints control-plane nodes, and syncs Helm releases:

```bash
just kubev-apply
```

Individual steps:

```bash
just untaint-cp-nodes       # remove control-plane taints
just kubev-apply-services   # helmfile sync
```

## Key Files

| Path | Description |
|---|---|
| `kubev/kubev.yaml` | KubeV cluster configuration |
| `kubev/kubev-kubeconfig.crypt.yaml` | Encrypted kubeconfig (written after apply) |
| `../00_config-generator/.env` | Environment variables (Docker registry, tags, etc.) |
| `../git-submodules/secrets/ssh/id_rsa` | SSH key for cluster access |