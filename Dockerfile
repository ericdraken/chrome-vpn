FROM ericdraken/browserless-chrome:armv7
LABEL maintainer="ericdraken@gmail.com"
LABEL repo="https://github.com/ericdraken/chrome-vpn"

# Image browserless/chrome drops the user to restricted user `blessuser`.
# Switch back to root then in the Chrome service call `su -p - blessuser ...`
USER root

WORKDIR "/"

# The following is a modified build script from azinchen/nordvpn
# but modified for the Ubuntu base image instead of Alpine
ENV URL_NORDVPN_API="https://api.nordvpn.com/server" \
    URL_RECOMMENDED_SERVERS="https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations" \
    URL_OVPN_FILES="https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip" \
    PROTOCOL=openvpn_udp \
    MAX_LOAD=70 \
    RANDOM_TOP=20 \
    OPENVPN_OPTS="" \
    MIN_RANDOM_SLEEP=1 \
    MAX_RANDOM_SLEEP=8 \
    TEST_URL="https://1.1.1.1/"

# The s6 process supervisor
ARG S6_FILE=s6-overlay-armhf.tar.gz
ARG S6_VERSION=v1.22.1.0

COPY root/app /app
COPY root/etc /etc

# Remove dumb-init from Chrome
RUN rm -f /usr/local/bin/dumb-init && \
	# Install dependencies
    apt-get -qq update && \
    apt-get -y install bash curl unzip tar iptables jq openvpn cron privoxy openssl && \
    apt-get -qq clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # Create the VPN folders
	mkdir -p /vpn && \
    mkdir -p /ovpn && \
    # Download the S6 supervisor
    wget https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/$S6_FILE -O /tmp/$S6_FILE && \
    wget https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/$S6_FILE.sig -O /tmp/$S6_FILE.sig && \
    wget https://keybase.io/justcontainers/key.asc -O /tmp/key.asc && \
    # Verify the S6 signature
    gpg --import /tmp/key.asc 2>&1 && \
	gpg --verify /tmp/$S6_FILE.sig /tmp/$S6_FILE 2>&1 && \
	tar xfz /tmp/$S6_FILE -C / && \
	chmod +x /app/* && \
	# Install the Node.js actuators
	npm --prefix /app/actuator install && \
	# Install the speedtest package
	pip3 install speedtest-cli

# Reuse a volume to prevent downloading VPN configs over and over again
VOLUME ["/ovpn"]

# Expose the web-socket, HTTP ports, and proxy ports
EXPOSE 3000/tcp
EXPOSE 3001/tcp

# Health check by trying to connect to GitHub with timeouts.
# All network activity must go through the VPN, so if TUN
# is down, then no network and the health check fails.
HEALTHCHECK --start-period=10s --interval=20s --retries=3 CMD curl \
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