#!/usr/bin/with-contenv bash

if [[ ! -z $PACKETS_LIMIT_PER_VPN ]]; then
  # Get the current packet count on the tun0 interface
  packet_count="$(exec /app/randomizer/reqcount.sh)"

  if (( packet_count >= PACKETS_LIMIT_PER_VPN )); then

    echo "Randomizing the VPN..."
    iptables -Z
    s6-svc -t /var/run/s6/services/openvpn

  fi
fi

