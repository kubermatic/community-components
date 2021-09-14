#!/bin/bash

echo "Execute script"
set -xeuo pipefail
### Example to maintain nodes

#cat <<EOF > /etc/sysctl.d/k8s.conf
#net.bridge.bridge-nf-call-ip6tables = 1
#net.bridge.bridge-nf-call-iptables = 1
#kernel.panic_on_oops = 1
#kernel.panic = 10
#net.ipv4.ip_forward = 1
#net.ipv4.conf.all.rp_filter = 1
#vm.overcommit_memory = 1
#fs.inotify.max_user_watches = 104857
#EOF
#
#
#### Finalize
#echo "apply systemd changes"
#systemctl daemon-reload
#reboot