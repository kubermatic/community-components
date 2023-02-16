#!/bin/bash

grep -i rocky /etc/os-release && echo "rocky detected!" || (echo "This script requires rocky!" && exit 1)
if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") K8S_VERSION"
  echo "e.g $(basename \"$0\") 1.22.5"
  exit 1
fi
K8S_VERSION="$1"

set -xeuo pipefail

####### Containerd installation
echo "---------- Install packages for Container Runtime"
yum install -y yum-utils
yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
# Due to DNF modules we have to do this on docker-ce repo
# More info at: https://bugzilla.redhat.com/show_bug.cgi?id=1756473
yum-config-manager --save --setopt=docker-ce-stable.module_hotfixes=true
yum install -y containerd.io-1.6* yum-plugin-versionlock
yum versionlock add containerd.io

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo tee /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: false
EOF

# Using the systemd cgroup driver with runc
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Enable and Restart Containerd:
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo systemctl restart containerd


####### Install and configure prerequisites
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /opt/load-kernel-modules.sh
modprobe ip_tables
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh

if modinfo nf_conntrack_ipv4 &> /dev/null; then
  modprobe nf_conntrack_ipv4
else
  modprobe nf_conntrack
fi

modprobe overlay
modprobe br_netfilter
EOF
chmod 755 /opt/load-kernel-modules.sh

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
kernel.panic_on_oops = 1
kernel.panic = 10
net.ipv4.ip_forward = 1
vm.overcommit_memory = 1
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192
EOF

cat <<EOF | sudo tee /etc/selinux/config
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=permissive
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
EOF

setenforce 0 || true
systemctl restart systemd-modules-load.service
sysctl --system
sudo systemctl restart containerd

# Apply sysctl params without reboot
sudo sysctl --system

# Install required tools
yum install -y \
  device-mapper-persistent-data \
  lvm2 \
  ebtables \
  ethtool \
  nfs-utils \
  bash-completion \
  sudo \
  socat \
  wget \
  curl \
  tar \
  ipvsadm \
  iproute-tc

systemctl disable --now firewalld || true

DEFAULT_IFC_NAME=$(ip -o route get 1  | grep -oP "dev \K\S+")
IFC_CFG_FILE=/etc/sysconfig/network-scripts/ifcfg-$DEFAULT_IFC_NAME
# Enable IPv6 and DHCPv6 on the default interface
grep IPV6INIT $IFC_CFG_FILE && sed -i '/IPV6INIT*/c IPV6INIT=yes' $IFC_CFG_FILE || echo "IPV6INIT=yes" >> $IFC_CFG_FILE
grep DHCPV6C $IFC_CFG_FILE && sed -i '/DHCPV6C*/c DHCPV6C=yes' $IFC_CFG_FILE || echo "DHCPV6C=yes" >> $IFC_CFG_FILE
grep IPV6_AUTOCONF $IFC_CFG_FILE && sed -i '/IPV6_AUTOCONF*/c IPV6_AUTOCONF=yes' $IFC_CFG_FILE || echo "IPV6_AUTOCONF=yes" >> $IFC_CFG_FILE
# Restart NetworkManager to apply for IPv6 configs
systemctl restart NetworkManager
# Let NetworkManager apply the DHCPv6 configs
sleep 3

####### Installing kubeadm, kubelet and kubectl

#Install CNI plugins
CNI_VERSION="v1.1.1"
ARCH="amd64"
sudo mkdir -p /opt/cni/bin
sudo curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz" | sudo tar -C /opt/cni/bin -xz

# Set the download directory
DOWNLOAD_DIR=/usr/local/bin
sudo mkdir -p $DOWNLOAD_DIR

# Install crictl 
CRICTL_VERSION="v1.22.0"
ARCH="amd64"
sudo curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz
sudo rm -f /usr/bin/crictl
sudo ln -s /usr/local/bin/crictl /usr/bin/crictl

# Install kubeadm, kubelet, kubectl and add a kubelet systemd service:
RELEASE=v$K8S_VERSION
ARCH="amd64"
cd $DOWNLOAD_DIR
sudo curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet,kubectl}
sudo chmod +x {kubeadm,kubelet,kubectl}
sudo rm -f /usr/bin/kubeadm /usr/bin/kubectl /usr/bin/kubelet
sudo ln -s /usr/local/bin/kubeadm /usr/bin/kubeadm
sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl
sudo ln -s /usr/local/bin/kubelet /usr/bin/kubelet

