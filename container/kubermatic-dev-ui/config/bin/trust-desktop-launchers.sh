#!/usr/bin/env bash
# Mark every ~/Desktop/*.desktop launcher "trusted" for XFCE 4.17+.
#
# XFCE 4.17+ (libxfce4util) refuses to launch a .desktop file from the desktop / file
# manager unless the GVfs metadata attribute "metadata::xfce-exe-checksum" equals the
# SHA-256 of the file contents; otherwise Thunar shows the "Untrusted application
# launcher" dialog. The launchers are baked into the image without that marker, so we
# set it here. This MUST run inside the live session (it needs D-Bus + gvfsd-metadata),
# which is why it is wired via XFCE autostart rather than at image build time.
shopt -s nullglob
for f in "$HOME"/Desktop/*.desktop; do
    gio set "$f" metadata::xfce-exe-checksum "$(sha256sum "$f" | cut -d' ' -f1)" 2>/dev/null || true
done