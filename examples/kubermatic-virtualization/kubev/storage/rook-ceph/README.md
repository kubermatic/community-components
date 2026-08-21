# Rook Ceph Storage for KubeVirt

Rook Ceph v1.19 provides distributed storage for Kubernetes using Ceph.

**Reference:** https://rook.io/docs/rook/v1.19

## Quick Start

```bash
# Ensure /dev/sdb is clean on all nodes
wipefs -a /dev/sdb
sgdisk --zap-all /dev/sdb

# Deploy Rook operator and Ceph cluster
helmfile sync
```

## Kernel Requirements

| Feature | Minimum Kernel | Your Kernel (6.14.0) |
|---------|----------------|----------------------|
| RBD (Block Storage) | 4.5+ | ✓ |
| CephFS (Filesystem) | 4.17+ | ✓ |
| RBD Encryption | 5.4+ | ✓ |

## Prerequisites

1. **Block Device**: Each node requires `/dev/sdb` (raw, no filesystem)
   ```bash
   wipefs -a /dev/sdb
   sgdisk --zap-all /dev/sdb
   ```

2. **Kernel Modules** (configured in cloud-init):
   ```bash
   modprobe rbd
   modprobe ceph
   ```

3. **LVM2** (configured in cloud-init):
   ```bash
   apt-get install -y lvm2
   ```

## Storage Classes

| StorageClass | Type | Default | Use Case |
|--------------|------|---------|----------|
| `kubev-main` | RBD | Yes | General purpose, stateful apps |
| `kubev-vms` | RBD | No | KubeVirt VMs with live migration support |

### Usage Example

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  # storageClassName: kubev-main  # Optional, it's the default
  resources:
    requests:
      storage: 10Gi
```

### KubeVirt VM Disk

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: vm-disk
spec:
  accessModes:
    - ReadWriteMany  # Enables live migration
  volumeMode: Block
  storageClassName: kubev-vms
  resources:
    requests:
      storage: 20Gi
```

## Monitoring

```bash
# Check cluster status
kubectl -n rook-ceph get cephcluster

# Watch pods
kubectl -n rook-ceph get pods -w

# Deploy toolbox for Ceph CLI
kubectl -n rook-ceph apply -f https://raw.githubusercontent.com/rook/rook/v1.19.0/deploy/examples/toolbox.yaml

# Access Ceph CLI
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph status
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd status
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph df
```

## Dashboard

Access the Ceph dashboard:

```bash
# Port forward
kubectl -n rook-ceph port-forward svc/rook-ceph-mgr-dashboard 8443:8443

# Get admin password
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 -d
```

Open https://localhost:8443 (user: `admin`)

## Troubleshooting

### OSD not starting

```bash
# Check if device has existing data
lsblk -f /dev/sdb

# Wipe device
wipefs -a /dev/sdb
sgdisk --zap-all /dev/sdb
dd if=/dev/zero of=/dev/sdb bs=1M count=100
```

### CSI driver issues

```bash
# Check CSI pods
kubectl -n rook-ceph get pods -l app=csi-rbdplugin
kubectl -n rook-ceph get pods -l app=csi-rbdplugin-provisioner

# Check logs
kubectl -n rook-ceph logs -l app=csi-rbdplugin -c csi-rbdplugin
```

### Kernel modules

```bash
lsmod | grep -E 'rbd|ceph'
# If missing:
modprobe rbd
modprobe ceph
```

## Uninstallation

```bash
# Remove storage classes and cluster
kubectl delete -f storage/rook-ceph/ceph-storageclass.yaml
kubectl delete -f storage/rook-ceph/ceph-cluster.yaml

# Wait for cleanup
kubectl -n rook-ceph get cephcluster

# Remove operator
helmfile destroy

# Clean up on each node (run as root)
rm -rf /var/lib/rook
wipefs -a /dev/sdb
sgdisk --zap-all /dev/sdb
```