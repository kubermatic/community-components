#! /bin/bash

echo "kubermatic:${PASS}"|chpasswd
/usr/sbin/sshd -D