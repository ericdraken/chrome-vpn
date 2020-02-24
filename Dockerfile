ARG BASE_IMAGE=ericdraken/browserless-chrome:latest

FROM ${BASE_IMAGE}
LABEL maintainer="ericdraken@gmail.com"
LABEL repo="https://github.com/ericdraken/chrome-vpn"

ARG S6_FILE=s6-overlay-amd64.tar.gz
ARG S6_VERSION=v1.22.1.0

# Image browserless/chrome drops the user to restricted user `blessuser`.
# Switch back to root then in the Chrome service call `su -p - blessuser ...`
USER root

WORKDIR "/"

# The following is a modified build script from azinchen/nordvpn
# but modified for the Ubuntu base image instead of Alpine
ENV URL_NORDVPN_API="https://api.nordvpn.com/server" \
    URL_OVPN_FILES="https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip" \
    MAX_LOAD=70 \
    OPENVPN_OPTS="" \
    TEST_URL="https://1.1.1.1/" \
    AUTH_FILE="/vpn/auth" \
    USED_VPNS_FILE="/usedvpns/vpns.txt" \
    MAX_ALLOWED_USED_VPNS=500 \
    CATEGORY="Standard VPN servers" \
    COUNTRIES="Singapore,Mexico"

# Remove dumb-init from Chrome
RUN rm -f /usr/local/bin/dumb-init && \
	# Install dependencies
    apt-get -qq update && \
    apt-get -y install bash curl unzip tar iptables openvpn privoxy openssl jq \
    # Temporary packages
    nano telnet \
    # These are needed for the npm packages:
    git build-essential autoconf libtool
RUN apt-get -qq clean && rm -rf /var/lib/apt/lists/* /var/tmp/*
    # Create the VPN folders
RUN mkdir -p /vpn /ovpn 
    # Download the S6 supervisor
RUN wget -q https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/$S6_FILE -O s6.tar.gz
RUN tar xfz s6.tar.gz
	# Install the speedtest package
RUN pip3 install speedtest-cli

COPY root/app /app
COPY root/etc/cont-init.d /etc/cont-init.d
COPY root/etc/services.d /etc/services.d

RUN chmod +x /app/* && \
	cd /app/node && \
	npm --no-package-lock install

# Reuse a volume to prevent downloading VPN configs over and over again
VOLUME /ovpn
# Track used VPNs
VOLUME /usedvpns

# Ensure the used VPNs file is present
RUN touch $USED_VPNS_FILE

# Expose the web-socket, HTTP ports, and proxy ports
EXPOSE 3000/tcp
EXPOSE 3001/tcp

# Health check by trying to connect to a test URL with timeouts.
# All network activity must go through the VPN, so if TUN
# is down, then no network and the health check fails.
HEALTHCHECK --start-period=10s --interval=20s --retries=5 CMD curl \
				--connect-timeout 5 \
				--max-time 10 \
				--head \
				--fail \
				--silent \
				--show-error \
				--output /dev/null \
				$TEST_URL || exit 1

# Using the S6 supervisor
ENTRYPOINT ["/init"]