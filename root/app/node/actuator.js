/*
 * Copyright (c) 2019. Eric Draken - ericdraken.com
 */

const express = require('express');
const basicAuth = require('express-basic-auth');
const process = require('process');
const child = require('child_process');
const app = express();

const usedVPNsFile = process.env.USED_VPNS_FILE;

const endpoints = {
    // Connection speed tests
    speedtestraw: '/speedtest-raw',
    speedtest: '/speedtest',

    // VPN randomization and usage
    randomvpn: '/randomvpn',
    usedvpns: '/usedvpns',
    clearvpns: '/clearvpns',

    // Health and status
    health: '/health', // HEAD
    up: '/up',
    status: '/status',

    // VPN IP info
    ip: '/ip',
    ipinfo: '/ipinfo',
    region: '/region',

    // Packet counter and set randomization trigger
    packets: '/packets',

    // Misc
    zygotes: '/zygotes',
    shutdown: '/shutdown'
};

const server = app.listen(8080, () => console.log('Actuators running...'));

app.get('/', function (req, res) {
    res.writeHead(200, {"Content-Type": "text/plain"});
    res.end(`Use one of these endpoints: ${Object.values(endpoints).join(', ')}\n`);
});

// Get the raw speedtest output
app.get(endpoints.speedtestraw, async (req, res) => {
    res.writeHead(200, {"Content-Type": "text/plain"});
    await shellcmd('speedtest-cli --timeout 10 --no-upload --bytes --single' , res);
});

// Get the raw speedtest output
app.get(endpoints.speedtest, async (req, res) => {
    res.writeHead(200, {"Content-Type": "text/json"});
    await shellcmd('speedtest-cli --timeout 10 --no-upload --json || echo \'{}\'' , res);
});

// Get the VPN service status, up = 1, down = 0
app.get(endpoints.zygotes, async (req, res) => {
    res.writeHead(200, {"Content-Type": "text/plain"});
    await shellcmd('ps -axef | grep "[c]hrom.*pinch" | wc -l' , res);
});

// Get the VPN service status, up = 1, down = 0
app.get(endpoints.status, async (req, res) => {
    res.writeHead(200, {"Content-Type": "text/plain"});
    await shellcmd('service openvpn status ; echo $(($? == 0))', res);
});

// Get the used VPNs
app.get(endpoints.usedvpns, async (req, res) => {
    res.writeHead(200, {"Content-Type": "text/plain"});
    await shellcmd(`sed -E 's/\\|/ /g' ${usedVPNsFile} && echo ""`, res); // e.g. a|b|c --> a b c
});

// Clear the used VPNs list
app.get(endpoints.clearvpns, async (req, res) => {
    res.writeHead(200, {"Content-Type": "text/plain"});
    await shellcmd(`echo "" > ${usedVPNsFile} && echo "ok"`, res);
});

// Get the VPN service status and return 200 or 500
app.head(endpoints.health, async (req, res) => {
    await child.exec(
        'service openvpn status >/dev/null',
        function (err, stdout, stderr) {
        res.status( !!err ? 500 : 200 ).end();
    })
});

// Get the VPN connectivity status, up = 1, down = 0
app.get(endpoints.up, async (req, res) => {
    res.writeHead(200, {"Content-Type": "text/plain"});
    await shellcmd('' +
        'curl ' +
        '--connect-timeout 20 ' +
        '--max-time 30 ' +
        '--head ' +
        '--fail ' +
        '--silent ' +
        '--output /dev/null ' +
        '$TEST_URL 2>/dev/null ; echo $(($? == 0))', res);
});

// Get the current VPN exit IP
app.get(endpoints.ip, async (req, res) => {
    res.writeHead(200, {"Content-Type": "text/plain"});
    await shellcmd('' +
        'curl ' +
        '--connect-timeout 5 ' +
        '--max-time 10 ' +
        'http://ipinfo.io/ip', res);
});

