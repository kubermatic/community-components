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


ARG BASE_IMAGE=quay.io/kubermatic-labs/kubeone-tooling
ARG BASE_TAG=latest

# Main image
FROM ${BASE_IMAGE}:${BASE_TAG}

ARG USER=kubermatic
ARG USER_HOME=/home/${USER}
ARG BIN_ARCH=linux-amd64
ARG KKP_VERSION=TBD
LABEL KUBEONE_VERSION=${BASE_TAG}
LABEL KKP_VERSION=${KKP_VERSION}
LABEL KUBEV_VERSION=${KUBEV_VERSION}

ENV USER_HOME=$USER_HOME
ENV HOME=$USER_HOME

USER 0
COPY .local/bin/kubermatic-virtualization /usr/bin/kubermatic-virtualization

RUN chmod a+rx /usr/bin/kubermatic-virtualization && \
      echo 'source <(kubermatic-virtualization completion bash)' >> /root/.bashrc && \
      echo 'kubermatic-virtualization version' >> /root/.bashrc && \
      echo 'kubermatic-virtualization version' >> $USER_HOME/.bashrc

RUN mkdir -p /tmp/${KKP_VERSION} && \
      wget https://github.com/kubermatic/kubermatic/releases/download/${KKP_VERSION}/kubermatic-ee-${KKP_VERSION}-${BIN_ARCH}.tar.gz -O- | tar -xz --directory /tmp/${KKP_VERSION}/ && \
      mv /tmp/${KKP_VERSION}/kubermatic-installer /bin/kubermatic-installer && \
      chmod +x /bin/kubermatic-installer && \
      rm -rf /tmp/${KKP_VERSION} && \
      kubermatic-installer --version && \
      echo 'figlet KKP '${KKP_VERSION}' | /usr/games/lolcat' >> /root/.bashrc && \
      echo 'figlet KKP '${KKP_VERSION}' | /usr/games/lolcat' >> $USER_HOME/.bashrc

USER ${USER}

## tail to enable to run in backend
#CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
