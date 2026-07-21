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
# All APT-managed software is installed in a single transaction to keep the
# image small and the build fast:
#   1. Repair APT sources from apt-sources.sh -- the dev-ui base ships a dead
#      Helm/baltocdn repo that makes apt-get update fail, so this must run first.
#   2. Bootstrap just enough to reach HTTPS-protected repos.
#   3. Install the full package list from apt-packages.txt.
# Package list and repository setup live in their own files (see those for
# what each entry is for and why each repo is needed).
COPY apt-packages.txt apt-sources.sh /tmp/
RUN bash /tmp/apt-sources.sh && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg lsb-release \
        apt-transport-https software-properties-common && \
    sed 's/#.*$//' /tmp/apt-packages.txt | xargs apt-get install -y --no-install-recommends && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/apt-packages.txt /tmp/apt-sources.sh

### VS Code
RUN  mkdir -p /apps/vscode/ && \
     wget -c "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"  -O - | tar -xz -C /apps/vscode/
RUN echo '/apps/vscode/VSCode-linux-x64/bin/code --no-sandbox --user-data-dir /headless/vscode-user-data $?' > /usr/local/bin/code && \
    chmod +x /usr/local/bin/code
RUN /usr/local/bin/code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools

COPY config/terminator/config /headless/.config/terminator/config
COPY config/terminator/config /root/.config/terminator/config

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
