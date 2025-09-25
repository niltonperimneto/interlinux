#!/usr/bin/env bash
set -euo pipefail

THEME="${1:-school-bgrt}"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root."
  exit 1
fi

if ! command -v plymouth-set-default-theme >/dev/null 2>&1; then
  echo "plymouth-set-default-theme not found."
  exit 1
fi

plymouth-set-default-theme "$THEME"

echo "Plymouth theme set to '$THEME'. The initramfs will be rebuilt on the user's system."