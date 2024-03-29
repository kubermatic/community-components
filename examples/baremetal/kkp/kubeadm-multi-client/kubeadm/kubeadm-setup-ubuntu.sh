#!/bin/bash

grep -i ubuntu /etc/os-release && echo "ubuntu detected!" || (echo "This script requires ubuntu!" && exit 1)
if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
  echo "Usage: $(basename \"$0\") K8S_VERSION"
  echo "e.g $(basename \"$0\") 1.22.5"
  exit 1
fi
K8S_VERSION="$1"

set -xeuo pipefail

####### Containerd installation
echo "---------- Install packages for Container Runtime"
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get install -y --allow-downgrades --allow-change-held-packages containerd.io=1.6*
apt-mark hold containerd.io

# Configure containerd
sudo mkdir -p /etc/systemd/system/containerd.service.d
sudo tee /etc/systemd/system/containerd.service.d/environment.conf <<EOF
[Service]
Restart=always
EnvironmentFile=-/etc/environment
EOF

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

cat <<EOF | sudo tee /etc/default/grub.d/60-swap-accounting.cfg
# Added by kubermatic machine-controller
# Enable cgroups memory and swap accounting
GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"
EOF

mkdir -p /etc/systemd/journald.conf.d
cat <<EOF | sudo tee  /etc/systemd/journald.conf.d/max_disk_use.conf
[Journal]
SystemMaxUse=5G
EOF


# Install required tools
if systemctl is-active ufw; then systemctl stop ufw; fi
systemctl mask ufw
# As we added some modules and don't want to reboot, restart the service
sudo systemctl restart systemd-modules-load.service
sudo sysctl --system
sudo systemctl restart containerd
# Override hostname if /etc/machine-name exists
if [ -x "$(command -v hostnamectl)" ] && [ -s /etc/machine-name ]; then
  machine_name=$(cat /etc/machine-name)
  hostnamectl set-hostname ${machine_name}
fi
apt-get update
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
  ipvsadm


####### Installing kubeadm, kubelet and kubectl

#Install CNI plugins
opt_bin=/opt/bin
usr_local_bin=/usr/local/bin
cni_bin_dir=/opt/cni/bin
mkdir -p /etc/cni/net.d /etc/kubernetes/manifests "$opt_bin" "$cni_bin_dir"
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
CNI_VERSION="${CNI_VERSION:-v1.1.1}"
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

# cri-tools variables
CRI_TOOLS_RELEASE="${CRI_TOOLS_RELEASE:-v1.22.0}"
cri_tools_base_url="https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRI_TOOLS_RELEASE}"
cri_tools_filename="crictl-${CRI_TOOLS_RELEASE}-linux-${arch}.tar.gz"

# download cri-tools
curl -Lfo "$opt_bin/$cri_tools_filename" "$cri_tools_base_url/$cri_tools_filename"
# download cri-tools checksum
# the cri-tools checksum file has a filename prefix that breaks sha256sum so we need to drop it with sed
cri_tools_sum=$(curl -Lf "$cri_tools_base_url/$cri_tools_filename.sha256" | sed 's/\*\///')
cd "$opt_bin"

# verify cri-tools checksum
sha256sum -c <<<"$cri_tools_sum"

# unpack cri-tools and symlink to path so it's available to all users
tar xvf "$cri_tools_filename"
rm -f "$cri_tools_filename"
ln -sf "$opt_bin/crictl" "$usr_local_bin"/crictl || echo "symbolic link is skipped"
cd -

systemctl stop kubelet || echo "if present ..."

# Created required Kubelet configurations
mkdir -p /etc/systemd/system/kubelet.service.d/
sudo tee /etc/systemd/system/kubelet.service.d/extras.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--resolv-conf=/run/systemd/resolve/resolv.conf"
EOF

sudo systemctl daemon-reload

# Renamed /etc/kubernetes/kubelet.conf to /etc/systemd/system/kubelet.service.d/config.yaml and updated the reference in /etc/systemd/system/kubelet.service. since kubelet.conf is Kubeconfig file.
# Reference https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service.d/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
cgroupDriver: systemd
clusterDNS:
- "10.240.16.10"
clusterDomain: cluster.local
containerLogMaxSize: 100Mi
containerLogMaxFiles: 5
cpuManagerReconcilePeriod: 0s
evictionPressureTransitionPeriod: 0s
featureGates:
  RotateKubeletServerCertificate: true
