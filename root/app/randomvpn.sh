#!/usr/bin/with-contenv bash

# Restart the VPN server with a random server,
# wait until it is up and working, then return
# 'ok' or 'failed' if unsuccessful
# Author: Eric Draken

/app/reconnect.sh >/dev/null || (
  echo 'failed'
  exit 1
)
sleep 4

for ((c = 0; c <= 10; c++)); do
  service openvpn status &&
    curl \
      --connect-timeout 2 \
      --max-time 5 \
      --head \
      --fail \
      --silent \
      --output /dev/null \
      $TEST_URL 2>/dev/null &&
      echo 'ok' && exit 0

      sleep 2
done

echo 'failed'
exit 1