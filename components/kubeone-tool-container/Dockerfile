# Copyright YEAR The XXX Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


FROM golang:1.15

RUN apt-get update && apt-get install -y \
    bash-completion \
    python3-crcmod \
        ca-certificates \
        curl \
        apt-transport-https \
        lsb-release \
        gnupg \
         unzip \
               upx-ucl


ENV GO111MODULE on
ENV USER root

# Install Terraform
ENV TERRAFORM_VERSION "0.13.3"
RUN curl -fL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip | funzip >/usr/local/bin/terraform
RUN chmod +x /usr/local/bin/terraform

# Install Kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin

# Install Jq
RUN curl -o /usr/local/bin/jq http://stedolan.github.io/jq/download/linux64/jq && \
  chmod +x /usr/local/bin/jq

# Install Yq
RUN RELEASE_URL=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/mikefarah/yq/releases/latest) && \
 YQ_LATEST="${RELEASE_URL##*/}" && \
 wget https://github.com/mikefarah/yq/releases/download/$YQ_LATEST/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# Install KubeOne
RUN VERSION=$(curl -w '%{url_effective}' -I -L -s -S https://github.com/kubermatic/kubeone/releases/latest -o /dev/null | sed -e 's|.*/v||') && \
 curl -LO "https://github.com/kubermatic/kubeone/releases/download/v${VERSION}/kubeone_${VERSION}_linux_amd64.zip" && \
 unzip kubeone_${VERSION}_linux_amd64.zip -d kubeone_${VERSION}_linux_amd64 && \
 mv kubeone_${VERSION}_linux_amd64/kubeone /usr/local/bin

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
unzip awscliv2.zip && \
./aws/install

# Install Azure CLI
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
         gpg --dearmor | \
          tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null  && \
         AZ_REPO=$(lsb_release -cs) && \
         echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
              tee /etc/apt/sources.list.d/azure-cli.list  && \
         apt-get update -y && \
         apt-get install azure-cli -y

# Install GCP CLI
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list &&  \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - &&  \
    apt-get update -y && \
    apt-get install google-cloud-sdk -y

RUN kubectl completion bash >> /etc/bash_completion.d/kubectl
RUN echo "source <(kubeone completion bash)" >> ~/.bashrc
RUN echo 'source <(kubectl completion bash)' >> ~/.bashrc
RUN echo 'alias k="kubectl"'  >> ~/.bashrc
RUN echo 'alias kg="kubectl get"' >> ~/.bashrc
RUN echo 'alias kgpo="kubectl get pods"' >> ~/.bashrc
RUN echo 'alias kgpoojson="kubectl get pods -o=json"' >> ~/.bashrc
RUN echo 'alias kgpon="kubectl get pods --namespace"' >> ~/.bashrc
RUN echo 'alias ksysgpooyamll="kubectl --namespace=kube-system get pods -o=yaml -l"' >> ~/.bashrc
RUN echo 'alias krm="kubectl delete"' >> ~/.bashrc
RUN echo 'alias krmf="kubectl delete -f"' >> ~/.bashrc
RUN echo 'alias krming="kubectl delete ingress"' >> ~/.bashrc
RUN echo 'alias krmingl="kubectl delete ingress -l"' >> ~/.bashrc
RUN echo 'alias krmingall="kubectl delete ingress --all-namespaces"' >> ~/.bashrc
RUN echo 'alias ka="kubectl apply -f"' >> ~/.bashrc
RUN echo 'alias klo="kubectl logs -f"' >> ~/.bashrc
RUN echo 'alias kex="kubectl exec -i -t"' >> ~/.bashrc

CMD ["/bin/bash"]