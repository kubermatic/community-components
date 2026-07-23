#!/usr/bin/env bash
# Configure/repair third-party APT repositories for the kubermatic-dev-ui
# container. Invoked once from the Dockerfile before the main `apt-get install`
# pass, and (unlike the kubeone-tool base) before the first `apt-get update`,
# because the broken repo below makes `apt-get update` fail until it is removed.
#
# The dev-ui base (Debian bullseye, built 2024) ships a now-dead Helm apt repo
# on baltocdn that makes any "apt-get update" fail ("repository no longer
# signed"). Remove it -- Helm moved off baltocdn long ago, so it is dead weight
# anyway. This file is also the home for any future third-party repo additions.

set -euo pipefail

# Drop the dead Helm/baltocdn repo so apt-get update succeeds. grep exits 1 when
# nothing matches; `|| true` keeps that from aborting the script under `set -e`.
rm -f /etc/apt/sources.list.d/helm-stable-debian.list
grep -rlZ baltocdn /etc/apt /etc/apt/sources.list.d 2>/dev/null | xargs -0 -r rm -f || true
