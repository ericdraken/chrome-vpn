#!/usr/bin/with-contenv bash
set -e

echo "Restarting VPN service"
# See: https://skarnet.org/software/s6/s6-svc.html
s6-svc -r /var/run/s6/services/openvpn

exit 0