mkdir -p /etc/systemd/journald.conf.d
cat <<EOF | sudo tee  /etc/systemd/journald.conf.d/max_disk_use.conf
[Journal]
SystemMaxUse=5G
EOF

####### Disable SWAP
cat <<EOF | sudo tee /opt/disable-swap.sh
#!/usr/bin/env bash
set -euo pipefail

# Make sure we always disable swap - Otherwise the kubelet won't start as for some cloud
# providers swap gets enabled on reboot or after the setup script has finished executing.
sed -i.orig '/.*swap.*/d' /etc/fstab
swapoff -a
EOF
chmod 755 /opt/disable-swap.sh

#cat <<EOF | sudo tee /opt/setup_net_env.sh
##!/usr/bin/env bash
#echodate() {
#  echo "[$(date -Is)]" "$@"
#}
#
## get the default interface IP address
#DEFAULT_IFC_IP=$(ip -o  route get 1 | grep -oP "src \K\S+")
#
#if [ -z "${DEFAULT_IFC_IP}" ]
#then
#  echodate "Failed to get IP address for the default route interface"
#  exit 1
#fi
#
## get the full hostname
#FULL_HOSTNAME=$(hostname -f)
## if /etc/machine-name is not empty then use the hostname from there
#if [ -s /etc/machine-name ]; then
#    FULL_HOSTNAME=$(cat /etc/machine-name)
#fi
#
## write the nodeip_env file
## we need the line below because flatcar has the same string "coreos" in that file
#if grep -q coreos /etc/os-release
#then
#  echo "KUBELET_NODE_IP=${DEFAULT_IFC_IP}\nKUBELET_HOSTNAME=${FULL_HOSTNAME}" > /etc/kubernetes/nodeip.conf
#elif [ ! -d /etc/systemd/system/kubelet.service.d ]
#then
#  echodate "Can't find kubelet service extras directory"
#  exit 1
#else
#  echo -e "[Service]\nEnvironment=\"KUBELET_NODE_IP=${DEFAULT_IFC_IP}\"\nEnvironment=\"KUBELET_HOSTNAME=${FULL_HOSTNAME}\"" > /etc/systemd/system/kubelet.service.d/nodeip.conf
#fi
#EOF
#chmod 755 /opt/setup_net_env.sh

mkdir -p /etc/systemd/system/kubelet.service.d/
# set kubelet nodeip environment variable
#/opt/setup_net_env.sh


cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
After=containerd.service
Requires=containerd.service

Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/home/

[Service]
User=root
Restart=always
StartLimitInterval=0
RestartSec=10
CPUAccounting=true
MemoryAccounting=true

Environment="PATH=/opt/bin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin/"
EnvironmentFile=-/etc/environment

ExecStartPre=/bin/bash /opt/disable-swap.sh
ExecStartPre=/bin/bash /opt/load-kernel-modules.sh
ExecStart=/opt/bin/kubelet \
  --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
  --kubeconfig=/var/lib/kubelet/kubeconfig \
  --config=/etc/kubernetes/kubelet.conf \
  --network-plugin=cni \
  --cert-dir=/etc/kubernetes/pki \
  --exit-on-lock-contention \
  --lock-file=/tmp/kubelet.lock \
  --container-runtime=remote \
  --container-runtime-endpoint=unix:///run/containerd/containerd.sock \
[Install]
WantedBy=multi-user.target
EOF
## REMOVED
#ExecStartPre=/bin/bash /opt/setup_net_env.sh

# Enable and start kubelet
systemctl daemon-reload
sudo systemctl enable --now kubelet

