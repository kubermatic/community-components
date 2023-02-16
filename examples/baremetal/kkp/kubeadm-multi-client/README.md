
# Baremetal hosting

## SSH
user: `root`
machines: [`hosts.txt`](./hosts.txt)
worker nodes: [`upgradehosts.txt`](./upgradehosts.txt)

## Nodes Provisioning

1. Setup Kubeadm Cluster at Kubermatic:
   - DEV: https://dev.k8.3ascloud.de
2. Download kubeconfig
3. Initial Nodes with ***SAME version*** as control plane
```bash
# USE same as control plane. Second parameter is OS, whether ubuntu or rockylinux.
./01_setup-install-multi-client-ssh.sh 'username@172.14.16.1,root@jumphost.example.com' ubuntu 1.23.12
```
4. Create kubeadm join token, with the [`kubeadm/Dockerfile-ubuntu`](kubeadm/Dockerfile-ubuntu) or [`kubeadm/Dockerfile-rockylinux`](kubeadm/Dockerfile-rockylinux)
```bash
./02_create_kubeadm_join_token.sh 1.23.12 ubuntu ~/Downloads/kubeconfig-admin-xxxxxx
```
5. Copy output of docker container `kubeadm join ... --token .. -discovery-token-ca-cert-hash ...` and execute join node script:
```bash
./03_setup-join-multi-client-ssh.sh 'username@172.14.16.1,root@jumphost.example.com' 'pasted-command'
```

## Nodes Upgrade
1. Run upgrade script as follows passing the jumphost config, new k8s version, os flavor and kubeconfig as parameter. 
> This script will drain, remove and upgrade the node.
> Create upgradenodes.txt and add the user cluster worker nodes list (Comma-separated Format: hostIP,nodename) to be upgraded. 
```bash
./04_uprade_kubeadm-multi-client-ssh.sh 'username@172.14.16.1,root@jumphost.example.com' ubuntu 1.24.6 ~/Downloads/kubeconfig-admin-xxxxxx
```
2. Create kubeadm join token, with the [`kubeadm/Dockerfile-ubuntu`](kubeadm/Dockerfile-ubuntu) or [`kubeadm/Dockerfile-rockylinux`](kubeadm/Dockerfile-rockylinux)
```bash
./02_create_kubeadm_join_token.sh 1.24.6 ubuntu ~/Downloads/kubeconfig-admin-xxxxxx
```
3. Copy output of docker container `kubeadm join ... --token .. -discovery-token-ca-cert-hash ...` and execute join node script:
```bash
./03_setup-join-multi-client-ssh.sh 'username@172.14.16.1,root@jumphost.example.com' 'pasted-command'
```
