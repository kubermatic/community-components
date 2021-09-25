#!/bin/bash

grep -i ubuntu /etc/os-release && echo "ubuntu detected!" || (echo "This script requires ubuntu!" && exit 1)
if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") K8S_VERSION"
  echo "e.g $(basename \"$0\") 1.18.10"
  exit 1
fi
K8S_VERSION="$1"

set -xeuo pipefail

####### Docker installation
echo "---------- Install packages for Container Runtime"
UBUNTU_LSB_RELEASE=${UBUNTU_LSB_RELEASE:-"focal"}
CONTAINERD_VERSION=${CONTAINERD_VERSION:-"1.2.13-2"}
DOCKER_VERSION=${DOCKER_VERSION:-"5:19.03.11~3-0~ubuntu-${UBUNTU_LSB_RELEASE}"}

if systemctl is-active ufw; then systemctl stop ufw; fi
systemctl mask ufw
systemctl restart systemd-modules-load.service
sysctl --system

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $UBUNTU_LSB_RELEASE stable"
apt-get update

mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
mkdir -p /etc/default/grub.d
# Enable cgroups memory and swap accounting
cat <<EOF > /etc/default/grub.d/60-swap-accounting.cfg
{
GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"
}
EOF

cp /etc/fstab /etc/fstab.orig
cat /etc/fstab.orig | awk '$3 ~ /^swap$/ && $1 !~ /^#/ {$0="# commented out by cloudinit\n#"$0} 1' > /etc/fstab.noswap
mv /etc/fstab.noswap /etc/fstab
swapoff -a
#We need to explicitly specify docker-ce and docker-ce-cli to the same version.
#	See: https://github.com/docker/cli/issues/2533
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y \
  curl \
  ca-certificates \
  ceph-common \
  cifs-utils \
  conntrack \
  e2fsprogs \
  ebtables \
  ethtool \
  glusterfs-client \
  iptables \
  jq \
  kmod \
  openssh-client \
  nfs-common \
  socat \
  util-linux \
  docker-ce="${DOCKER_VERSION}" \
  docker-ce-cli="${DOCKER_VERSION}" \
  ipvsadm
#
apt-mark hold docker-ce docker-ce-cli || true

##### CNI
opt_bin=/opt/bin
cni_bin_dir=/opt/cni/bin

#create all the necessary dirs
mkdir -p /etc/cni/net.d /etc/kubernetes/dynamic-config-dir /etc/kubernetes/manifests "$opt_bin" "$cni_bin_dir"

# HOST_ARCH can be defined outside of machine-controller (in kubeone for example)
arch=${HOST_ARCH-}
if [ -z "$arch" ]
then
case $(uname -m) in
x86_64)
    arch="amd64"
    ;;
aarch64)
    arch="arm64"
    ;;
*)
    echo "unsupported CPU architecture, exiting"
    exit 1
    ;;
esac
fi

# CNI variables
CNI_VERSION="${CNI_VERSION:-"v0.8.7"}"
cni_base_url="https://github.com/containernetworking/plugins/releases/download/$CNI_VERSION"
cni_filename="cni-plugins-linux-$arch-$CNI_VERSION.tgz"

# download CNI
curl -Lfo "$cni_bin_dir/$cni_filename" "$cni_base_url/$cni_filename"

# download CNI checksum
cni_sum=$(curl -Lf "$cni_base_url/$cni_filename.sha256")
cd "$cni_bin_dir"

# verify CNI checksum
sha256sum -c <<<"$cni_sum"

# unpack CNI
tar xvf "$cni_filename"
rm -f "$cni_filename"
cd -

#### kubelet *
KUBE_VERSION=v"${K8S_VERSION}"

### Some tune setup
mkdir -p /etc/systemd/journald.conf.d
cat <<EOF > /etc/systemd/journald.conf.d/max_disk_use.conf
[Journal]
    SystemMaxUse=5G
EOF
cat <<EOF > /opt/load-kernel-modules.sh
#!/usr/bin/env bash
set -euo pipefail

modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh

if modinfo nf_conntrack_ipv4 &> /dev/null; then
  modprobe nf_conntrack_ipv4
else
  modprobe nf_conntrack
fi
EOF

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
kernel.panic_on_oops = 1
kernel.panic = 10
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 1
vm.overcommit_memory = 1
fs.inotify.max_user_watches = 104857
EOF


curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

echo "---------- Install packages for Kubernetes $K8S_VERSION"
apt-get update && apt-get install -y \
  kubelet=${K8S_VERSION}-00 \
  kubeadm=${K8S_VERSION}-00 \
  kubectl=${K8S_VERSION}-00


### Finalize
systemctl daemon-reload
systemctl enable --now docker

# Update grub to include kernel command options to enable swap accounting.
if grep -v -q swapaccount=1 /proc/cmdline
then
  echo "Reboot system"
  update-grub
  touch /var/run/reboot-required
  reboot
fi
