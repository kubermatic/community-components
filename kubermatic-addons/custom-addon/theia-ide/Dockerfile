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
    apt-get install -y kubectl helm && \
    apt-get clean

#install kubernetes plugin
RUN curl -Ls https://open-vsx.org/api/ms-kubernetes-tools/vscode-kubernetes-tools/1.2.1/file/ms-kubernetes-tools.vscode-kubernetes-tools-1.2.1.vsix -o vs-kubernetes.vsix && \
    mkdir plugins/vscode-kubernetes-tools && cd plugins/vscode-kubernetes-tools && \
    unzip ../../vs-kubernetes.vsix && \
    cd ../.. && rm vs-kubernetes.vsix && \
    sed -i "`head -n -2 package.json | wc -l`i\\"'        "vscode-kubernetes-tools": "https://open-vsx.org/api/ms-kubernetes-tools/vscode-kubernetes-tools/1.2.1/file/ms-kubernetes-tools.vscode-kubernetes-tools-1.2.1.vsix",'"\\" package.json && \
    cat package.json

#RUN yarn --pure-lockfile && \
#    NODE_OPTIONS="--max_old_space_size=4096" yarn theia build && \
#    yarn theia download:plugins && \
#    yarn --production && \
#    yarn autoclean --init && \
#    echo *.ts >> .yarnclean && \
#    echo *.ts.map >> .yarnclean && \
#    echo *.spec.* >> .yarnclean && \
#    yarn autoclean --force && \
#    yarn cache clean

USER theia