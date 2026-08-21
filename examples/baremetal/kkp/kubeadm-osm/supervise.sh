#!/bin/bash
set -xeuo pipefail
while ! "$@"; do
    sleep 1
done
