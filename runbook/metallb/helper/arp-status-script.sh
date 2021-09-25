#!/bin/bash
TIMEOUT_SEC=60
IP_LOGFILE="ip_neigh_show_$(hostname -i).log"

function arpshow() {
echo "$(date) ---------------------"
echo "PING ---------------------"
ping -w 5 10.53.18.1
ping -w 5 10.53.18.2
echo "sleep 2 ..." && sleep 2
ip neigh show

echo "CURL ---------------------"
curl -k https://10.53.18.1
curl -k https://10.53.18.2
echo "sleep 2 ..." && sleep 2
ip neigh show

echo "ARPING -------------------"
arping -I ens192 10.53.18.1 -c 5 -b
arping -I ens192 10.53.18.2 -c 5 -b
echo "sleep 2 ..." && sleep 2
ip neigh show
echo "------------------------------------------------"
}

while true ; do
  arpshow   2>&1 | tee -a $IP_LOGFILE
  echo "sleep $TIMEOUT_SEC ..." && sleep $TIMEOUT_SEC
done