####### REMOVED
#cat <<EOF | sudo tee /opt/bin/health-monitor.sh
#  #!/usr/bin/env bash
#
#  # Copyright 2016 The Kubernetes Authors.
#  #
#  # Licensed under the Apache License, Version 2.0 (the "License");
#  # you may not use this file except in compliance with the License.
#  # You may obtain a copy of the License at
#  #
#  #     http://www.apache.org/licenses/LICENSE-2.0
#  #
#  # Unless required by applicable law or agreed to in writing, software
#  # distributed under the License is distributed on an "AS IS" BASIS,
#  # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  # See the License for the specific language governing permissions and
#  # limitations under the License.
#
#  # This script is for master and node instance health monitoring, which is
#  # packed in kube-manifest tarball. It is executed through a systemd service
#  # in cluster/gce/gci/<master/node>.yaml. The env variables come from an env
#  # file provided by the systemd service.
#
#  # This script is a slightly adjusted version of
#  # https://github.com/kubernetes/kubernetes/blob/e1a1aa211224fcd9b213420b80b2ae680669683d/cluster/gce/gci/health-monitor.sh
#  # Adjustments are:
#  # * Kubelet health port is 10248 not 10255
#  # * Removal of all all references to the KUBE_ENV file
#
#  set -o nounset
#  set -o pipefail
#
#  # We simply kill the process when there is a failure. Another systemd service will
#  # automatically restart the process.
#  function container_runtime_monitoring() {
#    local -r max_attempts=5
#    local attempt=1
#    local -r container_runtime_name="${CONTAINER_RUNTIME_NAME:-docker}"
#    # We still need to use 'docker ps' when container runtime is "docker". This is because
#    # dockershim is still part of kubelet today. When kubelet is down, crictl pods
#    # will also fail, and docker will be killed. This is undesirable especially when
#    # docker live restore is disabled.
#    local healthcheck_command="docker ps"
#    if [[ "${CONTAINER_RUNTIME:-docker}" != "docker" ]]; then
#      healthcheck_command="crictl pods"
#    fi
#    # Container runtime startup takes time. Make initial attempts before starting
#    # killing the container runtime.
#    until timeout 60 ${healthcheck_command} > /dev/null; do
#      if ((attempt == max_attempts)); then
#        echo "Max attempt ${max_attempts} reached! Proceeding to monitor container runtime healthiness."
#        break
#      fi
#      echo "$attempt initial attempt \"${healthcheck_command}\"! Trying again in $attempt seconds..."
#      sleep "$((2 ** attempt++))"
#    done
#    while true; do
#      if ! timeout 60 ${healthcheck_command} > /dev/null; then
#        echo "Container runtime ${container_runtime_name} failed!"
#        if [[ "$container_runtime_name" == "docker" ]]; then
#          # Dump stack of docker daemon for investigation.
#          # Log file name looks like goroutine-stacks-TIMESTAMP and will be saved to
#          # the exec root directory, which is /var/run/docker/ on Ubuntu and COS.
#          pkill -SIGUSR1 dockerd
#        fi
#        systemctl kill --kill-who=main "${container_runtime_name}"
#        # Wait for a while, as we don't want to kill it again before it is really up.
#        sleep 120
#      else
#        sleep "${SLEEP_SECONDS}"
#      fi
#    done
#  }
#
#  function kubelet_monitoring() {
#    echo "Wait for 2 minutes for kubelet to be functional"
#    sleep 120
#    local -r max_seconds=10
#    local output=""
#    while true; do
#      local failed=false
#
#      if journalctl -u kubelet -n 1 | grep -q "use of closed network connection"; then
#        failed=true
#        echo "Kubelet stopped posting node status. Restarting"
#      elif ! output=$(curl -m "${max_seconds}" -f -s -S http://127.0.0.1:10248/healthz 2>&1); then
#        failed=true
#        # Print the response and/or errors.
#        echo "$output"
#      fi
#
#      if [[ "$failed" == "true" ]]; then
#        echo "Kubelet is unhealthy!"
#        systemctl kill kubelet
#        # Wait for a while, as we don't want to kill it again before it is really up.
#        sleep 60
#      else
#        sleep "${SLEEP_SECONDS}"
#      fi
#    done
#  }
#
#  ############## Main Function ################
#  if [[ "$#" -ne 1 ]]; then
#    echo "Usage: health-monitor.sh <container-runtime/kubelet>"
#    exit 1
#  fi
#
#  SLEEP_SECONDS=10
#  component=$1
#  echo "Start kubernetes health monitoring for ${component}"
#  if [[ "${component}" == "container-runtime" ]]; then
#    container_runtime_monitoring
#  elif [[ "${component}" == "kubelet" ]]; then
#    kubelet_monitoring
#  else
#    echo "Health monitoring for component ${component} is not supported!"
#  fi
#EOF
#sudo chmod 755 /opt/bin/health-monitor.sh
#cat <<EOF | sudo tee /etc/systemd/system/kubelet-healthcheck.service
#[Unit]
#Requires=kubelet.service
#After=kubelet.service
#
#[Service]
#ExecStart=/opt/bin/health-monitor.sh kubelet
#
#[Install]
#WantedBy=multi-user.target
#EOF
#systemctl daemon-reload
#systemctl enable --now --no-block kubelet-healthcheck.service
