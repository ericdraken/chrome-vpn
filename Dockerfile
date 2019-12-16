FROM ericdraken/browserless-chrome:armv7
LABEL maintainer="ericdraken@gmail.com"
LABEL repo="https://github.com/ericdraken/chrome-vpn"

# Image browserless/chrome drops the user to restricted user `blessuser`.
# Switch back to root then in the Chrome service call `su -p - blessuser ...`
USER root

# Remove dumb-init from Chrome
RUN rm -f /usr/local/bin/dumb-init

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

# Install Ubuntu packages
RUN apt-get -qq update && \
    apt-get -y -qq install bash curl unzip tar iptables jq openvpn cron privoxy openssl

# Make folders to hold VPN config information
RUN mkdir -p /vpn && \
    mkdir -p /ovpn

# Get the s6 process supervisor
ARG S6_FILE=s6-overlay-armhf.tar.gz
ARG S6_VERSION=v1.22.1.0
ADD https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/$S6_FILE /tmp/

# Verify the s6 file signature
ADD https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/$S6_FILE.sig /tmp/
ADD https://keybase.io/justcontainers/key.asc /tmp/
RUN gpg --import /tmp/key.asc 2>&1
RUN gpg --verify /tmp/$S6_FILE.sig /tmp/$S6_FILE 2>&1
RUN tar xfz /tmp/$S6_FILE -C /

# Install squid
# The must match the folders in the squid.conf file
# Note: squid3: libssl1.0-dev, squid4: libssl-dev
ENV SQUID_FILE=squid-4.8.tar.gz \
    SQUID_FOLDER=v4 \
    SQUID_CACHE_DIR=/tmp/squid \
    SQUID_LOG_DIR=/tmp/log/squid \
    SQUID_USER=proxy \
    SQUID_BUILD_DEPS="libssl-dev build-essential libcrypto++-dev pkg-config autoconf g++"

RUN apt-get -y -qq install $SQUID_BUILD_DEPS

ADD http://www.squid-cache.org/Versions/$SQUID_FOLDER/$SQUID_FILE /tmp/
# TODO: Verify the signature
# ADD http://www.squid-cache.org/Versions/$SQUID_FOLDER/$SQUID_FILE.asc /tmp/
# RUN gpg --import /tmp/$SQUID_FILE.asc 2>&1
# RUN gpg --verify /tmp/$SQUID_FILE.sig /tmp/$SQUID_FILE 2>&1
RUN tar xfz /tmp/$SQUID_FILE -C /tmp/
# This will take a very long time to build!
RUN cd /tmp/squid* && \
    ./configure \
        --with-default-user=$SQUID_USER \
        --with-openssl \
        --enable-ssl \
        --enable-ssl-crtd \
        --prefix=/squid && \
    make all && make install

# Cleanup
RUN apt-get -y -qq remove $SQUID_BUILD_DEPS && \
    apt-get -qq clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY root/app /app
COPY root/etc /etc

RUN chmod +x /app/*

# Install the Node actuator
RUN npm --prefix /app/actuator install

# Install speedtest-cli
RUN pip3 install speedtest-cli

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