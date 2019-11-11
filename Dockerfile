FROM browserless/chrome:latest
LABEL maintainer="ericdraken@gmail.com"
LABEL repo="https://github.com/ericdraken/chrome-vpn"

WORKDIR "/"

# Image browserless/chrome drops the user to restricted user `blessuser`.
# Switch back to root then in the Chrome service call `su -p - blessuser ...`
USER root

# The following is a modified build script from azinchen/nordvpn
# but modified for the Ubuntu base image instead of Alpine
ENV URL_NORDVPN_API="https://api.nordvpn.com/server" \
    URL_RECOMMENDED_SERVERS="https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations" \
    URL_OVPN_FILES="https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip" \
    PROTOCOL=openvpn_udp \
    MAX_LOAD=70 \
    RANDOM_TOP=0 \
    OPENVPN_OPTS=""

# Install Ubuntu packages
RUN apt-get -qq update && \
    apt-get -y -qq install bash curl unzip tar iptables jq openvpn cron && \
    apt-get -qq clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Make folders to hold VPN config information
RUN mkdir -p /vpn && \
    mkdir -p /ovpn

# Get the s6 process supervisor
ARG S6_FILE=s6-overlay-amd64.tar.gz
ARG S6_VERSION=v1.22.1.0
ADD https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/$S6_FILE /tmp/

# Verify the s6 file signature
ADD https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/$S6_FILE.sig /tmp/
ADD https://keybase.io/justcontainers/key.asc /tmp/
RUN gpg --import /tmp/key.asc 2>&1
RUN gpg --verify /tmp/$S6_FILE.sig /tmp/$S6_FILE 2>&1
RUN tar xfz /tmp/$S6_FILE -C /

COPY root/ /

RUN chmod +x /app/*

# Reuse a volume to prevent downloading VPN configs over and over again
VOLUME ["/ovpn"]

# Expose the web-socket and HTTP ports
EXPOSE 3000

# Health check by trying to connect to GitHub with timeouts.
# All network activity must go through the VPN, so if TUN
# is down, then no network and the health check fails.
HEALTHCHECK --start-period=10s --interval=60s --retries=3 CMD curl \
				--connect-timeout 10 \
				--max-time 20 \
				--head \
				--fail \
				--silent \
				--show-error \
				--output /dev/null \
				'https://github.com/' || exit 1

# Using the S6 supervisor
ENTRYPOINT ["/init"]