fileCheckFrequency: 0s
httpCheckFrequency: 0s
imageMinimumGCAge: 0s
logging:
  flushFrequency: 0
  options:
    json:
      infoBufferSize: "0"
  verbosity: 0
memorySwap: {}
nodeStatusReportFrequency: 0s
nodeStatusUpdateFrequency: 0s
protectKernelDefaults: true
readOnlyPort: 0
resolvConf: /run/systemd/resolve/resolv.conf
rotateCertificates: true
runtimeRequestTimeout: 0s
serverTLSBootstrap: true
shutdownGracePeriod: 0s
shutdownGracePeriodCriticalPods: 0s
staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 0s
syncFrequency: 0s
kubeReserved:
  cpu: 200m
  ephemeral-storage: 1Gi
  memory: 200Mi
systemReserved:
  cpu: 200m
  ephemeral-storage: 1Gi
  memory: 200Mi
evictionHard:
  imagefs.available: 15%
  memory.available: 100Mi
  nodefs.available: 10%
  nodefs.inodesFree: 5%
tlsCipherSuites:
- TLS_AES_128_GCM_SHA256
- TLS_AES_256_GCM_SHA384
- TLS_CHACHA20_POLY1305_SHA256
- TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
- TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
- TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
- TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
- TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
- TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
volumePluginDir: /var/lib/kubelet/volumeplugins
volumeStatsAggPeriod: 0s
EOF

# cat <<EOF | sudo tee /opt/bin/setup_net_env.sh
# #!/usr/bin/env bash
# echodate() {
#   echo "[\$(date -Is)]" "$@"
# }
# # get the default interface IP address
# {{- if eq .NetworkIPFamily "IPv6" }}
# DEFAULT_IFC_IP=\$(ip -o -6 route get  1:: | grep -oP "src \K\S+")
# {{- else if eq .NetworkIPFamily "IPv4+IPv6" }}
# DEFAULT_IFC_IPv4=\$(ip -o route get  1 | grep -oP "src \K\S+")
# DEFAULT_IFC_IPv6=\$(ip -o -6 route get  1:: | grep -oP "src \K\S+")
# if [ -z "\${DEFAULT_IFC_IPv6}" ]
# then
#   echodate "Failed to get IPv6 address for the default route interface"
#   exit 1
# fi
# DEFAULT_IFC_IP=\$DEFAULT_IFC_IPv4,\$DEFAULT_IFC_IPv6
# {{- else }}
# DEFAULT_IFC_IP=\$(ip -o  route get 1 | grep -oP "src \K\S+")
# {{- end }}
# if [ -z "\${DEFAULT_IFC_IP}" ]
# then
#   echodate "Failed to get IP address for the default route interface"
#   exit 1
# fi
# # get the full hostname
# FULL_HOSTNAME=\$(hostname -f)
# # if /etc/machine-name is not empty then use the hostname from there
# if [ -s /etc/machine-name ]; then
#   FULL_HOSTNAME=\$(cat /etc/machine-name)
# fi
# # write the nodeip_env file
# # we need the line below because flatcar has the same string "coreos" in that file
# if grep -q coreos /etc/os-release
# then
#   echo "KUBELET_NODE_IP=\${DEFAULT_IFC_IP}\nKUBELET_HOSTNAME=\${FULL_HOSTNAME}" > /etc/kubernetes/nodeip.conf
# elif [ ! -d /etc/systemd/system/kubelet.service.d ]
# then
#   echodate "Can't find kubelet service extras directory"
#   exit 1
# else
#   echo -e "[Service]\nEnvironment=\"KUBELET_NODE_IP=\${DEFAULT_IFC_IP}\"\nEnvironment=\"KUBELET_HOSTNAME=\${FULL_HOSTNAME}\"" > /etc/systemd/system/kubelet.service.d/nodeip.conf
# fi
# EOF
# chmod 755 /opt/bin/setup_net_env.sh

