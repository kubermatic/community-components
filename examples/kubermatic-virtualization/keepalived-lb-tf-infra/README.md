# Keepalived Load Balancer for KubeV Control Plane

This Terraform module deploys keepalived on KubeV control plane nodes to provide a Virtual IP (VIP) for Kubernetes API high availability.

## Overview

Keepalived uses VRRP (Virtual Router Redundancy Protocol) to manage a floating Virtual IP address across multiple control plane nodes. When the master node fails, the VIP automatically moves to a backup node, ensuring continuous API server availability.

## Use Cases

This module is recommended for:
- **On-premise / bare-metal deployments** where cloud load balancers are not available
- **VMware vSphere** environments
- **Private data centers** with direct L2 network connectivity

> **Note**: For GCP test deployments, use the [GCP Internal Load Balancer](../../infra-machines/gce/README.md) instead, as keepalived VIPs are not easily accessible from outside the VPC and GCP does not support multicast.

## Prerequisites

- Control plane nodes must be provisioned and accessible via SSH
- All control plane nodes must be on the same L2 network segment
- The VIP address must be unused and within the same subnet as control plane nodes
- SSH key-based authentication configured

## Usage

### 1. Create terraform.tfvars

```hcl
cluster_name = "kubev-cluster"

# Virtual IP for the Kubernetes API
api_vip = "10.0.2.100"

# Control plane node IPs
control_plane_hosts = [
  "10.0.2.10",
  "10.0.2.11",
  "10.0.2.12"
]

# SSH configuration
ssh_username         = "ubuntu"
ssh_private_key_file = "~/.ssh/id_rsa"

# Network interface for VRRP (check with: ip link show)
vrrp_interface = "ens192"

# VRRP router ID (must be unique in your network, 1-255)
vrrp_router_id = 42

# Optional: Bastion host for SSH jump
# bastion_host     = "bastion.example.com"
# bastion_port     = 22
# bastion_username = "ubuntu"
```

### 2. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

### 3. Verify Installation

SSH into any control plane node and check:

```bash
# Check keepalived status
sudo systemctl status keepalived

# Check which node holds the VIP
ip addr show | grep <VIP>

# Test API server via VIP
curl -k https://<VIP>:6443/healthz
```

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|:--------:|
| `cluster_name` | Name of the cluster | - | yes |
| `api_vip` | Virtual IP address for Kubernetes API | - | yes |
| `control_plane_hosts` | List of control plane node IPs | - | yes |
| `ssh_username` | SSH user for provisioning | `root` | no |
| `ssh_private_key_file` | Path to SSH private key | - | yes |
| `vrrp_interface` | Network interface for VRRP | `ens192` | no |
| `vrrp_router_id` | VRRP router ID (1-255, must be unique) | `42` | no |
| `bastion_host` | SSH bastion/jump host | `""` | no |
| `bastion_port` | SSH bastion port | `22` | no |
| `bastion_username` | SSH bastion user | `""` | no |

## Outputs

| Output | Description |
|--------|-------------|
| `kubev_api` | API endpoint configuration with VIP |
| `kubev_hosts` | Control plane host information |

## How It Works

1. **Installation**: The module installs keepalived on all control plane nodes
2. **Configuration**: Each node is configured with VRRP:
   - First node becomes MASTER (priority 101)
   - Other nodes become BACKUP (priority 100)
3. **Health Check**: A script checks the local API server every 3 seconds
4. **Failover**: If the master fails the health check, the VIP moves to a backup node

## Architecture

```
                    ┌─────────────────┐
                    │   VIP: api_vip  │
                    │   (Floating IP) │
                    └────────┬────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
           ▼                 ▼                 ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │   CP Node 1  │  │   CP Node 2  │  │   CP Node 3  │
    │   (MASTER)   │  │   (BACKUP)   │  │   (BACKUP)   │
    │  Priority:101│  │  Priority:100│  │  Priority:100│
    │  kube-api:6443│  │  kube-api:6443│  │  kube-api:6443│
    └──────────────┘  └──────────────┘  └──────────────┘
```

## Troubleshooting

### Check keepalived logs
```bash
sudo journalctl -u keepalived -f
```

### Verify VRRP communication
```bash
sudo tcpdump -i <interface> vrrp
```

### Manual failover test
```bash
# On master node, stop keepalived
sudo systemctl stop keepalived

# Check VIP moved to another node
ip addr show | grep <VIP>
```

### Common issues

1. **VIP not assigned**: Check firewall allows VRRP protocol (IP protocol 112)
2. **Split-brain**: Ensure all nodes can communicate via VRRP
3. **Health check failing**: Verify API server is running on localhost:6443

## Integration with KubeV

When using this module with KubeV, configure the cluster to use the VIP as the API endpoint:

```yaml
# kubev.yaml
apiVersion: kubermatic.k8c.io/v1
kind: KubevCluster
spec:
  controlPlaneEndpoint:
    host: "<api_vip>"
    port: 6443
```