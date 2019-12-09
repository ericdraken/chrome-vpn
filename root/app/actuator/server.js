/*
 * Copyright (c) 2019. Eric Draken - ericdraken.com
 */

const express = require('express');
const basicAuth = require('express-basic-auth');
const process = require('process'); // Explicit, because, why not?
const child = require('child_process');
const app = express();

function shellcmd(cmd, res) {
    child.exec(cmd, function (err, stdout, stderr) {
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

app.get('/', function (req, res) {
    res.writeHead(200, {"Content-Type": "text/plain"});
    res.end("Use one of these endpoints: /speedtest, /zygotes, /status, /up, /ip, /ipinfo, /region, /randomvpn, or /kill");
});

// Get the raw speedtest output
app.get('/speedtest-raw', function (req, res) {
    res.writeHead(200, {"Content-Type": "text/plain"});
    shellcmd('speedtest-cli --no-upload --bytes --single' , res);
});

// Get the raw speedtest output
app.get('/speedtest', function (req, res) {
    res.writeHead(200, {"Content-Type": "text/json"});
    shellcmd('speedtest-cli --no-upload --json || echo \'{}\'' , res);
});

// Get the VPN service status, up = 1, down = 0
app.get('/zygotes', function (req, res) {
    res.writeHead(200, {"Content-Type": "text/plain"});
    shellcmd('ps -axef | grep "[c]hrom.*pinch" | wc -l' , res);
});

// Get the VPN service status, up = 1, down = 0
app.get('/status', function (req, res) {
    res.writeHead(200, {"Content-Type": "text/plain"});
    shellcmd('service openvpn status ; echo $(($? == 0))', res);
});

// Get the VPN service status and return 200 or 500
app.head('/health', function (req, res) {
    child.exec('service openvpn status >/dev/null', function (err, stdout, stderr) {
        res.status( !!err ? 500 : 200 ).end();
    })
});

// Get the VPN connectivity status, up = 1, down = 0
app.get('/up', function (req, res) {
    res.writeHead(200, {"Content-Type": "text/plain"});
    shellcmd('' +
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
app.get('/ip', function (req, res) {
    res.writeHead(200, {"Content-Type": "text/plain"});
    shellcmd('curl http://ipinfo.io/ip', res);
});

// Get the current VPN exit IP
app.get('/ipinfo', function (req, res) {
    res.writeHead(200, {"Content-Type": "text/plain"});
    shellcmd('curl http://ipinfo.io/', res);
});

// Get the current VPN region (province or state)
app.get('/region', function (req, res) {
    res.writeHead(200, {"Content-Type": "text/plain"});
    shellcmd('curl http://ipinfo.io/region', res);
});

// Restart the VPN client to pick up a new endpoint
app.get('/randomvpn', auth, function (req, res) {
    res.writeHead(200, {"Content-Type": "text/plain"});
    shellcmd('/app/randomvpn.sh', res);
});

// Kill the container completely
app.get('/kill', auth, function (req, res) {
    res.writeHead(200, {"Content-Type": "text/plain"});
    res.end('ok');
    child.exec('s6-svscanctl -t /var/run/s6/services', function (err, stdout, stderr) {
        console.log( !!err ? stderr : stdout);
    });
});

// Handle 404
app.use(function (req, res) {
    res.status(404).send('404: Route not Found');
});

// Handle 500
app.use(function (error, req, res, next) {
    res.status(500).send('500: Internal Server Error');
});

const server = app.listen(8080);

process.on('exit', function () {
    console.log('Got exit event. Trying to stop Express server.');
    app.close(function () {
        console.log("Express server closed");
    });
});

process.on('SIGINT', function () {
    console.log('Got SIGINT. Trying to exit gracefully.');
    server.close(function () {
        console.log("Express server closed. Asking process to exit.");
        process.exit()
    });
});