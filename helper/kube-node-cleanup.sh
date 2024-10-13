#!/usr/bin/env bash
####################################
# ............. Kubernetes cleanup

# Step 1: Delete All Kubernetes Resources
# Before uninstalling Kubernetes, ensure that you delete all resources (like pods, services, and volumes) that were created under Kubernetes.

# kubectl delete all --all-namespaces --all

# Step 2: Uninstall kubeadm, kubectl, and kubelet
# Use the following commands to uninstall kubeadm, kubectl, and kubelet:
if [ $(which apt-get) ]; then
  sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube* -y
  sudo apt-get autoremove -y

  ####################################
  # ............. keepalived entfernen

  # Cleanup KeepaliveD für Neuinstallation
  sudo apt-get purge --auto-remove keepalived -y
fi

# Step 3: Remove Configuration and Data
# After uninstalling the Kubernetes components, ensure you remove all configurations and data related to Kubernetes:
sudo rm -rf ~/.kube
sudo rm -rf /etc/cni
sudo rm -rf /etc/kubernetes
sudo rm -rf /var/lib/etcd
sudo rm -rf /var/lib/kubelet


# Step 4: Reset iptables
# Reset the iptables rules to their default settings:
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

# Step 5: Revert Changes to the Hosts File
# If you made any changes to the /etc/hosts file during the Kubernetes setup, ensure you revert those changes.