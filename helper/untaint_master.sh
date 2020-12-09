#!/bin/sh

kubectl taint nodes --all node-role.kubernetes.io/master-

### taint master
#kubectl taint node NODE_NAME node-role.kubernetes.io/master:NoSchedule