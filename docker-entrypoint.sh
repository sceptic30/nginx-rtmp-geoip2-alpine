#!/bin/bash
set -euo pipefail
echo -e "$(hostname -i) $(hostname)\n$(hostname -i) $(hostname).localhost" >> /etc/hosts
exec "$@"