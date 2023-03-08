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


ARG BASE_IMAGE=quay.io/kubermatic-labs/kubeone-tooling-ui-base:debian-xfce-vnc
FROM ${BASE_IMAGE}

USER 0
### IntelliJ IDEA - Community Edition
#RUN  mkdir -p /apps/idea/ && \
#     wget -c "https://download.jetbrains.com/idea/ideaIC-2022.3.2.tar.gz"  -O - | tar -xz -C /apps/idea/
#     # /usr/local/bin/
#RUN  mkdir -p /apps/download/ && cd /apps/download/ && \
#     wget -c "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -O vscode.deb && \
#     apt install -y ./vscode.deb && \
#     rm -rf /apps/download
#RUN  mkdir -p /apps/vscode-cli/ && \
#     wget -c "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64"  -O - | tar -xz -C /apps/vscode-cli/

RUN  mkdir -p /apps/vscode/ && \
     wget -c "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"  -O - | tar -xz -C /apps/vscode/
RUN echo '/apps/vscode/VSCode-linux-x64/bin/code --no-sandbox --user-data-dir /headless/vscode-user-data $?' > /usr/local/bin/code && \
    chmod +x /usr/local/bin/code
#RUN mkdir -p /apps/vscode-plugins/ && \
#     wget -c "https://open-vsx.org/api/ms-kubernetes-tools/vscode-kubernetes-tools/1.3.11/file/ms-kubernetes-tools.vscode-kubernetes-tools-1.3.11.vsix" -O /apps/vscode-plugins/kubernetes.vsix
RUN #code --install-extension /apps/vscode-plugins/kubernetes.vsix
RUN #code --install-extension /apps/vscode-plugins/kubernetes.vsix
RUN /usr/local/bin/code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools

COPY config/terminator/config /headless/.config/terminator/config
COPY config/terminator/config /root/.config/terminator/config
RUN apt update && apt install -y terminator && apt clean

COPY config/Desktop/ /headless/Desktop/
COPY config/background/bg_image.png /headless/.config/bg_image.png
RUN chmod g+rwx /headless/Desktop/*.desktop
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME

USER 1000

### tail to enable to run in backend
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
