#!/usr/bin/with-contenv bash

# Restart the VPN server with a random server,
# wait until it is up and working, then return
# 'ok' or 'failed' if unsuccessful
# Author: Eric Draken

/app/reconnect.sh >/dev/null || (echo 'failed'; exit 1)
sleep 4

i=0
m=10

until (
  service openvpn status &&
    curl \
      --connect-timeout 2 \
      --max-time 5 \
      --head \
      --fail \
      --silent \
      --output /dev/null \
      $TEST_URL 2>/dev/null
); do
  if [ ${i} -eq ${m} ]; then
    echo 'failed'
    exit 1
  fi
  ((i++))
  sleep 2
done
echo 'ok'
exit 0
