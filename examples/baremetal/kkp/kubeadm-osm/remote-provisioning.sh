#!/bin/bash
set -xeuo pipefail

# This script is used to bootstrap a node as part of an existing KKP cluster.
mkdir -p /opt/bin
cp /tmp/supervise.sh /opt/bin/supervise.sh
chmod +x /opt/bin/supervise.sh
systemctl enable cloud-init
cloud-init --file /tmp/manual-edge-kube-system-provisioning-config.cfg init
systemctl daemon-reload
systemctl disable cloud-init
systemctl restart setup.service
