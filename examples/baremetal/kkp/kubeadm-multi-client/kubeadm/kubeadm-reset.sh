#!/bin/bash
set -xeuo pipefail

kubeadm reset --force
rm -rf /etc/cni/net.d
rm -rf /etc/kube*
rm -rf $HOME/kube*
rm -f /var/lib/kubelet/config.yaml
rm -rf /var/lib/etcd #ATTENTION DELETES may existing ETCD data
if [ `which ipvsadm` ]; then
  ipvsadm --clear
fi
if [ `which crictl` ]; then
  crictl rm --all --force || echo "... cleanup"
fi
systemctl stop keepalived || echo "... cleanup"
systemctl disable keepalived || echo "... cleanup"
#reboot

# remove snap, exec 2 times
snap remove lxd
for i in $(snap list | awk '{print $1}'| grep -iv name); do snap remove $i; done
for i in $(snap list | awk '{print $1}'| grep -iv name); do snap remove $i; done

# Uncomment to allow downgrade from k8s 1.24.6 to 1.23.14
apt autoremove --purge -y --allow-change-held-packages kubeadm kubectl kubelet kubernetes-cni kube*
apt autoremove --purge -y --allow-change-held-packages containerd.io
apt autoremove --purge -y podman podman-docker docker-compose libvirt containernetworking-plugins openvswitch-switch drbd-utils zfsutils-linux snapd
# Uncomment to downgrade containerd to 1.6.12* to fix https://github.com/containerd/containerd/issues/7828 with current 1.6.13 release
# apt install -y --allow-downgrades --allow-change-held-packages containerd.io=1.6.12*

rm -rf /etc/zfs
rm -rf /var/lib/kubelet
#### on issues check if blocked by csi
# findmnt /var/lib/kubelet/pods/9b0a0ab4-cf3c-4a5b-93ee-a3854f7b7097/volumes/kubernetes.io~csi/pvc-f97ad01b-6bbd-44a1-b14e-8ff35550849b/mount
# lsof /var/lib/kubelet/pods/9b0a0ab4-cf3c-4a5b-93ee-a3854f7b7097/volumes/kubernetes.io~csi/pvc-f97ad01b-6bbd-44a1-b14e-8ff35550849b/mount
# for f in $(find /var/lib/kubelet/ -name mount); do chattr -i $f; done

rm -rf /var/lib/docker
rm -rf /var/lib/container*

#### DISK wipe of storage
wipefs -a /dev/sdb
wipefs -a /dev/sdc

apt autoremove && apt autoclean
apt update && apt dist-upgrade -y
