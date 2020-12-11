# https://github.com/theia-ide/theia-apps/blob/master/theia-go-docker/Dockerfile
FROM theiaide/theia-go:next

USER 0
RUN apt-get update && \
    apt-get install -y apt-transport-https gnupg2 curl sudo && \
    # theia as sudo users
    echo "theia ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/theia && \
    #kubectl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    #helm
    curl -s https://baltocdn.com/helm/signing.asc | sudo apt-key add - && \
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee  -a /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt-get update && \
    apt-get install -y kubectl helm jq vim bash-completion fonts-powerline && \
    apt-get clean

USER theia

#install THEIA kubernetes plugin
RUN curl -Ls https://open-vsx.org/api/ms-kubernetes-tools/vscode-kubernetes-tools/1.2.1/file/ms-kubernetes-tools.vscode-kubernetes-tools-1.2.1.vsix -o vs-kubernetes.vsix && \
    mkdir plugins/vscode-kubernetes-tools && cd plugins/vscode-kubernetes-tools && \
    unzip ../../vs-kubernetes.vsix && \
    cd ../.. && rm vs-kubernetes.vsix && \
    sed -i "`head -n -2 package.json | wc -l`i\\"'        "vscode-kubernetes-tools": "https://open-vsx.org/api/ms-kubernetes-tools/vscode-kubernetes-tools/1.2.1/file/ms-kubernetes-tools.vscode-kubernetes-tools-1.2.1.vsix",'"\\" package.json && \
    cat package.json

### INSTALL helper
RUN mkdir /home/theia/bin && cd /home/theia/bin && \
    # fzf
    wget https://github.com/junegunn/fzf/releases/download/0.24.4/fzf-0.24.4-linux_amd64.tar.gz -O- | tar -xz && \
    # krew
    set -x; cd "$(mktemp -d)" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" && \
    tar zxvf krew.tar.gz && \
    KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/')" && \
    "$KREW" install krew && \
    rm -rf * && \
    # fubctl
    wget https://rawgit.com/kubermatic/fubectl/master/fubectl.source -O /home/theia/bin/fubectl.source && \
    # powerline go
    wget https://github.com/justjanne/powerline-go/releases/latest/download/powerline-go-linux-amd64 -O /home/theia/bin/powerline-go && \
    chmod +x /home/theia/bin/powerline-go && \
    # needed to set right font for theia
    mkdir /home/theia/.theia && \
    echo "{\"terminal.integrated.fontFamily\": \"'PowerlineSymbols', 'Droid Sans Mono Slashed', 'monospace', monospace, 'Droid Sans Fallback'\"" \
    > /home/theia/.theia/settings.json

COPY ./.bashrc /home/theia/
# install fubectl depedencies
RUN bash -ic 'kinstall'

