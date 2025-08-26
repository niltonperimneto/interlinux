#!/bin/bash
# This script sets fish as the default shell for new users
set -euxo pipefail
echo -e '#!/bin/sh\nexport VISUAL=micro\nexport EDITOR="$VISUAL"' > /etc/profile.d/default-editor.sh