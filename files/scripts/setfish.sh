#!/bin/bash
# This script sets fish as the default shell for new users
set -euxo pipefail
sed -i 's|^SHELL=.*|SHELL=/usr/bin/fish|' /etc/default/useradd