cat <<EOF | sudo tee /opt/bin/health-monitor.sh
#!/usr/bin/env bash
# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# This script is for master and node instance health monitoring, which is
# packed in kube-manifest tarball. It is executed through a systemd service
# in cluster/gce/gci/<master/node>.yaml. The env variables come from an env
# file provided by the systemd service.
# This script is a slightly adjusted version of
# https://github.com/kubernetes/kubernetes/blob/e1a1aa211224fcd9b213420b80b2ae680669683d/cluster/gce/gci/health-monitor.sh
# Adjustments are:
# * Kubelet health port is 10248 not 10255
# * Removal of all all references to the KUBE_ENV file
set -o nounset
set -o pipefail
# We simply kill the process when there is a failure. Another systemd service will
# automatically restart the process.
function container_runtime_monitoring() {
  local -r max_attempts=5
  local attempt=1
  local -r container_runtime_name="\${CONTAINER_RUNTIME_NAME:-docker}"
  # We still need to use 'docker ps' when container runtime is "docker". This is because
  # dockershim is still part of kubelet today. When kubelet is down, crictl pods
  # will also fail, and docker will be killed. This is undesirable especially when
  # docker live restore is disabled.
  local healthcheck_command="docker ps"
  if [[ "\${CONTAINER_RUNTIME:-docker}" != "docker" ]]; then
    healthcheck_command="crictl pods"
  fi
  # Container runtime startup takes time. Make initial attempts before starting
  # killing the container runtime.
  until timeout 60 \${healthcheck_command} > /dev/null; do
    if ((attempt == max_attempts)); then
      echo "Max attempt \${max_attempts} reached! Proceeding to monitor container runtime healthiness."
      break
    fi
    echo "\$attempt initial attempt \"\${healthcheck_command}\"! Trying again in \$attempt seconds..."
    sleep "\$((2 ** attempt++))"
  done
  while true; do
    if ! timeout 60 \${healthcheck_command} > /dev/null; then
      echo "Container runtime \${container_runtime_name} failed!"
      if [[ "\$container_runtime_name" == "docker" ]]; then
        # Dump stack of docker daemon for investigation.
        # Log file name looks like goroutine-stacks-TIMESTAMP and will be saved to
        # the exec root directory, which is /var/run/docker/ on Ubuntu and COS.
        pkill -SIGUSR1 dockerd
      fi
      systemctl kill --kill-who=main "\${container_runtime_name}"
      # Wait for a while, as we don't want to kill it again before it is really up.
      sleep 120
    else
      sleep "\${SLEEP_SECONDS}"
    fi
  done
}
function kubelet_monitoring() {
  echo "Wait for 2 minutes for kubelet to be functional"
  sleep 120
  local -r max_seconds=10
  local output=""
  while true; do
    local failed=false
    if journalctl -u kubelet -n 1 | grep -q "use of closed network connection"; then
      failed=true
      echo "Kubelet stopped posting node status. Restarting"
    elif ! output=\$(curl -m "\${max_seconds}" -f -s -S http://127.0.0.1:10248/healthz 2>&1); then
      failed=true
      # Print the response and/or errors.
      echo "\$output"
    fi
    if [[ "\$failed" == "true" ]]; then
      echo "Kubelet is unhealthy!"
      systemctl kill kubelet
      # Wait for a while, as we don't want to kill it again before it is really up.
      sleep 60
    else
      sleep "\${SLEEP_SECONDS}"
    fi
  done
}
############## Main Function ################
if [[ "\$#" -ne 1 ]]; then
  echo "Usage: health-monitor.sh <container-runtime/kubelet>"
  exit 1
fi
SLEEP_SECONDS=10
component=\$1
echo "Start kubernetes health monitoring for \${component}"
if [[ "\${component}" == "container-runtime" ]]; then
  container_runtime_monitoring
elif [[ "\${component}" == "kubelet" ]]; then
  kubelet_monitoring
else
  echo "Health monitoring for component \${component} is not supported!"
fi
EOF
chown 755 /opt/bin/health-monitor.sh

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

# kubelet
KUBE_VERSION="v$K8S_VERSION"
kube_dir="$opt_bin/kubernetes-$KUBE_VERSION"
kube_base_url="https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/$arch"
kube_sum_file="$kube_dir/sha256"

# create versioned kube dir
mkdir -p "$kube_dir"
: >"$kube_sum_file"
for bin in kubelet kubeadm kubectl; do
    # download kube binary
    curl -Lfo "$kube_dir/$bin" "$kube_base_url/$bin"
    chmod +x "$kube_dir/$bin"
    # download kube binary checksum
    sum=$(curl -Lf "$kube_base_url/$bin.sha256")
    # save kube binary checksum
    echo "$sum  $kube_dir/$bin" >>"$kube_sum_file"
done

# check kube binaries checksum
sha256sum -c "$kube_sum_file"
for bin in kubelet kubeadm kubectl; do
    # link kube binaries from verioned dir to $opt_bin
    ln -sf "$kube_dir/$bin" "$opt_bin"/$bin
    ln -sf "$kube_dir/$bin" "/usr/bin"/$bin
done

cat <<EOF | sudo tee /etc/profile.d/opt-bin-path.sh
export PATH="/opt/bin:$PATH"
EOF
chown 644 /etc/profile.d/opt-bin-path.sh

# set kubelet nodeip environment variable
#/opt/bin/setup_net_env.sh


# Add kubelet.service
if [ ["$K8S_VERSION" == *"1.24"*] ]; then
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
EnvironmentFile=-/etc/systemd/system/kubelet.service.d/extras.conf
ExecStartPre=/bin/bash /opt/disable-swap.sh
ExecStartPre=/bin/bash /opt/load-kernel-modules.sh
ExecStart=/opt/bin/kubelet \$KUBELET_EXTRA_ARGS \
  --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
  --kubeconfig=/etc/kubernetes/kubelet.conf \
  --config=/etc/systemd/system/kubelet.service.d/config.yaml \
  --network-plugin=cni \
  --cert-dir=/etc/kubernetes/pki \
  --exit-on-lock-contention \
  --lock-file=/tmp/kubelet.lock \
  --container-runtime=remote \
  --container-runtime-endpoint=unix:///run/containerd/containerd.sock \
  --feature-gates=RotateKubeletServerCertificate=true

[Install]
WantedBy=multi-user.target
EOF
#REMOVED 
#ExecStartPre=/bin/bash /opt/bin/setup_net_env.sh
else
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
EnvironmentFile=-/etc/systemd/system/kubelet.service.d/extras.conf
ExecStartPre=/bin/bash /opt/disable-swap.sh
ExecStartPre=/bin/bash /opt/load-kernel-modules.sh
ExecStart=/opt/bin/kubelet \$KUBELET_EXTRA_ARGS \
  --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
  --kubeconfig=/etc/kubernetes/kubelet.conf \
  --config=/etc/systemd/system/kubelet.service.d/config.yaml \
  --cert-dir=/etc/kubernetes/pki \
  --exit-on-lock-contention \
  --lock-file=/tmp/kubelet.lock \
  --container-runtime=remote \
  --container-runtime-endpoint=unix:///run/containerd/containerd.sock \
  --feature-gates=RotateKubeletServerCertificate=true

[Install]
WantedBy=multi-user.target
EOF
# REMOVED --network-plugin=cni as not supported from 1.24 k8s release
fi


cat <<EOF | sudo tee /etc/systemd/system/kubelet-healthcheck.service
[Unit]
Requires=kubelet.service
After=kubelet.service
[Service]
ExecStart=/opt/bin/health-monitor.sh kubelet
[Install]
WantedBy=multi-user.target
EOF

# fetch kubelet bootstrapping kubeconfig
#curl -s -k -v --header 'Authorization: Bearer {{ .Token }}' {{ .ServerURL }}/api/v1/namespaces/cloud-init-settings/secrets/{{ .BootstrapKubeconfigSecretName }} | jq '.data["kubeconfig"]' -r| base64 -d > /etc/kubernetes/bootstrap-kubelet.conf

systemctl daemon-reload
systemctl enable --now kubelet
systemctl enable --now --no-block kubelet-healthcheck.service
