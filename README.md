# Chrome+VPN

A combination of headless Chrome and a VPN to force all Chrome traffic through the tunnel adapter. No more WebRTC leaks.
This image allows the VPN server to change at regular intervals, and choose a specific country to use VPN servers from.

## NordVPN

From [azinchen/nordvpn](https://github.com/azinchen/nordvpn): This is an OpenVPN client docker container that use least loaded NordVPN servers. It makes routing containers' traffic through OpenVPN easy.

## Headless Chrome

From [browserless/chrome](https://github.com/browserless/chrome): If you've been struggling to get Chrome up and running docker, or scaling out your headless workloads, then browserless was built for you.

## How it works

browserless listens for both incoming websocket requests, generally issued by most libraries, as well as pre-build REST APIs to do common functions (PDF generation, images and so on). When a websocket connects to browserless it invokes Chrome and proxies your request into it. Once the session is done then it closes and awaits for more connections. Some libraries use Chrome's HTTP endpoints, like `/json` to inspect debug-able targets, which browserless also supports.

Your application still runs the script itself (much like a database interaction), which gives you total control over what library you want to choose and when to do upgrades. This is preferable over other solutions as Chrome is still breaking their debugging protocol quite frequently.
Excellent details are at the maintainer's repo: [browserless/chrome](https://github.com/browserless/chrome)

![Browserless Debugger](https://raw.githubusercontent.com/ericdraken/chrome-vpn/master/demo.gif)

## Environment variables

Container images are configured using environment variables passed at runtime.

 * `USE_CHROME_STABLE` - Use 'true' to use only the latest stable Chrome release
 * `COUNTRY`           - Use servers from countries in the list (IE Australia;New Zeland). Several countries can be selected using semicolon.
 * `CATEGORY`          - Use servers from specific categories (IE P2P;Anti DDoS). Several categories can be selected using semicolon. Allowed categories are:
   * `Dedicated IP`
   * `Double VPN`
   * `P2P`
   * `Standard VPN servers`
 * `RANDOM_TOP`        - Place n servers from filtered list in random order. Useful with `RECREATE_VPN_CRON`.
 * `VPN_USER`          - User for NordVPN account.
 * `VPN_PASS`          - Password for NordVPN account.
 * `NETWORK`           - CIDR network (IE 192.168.1.0/24), add a route to allows replies once the VPN is up.
 * `NETWORK6`          - CIDR IPv6 network (IE fe00:d34d:b33f::/64), add a route to allows replies once the VPN is up.
 * `OPENVPN_OPTS`      - Used to pass extra parameters to openvpn [full list](https://openvpn.net/community-resources/reference-manual-for-openvpn-2-4/).
 * `TZ`                - Timezone string to use in the Docker container.
 * `TEST_URL`          - URL for the health checks and testing VPN connectivity.

## Environment variable's keywords

The list of keywords for environment variables might be changed, check the allowed keywords by the following commands:

`COUNTRY`
```
curl -s https://api.nordvpn.com/server | jq -c '.[] | .country' | jq -s -a -c 'unique | .[]'
```

`CATEGORY`
```
curl -s https://api.nordvpn.com/server | jq -c '.[] | .categories[].name' | jq -s -a -c 'unique | .[]'
```

## Easy Setup

Copy the `env/chrome-vpn.env.tmpl` file to `env/chrome-vpn.env`, and `env/password.env.tmpl` file to `env/password.env`, and populate. Then run `docker-compose up`. Navigate to `http://localhost:3000` to
be treated to the Chrome debugger playground. If you need to bypass Chrome, you can use port 3001 as the proxy port.

```yaml
version: '3.5'

services:
  chrome-vpn:
    image: ericdraken/chrome-vpn:armv7
    restart: unless-stopped
    cap_add:
      - NET_ADMIN # Needed for VPN tunnel adapter
    ports:
      - "${CHROME_RDP_PORT:-3000}:3000"
      - "${PROXY_PORT:-3001}:3001"
    expose:
      - 8080 # Actuator port
    dns:
      - "${DNS_SERVER_1:-9.9.9.9}"
      - "${DNS_SERVER_2:-1.1.1.1}"
    volumes:
      - ./.chromium.sh:/app/chromium/chromium.sh:ro
      - /dev/shm:/dev/shm # Use shared memory with the host
    tmpfs:
      - /tmp
    env_file:
      - ./env/chrome-vpn.env
      - ./env/password.env
```

## Multiple simultaneous Chrome+VPN instances

Run `docker-compose -f docker-compose-scale[2,3].yaml up` to launch two or three Chrome+VPN instances
at random VPN servers for a round-robin VPN experience. Every time you execute a Chrome navigation, it will originate from
a different VPN server.

## Chrome version

You can query `http://host:port/json/version` to return the contents of `version.json` which contain the Chrome version and default User-Agent string.

## Actuators

You can query these localhost:8080 actuator endpoints for status updates and to restart the VPN client:

* `/status` - Is the VPN client running?
* `/up` - Can the TEST_URL be curled for a 200-response?
* `/health` - Using a HEAD request check if the openvpn server is functioning
* `/ip` - Get the current external IP
* `/ipinfo` - Get the ipinfo.io JSON response
* `/region` - Get the region of the VPN exit node
* `/randomvpn` - Restart the VPN client and wait until `/up` is successful: 'ok' or 'failed'
* `/kill` - Kill the container completely
* `/speedtest` - Get a JSON result of a speedtest.net test

Actuator endpoints are best hit when using the port 3001 proxy into the container rather than directly trying
to bind port 8080 to a host port for security purposes.