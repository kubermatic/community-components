#!/usr/bin/env bash
# Configure third-party APT repositories for the kubeone-tool container.
# Invoked once from the Dockerfile after the bootstrap packages
# (ca-certificates, curl, gnupg, lsb-release) are installed and before the
# main `apt-get install` pass.

set -euo pipefail

# Kubernetes apt repo version. Must be >= v1.32 because older kubectl
# builds (Go <= 1.24) crash with "lfstack.push invalid packing" when run
# under Rosetta 2 emulation on Apple Silicon. See golang/go#68714.
K8S_REPO_VERSION="v1.36"

CODENAME="$(lsb_release -cs)"
ARCH="$(dpkg --print-architecture)"
DISTRO="$(lsb_release -is)"

mkdir -p /etc/apt/keyrings /usr/share/keyrings

# --- Debian backports ------------------------------------------------------
# A few packages are not in Debian 'main' for a given stable release but are
# available via backports (e.g. upx-ucl on bookworm; Ubuntu ships it in
# 'universe' and Debian trixie in 'main'). Enabling backports gives them an
# install candidate. Backports are NotAutomatic (pin priority 100), so this
# does NOT pull backport versions of packages that already exist in 'main' --
# it only adds availability for ones that are otherwise missing. Scoped to
# bookworm on purpose so we never point at a -backports suite that does not
# exist for the current base (e.g. Ubuntu, or a Debian release without one).
if [ "${DISTRO}" = "Debian" ] && [ "${CODENAME}" = "bookworm" ]; then
  echo "deb http://deb.debian.org/debian ${CODENAME}-backports main" \
    > /etc/apt/sources.list.d/backports.list
fi

# --- HashiCorp (terraform) -------------------------------------------------
curl -fsSL https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor -o /etc/apt/trusted.gpg.d/hashicorp.gpg
echo "deb [arch=${ARCH}] https://apt.releases.hashicorp.com ${CODENAME} main" \
  > /etc/apt/sources.list.d/hashicorp.list

# --- Microsoft (azure-cli) -------------------------------------------------
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg
echo "deb [arch=${ARCH}] https://packages.microsoft.com/repos/azure-cli/ ${CODENAME} main" \
  > /etc/apt/sources.list.d/azure-cli.list

# --- Google Cloud SDK ------------------------------------------------------
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  > /etc/apt/sources.list.d/google-cloud-sdk.list

# --- Kubernetes (kubectl) --------------------------------------------------
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_REPO_VERSION}/deb/Release.key" \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_REPO_VERSION}/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

# --- Helm (Buildkite mirror) ----------------------------------------------
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey \
  | gpg --dearmor -o /usr/share/keyrings/helm.gpg
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" \
  > /etc/apt/sources.list.d/helm.list

# --- ngrok -----------------------------------------------------------------
curl -fsSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
  > /etc/apt/sources.list.d/ngrok.list
