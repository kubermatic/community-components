#!/bin/bash
set -xeuo pipefail

kubeadm reset --force
rm -rf /etc/cni/net.d
rm -rf /etc/kube*
rm -rf $HOME/kube*
rm -f /var/lib/kubelet/config.yaml
rm -rf /var/lib/etcd
if [ `which ipvsadm` ]; then
  ipvsadm --clear
fi
if [ `which crictl` ]; then
  crictl rm --all --force || echo "... cleanup"
fi
systemctl stop keepalived || echo "... cleanup"
systemctl disable keepalived || echo "... cleanup"
#reboot

# Uncomment to allow downgrade from k8s 1.24.6 to 1.23.14
# apt autoremove --purge -y --allow-change-held-packages kubeadm kubectl kubelet kubernetes-cni kube*

# Uncomment to downgrade containerd to 1.6.12* to fix https://github.com/containerd/containerd/issues/7828 with current 1.6.13 release
# apt install -y --allow-downgrades --allow-change-held-packages containerd.io=1.6.12*
