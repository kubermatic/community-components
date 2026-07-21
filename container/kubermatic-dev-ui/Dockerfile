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
ARG USER_ID=1000

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

# The dev-ui base (Debian bullseye, built 2024) ships a now-dead Helm apt repo on
# baltocdn that makes any "apt-get update" fail ("repository no longer signed").
# Remove it — Helm moved off baltocdn long ago, so it is dead weight anyway.
RUN rm -f /etc/apt/sources.list.d/helm-stable-debian.list; \
    grep -rlZ baltocdn /etc/apt /etc/apt/sources.list.d 2>/dev/null | xargs -0 -r rm -f; \
    true

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
RUN apt update && apt install -y terminator xfce4-terminal && apt clean

COPY config/Desktop/ /headless/Desktop/
COPY config/background/bg_image.png /headless/.config/bg_image.png

# Wire the XFCE "TerminalEmulator" helper so the Terminal desktop icon
# (Exec=exo-open --launch TerminalEmulator) actually launches a terminal. Without
# helpers.rc, exo falls through to x-terminal-emulator (terminator), which is
# unreliable under amd64 emulation; xfce4-terminal (native) launches reliably.
COPY config/xfce4/helpers.rc /headless/.config/xfce4/helpers.rc

# Auto-trust the baked-in ~/Desktop/*.desktop launchers at session start. XFCE 4.17+
# refuses to launch a .desktop file whose metadata::xfce-exe-checksum does not match and
# otherwise shows the "Untrusted application launcher" prompt. Marking them needs a live
# session (D-Bus + gvfsd-metadata), so it runs from autostart, not at build time.
COPY config/bin/trust-desktop-launchers.sh /usr/local/bin/trust-desktop-launchers.sh
COPY config/autostart/trust-desktop-launchers.desktop /headless/.config/autostart/trust-desktop-launchers.desktop
RUN chmod 0755 /usr/local/bin/trust-desktop-launchers.sh

### configure startup
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME

# Drop the stale /tmp/passwd left by the base's non-root build steps (owned by the
# headless uid, mode 644). Otherwise the entrypoint's generate_container_user cannot
# regenerate it (`cat /etc/passwd > /tmp/passwd`) when the container runs as any other
# non-root UID, and startup crash-loops with "Permission denied".
RUN rm -f /tmp/passwd

# Run as the desktop user the kubeone base actually creates: "headless" = UID 1001,
# GID 0. (Was USER 1000, which points at a UID with no /etc/passwd entry and breaks
# non-root startup in this image and anything built on top of it.)
USER ${USER_ID}

### tail to enable to run in backend
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
