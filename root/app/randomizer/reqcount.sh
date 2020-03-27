#!/usr/bin/env bash

iptables -L INPUT -vxn | grep -m 1 LOG | grep -Eo '^\s*[0-9]{1,6}' | tr -d ' '