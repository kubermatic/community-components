#!/usr/bin/env bash
#
# A script to scan ports on remote hosts without any tools like nmap
#

subnet=192.168.178

for ip in {1..254};
do for port in {22,80,443,3306,3389};
        do (echo >/dev/tcp/$subnet.$ip/$port) >& /dev/null \
	&& echo "$subnet.$ip:$port is open"
       done;
done
