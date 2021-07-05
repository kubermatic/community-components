#!/bin/bash
set -euo pipefail

TIMEOUT_SEC=60
TCPDUMP_LOGFILE="tcpdump_$(hostname -i).log"
TCPDUMP_BINARY="tcpdump_$(hostname -i).binary"

function create_arp_tcp_dump_interface_ip_sec() {
    if [ $# -ne 3 ]; then echo "call function: INTERFACE IP SEC"; exit 1; fi
    while true; do
      interface=$1
      ip=$2
      sec=$3
      echo ">>>>>>>> TCP DUMP TRACE: $interface $ip $sec <<<<<<<<<<<" >> $TCPDUMP_LOGFILE
      rm $TCPDUMP_BINARY || echo "try to delete tmp file"
      timeout $sec tcpdump -U -n -i $interface arp src host $ip -w $TCPDUMP_BINARY
      chown 0:0 $TCPDUMP_BINARY
      ls -la $TCPDUMP_BINARY
      tcpdump -r $TCPDUMP_BINARY -v >> $TCPDUMP_LOGFILE
    done
}

create_arp_tcp_dump_interface_ip_sec ens192 "$(hostname -i)" $TIMEOUT_SEC
