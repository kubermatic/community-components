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


ARG ARCH=amd64
ARG BASE_IMAGE=ubuntu:20.04
FROM ${ARCH}/${BASE_IMAGE}

ENV GO111MODULE on
# Install KubeOne
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y\
        bash-completion \
        python3-crcmod \
        ca-certificates \
        curl \
        apt-transport-https \
        lsb-release \
        gnupg \
        unzip \
        upx-ucl \
        openssh-server \
        sudo \
        vim \
        make \
        git-crypt \
        git \
        fonts-powerline \
        tmux \
        software-properties-common \
        iputils-ping \
        locate \
        netcat \
        dnsutils\
        zsh \
        uuid-runtime \
        && apt-get clean


RUN wget --no-check-certificate -qO -  https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

RUN apt-get update && apt-get install -y \
    terraform \
    && apt-get clean

RUN terraform -install-autocomplete

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

# Install govc
RUN curl -L $(curl -s https://api.github.com/repos/vmware/govmomi/releases/latest | grep browser_download_url | grep -i govc_linux_x86 | cut -d '"' -f 4) | tar -xvz govc && mv govc /usr/local/bin && \
    chmod +x /usr/local/bin/govc

# Install Kubectl & Helm & and fubectl depedencies
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    #helm
    curl -s https://baltocdn.com/helm/signing.asc | sudo apt-key add - && \
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee  -a /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt-get update && \
    apt-get install -y kubectl helm jq && \
    apt-get clean

# Install Yq
RUN RELEASE_URL=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/mikefarah/yq/releases/latest) && \
 YQ_LATEST="${RELEASE_URL##*/}" && \
 wget https://github.com/mikefarah/yq/releases/download/$YQ_LATEST/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# Install velero
RUN mkdir /tmp/velero-inst && cd /tmp/velero-inst \
    && curl -L $(curl -s https://api.github.com/repos/vmware-tanzu/velero/releases/latest | grep browser_download_url | grep -i linux-amd64 | cut -d '"' -f 4) | tar --strip 1 -xzf - \
    && mv velero /usr/bin && cd \
    && velero version --client-only

# Install KubeOne
ARG kubeone_version
RUN VERSION=$kubeone_version && \
 curl -LO "https://github.com/kubermatic/kubeone/releases/download/v${VERSION}/kubeone_${VERSION}_linux_amd64.zip" && \
 unzip kubeone_${VERSION}_linux_amd64.zip -d kubeone_${VERSION}_linux_amd64 && \
 mv kubeone_${VERSION}_linux_amd64/kubeone /usr/local/bin

# Install kustomize
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash && \
 mv kustomize /usr/local/bin

# Install Sops
RUN SOPS_VERSION=$(curl -w '%{url_effective}' -I -L -s -S https://github.com/mozilla/sops/releases/latest -o /dev/null | sed -e 's|.*/v||') && \
 curl -LO https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux && \
 install -o root -g root -m 0755 sops-v${SOPS_VERSION}.linux /usr/local/bin/sops

# Install k9s
RUN K9S_RELEASE_URL=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/derailed/k9s/releases/latest) && \
 K9S_LATEST="${K9S_RELEASE_URL##*/}" && \
 wget -c "https://github.com/derailed/k9s/releases/download/${K9S_LATEST}/k9s_Linux_x86_64.tar.gz"  -O - | tar -xz -C /usr/local/bin/

# Install LazyGit
RUN LAZYGIT_VERSION=v0.34 && \
    mkdir /tmp/lazygit-inst && cd /tmp/lazygit-inst && \
    curl -sL https://github.com/jesseduffield/lazygit/releases/download/v0.34/lazygit_0.34_Linux_x86_64.tar.gz | tar -xvz && \
    mv lazygit /usr/local/bin && \
    cd .. && rm -rf /tmp/lazygit-inst

# Install fzf manually since apt-get install does not install bash completion
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install

# Install zsh, oh-my-zsh, powerlevel10k
COPY .zshrc /root/
COPY .p10k.zsh /root/
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    git clone --depth=1 https://github.com/kubermatic/fubectl.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fubectl

COPY .bashrc /root/

ARG USER=kubermatic
RUN useradd -rm -d /home/${USER} -s /bin/bash -g root -G sudo -u 1000 ${USER}
USER ${USER}
WORKDIR /home/${USER}

### INSTALL helper
RUN mkdir /home/${USER}/bin && cd /home/${USER}/bin && \
    # krew
    set -x; cd "$(mktemp -d)" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz" && \
    tar -zxvf krew*.tar.gz && \
    KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/')" && \
    "$KREW" install krew && \
    rm -rf * && \
    # fubctl
    wget https://rawgit.com/kubermatic/fubectl/master/fubectl.source -O /home/${USER}/bin/fubectl.source && \
    # powerline go
    wget https://github.com/justjanne/powerline-go/releases/latest/download/powerline-go-linux-amd64 -O /home/${USER}/bin/powerline-go && \
    chmod +x /home/${USER}/bin/powerline-go
COPY .bashrc /home/${USER}/

# Install minio Operator Kubectl krew plugin
RUN bash -ic 'kubectl krew install minio'

# Install fubectl dependencies
RUN bash -ic 'kinstall'

### Init terrafrom poviders to cache provider binaries for offline setups
COPY terraform_libraries.tf .
RUN terraform init -input=false && \
    mkdir -p $HOME/.terraform.d/plugins/linux_amd64 && \
    mv .terraform/providers $HOME/.terraform.d/plugins/linux_amd64/
ENV TF_CLI_ARGS_init="-plugin-dir /home/${USER}/.terraform.d/plugins/linux_amd64/providers"

##only if you start ssh on demand
EXPOSE 22

SHELL ["/bin/bash", "-ic"]
### tail to enable to run in backend
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
