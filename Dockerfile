FROM browserless/chrome:latest
LABEL maintainer="ericdraken@gmail.com"
LABEL repo="https://github.com/ericdraken/chrome-vpn"

WORKDIR "/"

# Switch back to root
# Then in entrypoint call `su -p - blessuser ...`
USER root

ENV URL_NORDVPN_API="https://api.nordvpn.com/server" \
    URL_RECOMMENDED_SERVERS="https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations" \
    URL_OVPN_FILES="https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip" \
    PROTOCOL=openvpn_udp \
    MAX_LOAD=70 \
    RANDOM_TOP=0 \
    OPENVPN_OPTS=""

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/s6-overlay.tar.gz

RUN apt-get -qq update && \
    apt-get -y -qq install bash curl unzip tar iptables jq openvpn cron && \
    tar xfz /tmp/s6-overlay.tar.gz -C / && \
    mkdir -p /vpn && \
    mkdir -p /ovpn && \
    apt-get -qq clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY root/ /

RUN chmod +x /app/*

VOLUME ["/ovpn"]

# Expose the web-socket and HTTP ports
EXPOSE 3000

# Health check by trying to connect to GitHub with timeouts.
# All network activity must got through the VPN, so if TUN
# is down, then no network and the health check will fail.
HEALTHCHECK --start-period=10s --interval=60s --retries=3 CMD curl \
				--connect-timeout 10 \
				--max-time 20 \
				--head \
				--fail \
				--silent \
				--show-error \
				--output /dev/null \
				'https://github.com/' || exit 1

ENTRYPOINT ["/init"]