// Get the current VPN exit IP
app.get(endpoints.ipinfo, async (req, res) => {
    res.writeHead(200, {"Content-Type": "text/plain"});
    await shellcmd('' +
        'curl ' +
        '--connect-timeout 5 ' +
        '--max-time 10 ' +
        'http://ipinfo.io/ ' +
        '&& echo ""', res);
});

// Get the current VPN region (province or state)
app.get(endpoints.region, async (req, res) => {
    res.writeHead(200, {"Content-Type": "text/plain"});
    await shellcmd('' +
        'curl ' +
        '--connect-timeout 5 ' +
        '--max-time 10 ' +
        'http://ipinfo.io/region ' +
        '&& echo ""', res);
});

// Restart the VPN client to pick up a new endpoint
// app.get('/randomvpn', auth, async (req, res) => {
app.get(endpoints.randomvpn, (req, res) => {
    // Clear the iptables packet counters
    child.execSync('iptables -Z && s6-svc -t /var/run/s6/services/openvpn');
    let newIP = '';
    const max = 5;
    let lastErr = false;
    for (let i = 0; i < max; i++) {
        console.log("Actuator trying to get the new IP...");
        try {
            newIP = child.execSync('' +
                'sleep 2 && ' +
                'curl ' +
                '-s ' +
                '--connect-timeout 10 ' +
                '--max-time 20 ' +
                'http://ipinfo.io/ip', {timeout: 30000}).toString();

            console.log(`Actuator got new IP: ${newIP}`);
            res.writeHead(200, {"Content-Type": "text/plain"});
            res.end(newIP);
            return;
        } catch (err) {
            lastErr = err;
        }
    }
    res.writeHead(500, {"Content-Type": "text/plain"});
    res.end(`Restarted VPN but couldn't get a new IP. Error: ${lastErr.toString()}`);
});

// Get the number of tun0 packets through the VPN
app.get(endpoints.packets, (req, res) => {
    try {
        let count = child.execSync('exec /app/randomizer/reqcount.sh');
        count = count.toString().trim();
        console.log(`Tun0 packet count: ${count}`);
        res.writeHead(200, {"Content-Type": "text/plain"});
        res.end(count);
    } catch (e) {
        res.writeHead(500, {"Content-Type": "text/plain"});
        res.end(`Couldn't get packet count. Error: ${e.toString()}`);
    }
});

// Kill the container completely
// app.get('/shutdown', auth, (req, res) => {
app.get(endpoints.shutdown, (req, res) => {
    res.writeHead(200, {"Content-Type": "text/plain"});
    res.end('ok');
    console.log( "\n\n**** Container shutting down now ****\n\n" );
    // Shut down the actuator, which will trigger a finish script
    // which will terminate the container
    shutDown('SIGTERM');
});

// Handle 404
app.use(function (req, res) {
    res.status(404).send("404: Route not Found\n");
});

// Handle 500
app.use(function (error, req, res, next) {
    res.status(500).send("500: Internal Server Error\n");
});

process.on('SIGTERM', shutDown);
process.on('SIGINT', shutDown);

/// Helpers ///

function shutDown(signal) {
    console.log(`Got ${signal}. Trying to exit gracefully.`);
    server.close(() => {
        console.log("Express server closed. Asking process to exit.");
        process.exit(0)
    });

    setTimeout(() => {
        console.error('Could not close the actuator in time. Forcefully shutting down.');
        process.exit(1);
    }, 10000);
}

async function shellcmd(cmd, res) {
    await child.exec(cmd, function (err, stdout, stderr) {
        if (err) {
            console.log("\n" + stderr);
            res.end(stderr);
        } else {
            console.log("Shell command response: " + stdout);
            res.end(stdout);
        }
    });
}

function auth() {
    return basicAuth({
        users: {admin: !!process.env.ACTUATOR_PASS ? process.env.ACTUATOR_PASS : 'admin'},
        challenge: true,
        unauthorizedResponse: (req) => {
            return 'Unauthorized';
        }
    });
}
