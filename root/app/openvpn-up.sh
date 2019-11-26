#!/usr/bin/env bash
set -e

sh -c "sleep 1; echo 'VPN IP information:'; curl -s -p --max-time 20 https://ipinfo.io/; echo" &