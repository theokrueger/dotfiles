#!/usr/bin/env bash
# installer for gentoo packages
cd "$(dirname "$0")"
set -euxo pipefail

doas python3 ./gentoo/render.py
doas emaint sync -A
doas emerge --update --changed-use --deep --with-beps=y @world
