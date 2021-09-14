##### kubeadm installation
FROM ubuntu:20.04

### for dind kubeadm
### docker run -it --privileged cruizba/ubuntu-dind
### kubeadm join xxxx --token xxxx --ignore-preflight-errors=Swap,SystemVerification
# TODO fix systemd startup
#FROM cruizba/ubuntu-dind

RUN apt-get update && apt-get install -y sudo apt-utils && apt-get clean
COPY kubeadm-generator-install.sh /kubeadm-install.sh
ARG K8S_VERSION=1.18.10
RUN chmod +x /kubeadm-install.sh && /kubeadm-install.sh ${K8S_VERSION}


