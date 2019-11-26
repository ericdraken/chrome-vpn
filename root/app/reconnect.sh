#!/usr/bin/with-contenv bash

echo "Restarting VPN service"
# See: https://skarnet.org/software/s6/s6-svc.html
s6-svc -r /var/run/s6/services/nordvpnd

exit 0
