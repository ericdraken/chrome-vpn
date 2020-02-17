/*
 * Copyright (c) 2020. Eric Draken - ericdraken.com
 */
'use strict';
const {getRandomVPNConfig, downloadOVPNFiles} = require('./utils');
const openVpnManager = require('node-openvpn');
const childProcess = require('child_process');
const process = require('process');
const axios = require('axios');

const apiUrl = process.env.URL_NORDVPN_API;
const category = process.env.CATEGORY;
const countries = process.env.COUNTRIES;
const maxLoad = parseInt(process.env.MAX_LOAD, 10);
const ovpnUrl = process.env.URL_OVPN_FILES;
const authFile = process.env.AUTH_FILE;
const vpnOpts = process.env.OPENVPN_OPTS;
const protocol = "openvpn_udp"; // Hard-coded only!

//////////////

let ovpnFolder = "/ovpn";
// For Windows and testing
if (process.platform === "win32")
    ovpnFolder = `${__dirname}${ovpnFolder}`;

const management = {
    host: "127.0.0.1",
    port: 1337
};

downloadOVPNFiles(ovpnUrl, ovpnFolder)
    .then(() => {
        return getRandomVPNConfig(apiUrl, countries, protocol, category, maxLoad, ovpnFolder);
    })
    .then((ovpn) => {
        const args = [
            '--management', management.host, management.port,
            '--config', ovpn,
            '--script-security', 2,
            '--cd', ovpnFolder,
            '--auth-user-pass', authFile,
            '--auth-nocache',
            '--management-hold',
            '--daemon',
            '--dev',
            'tun0'
        ];

        if (!!vpnOpts && vpnOpts.length > 3)
            args.push(vpnOpts);

        // Close any running OpenVPN daemon processes
        try {
            childProcess.execSync('pkill openvpn');
            console.log("Terminated existing OpenVPN daemon");
        } catch (e) {
        }

        // This will throw an error if the exit code is non-zero
        childProcess.execFileSync('openvpn', args);
    })
    .then(async () => {
        await new Promise(resolve => setTimeout(resolve, 2000));
        const mgr = openVpnManager.connect({host: management.host, port: management.port});
        mgr
            .on('connected', function () {
                console.log("VPN management established")
            })
            .on('console-output', output => {
                console.log(output)
            })
            .on('state-change', state => {
                console.log("State: " + state);
                if (/CONNECTED,SUCCESS/g.test(state)) {
                    axios.get("https://ipinfo.io/",  { responseType: 'json' })
                        .then((response) => {
                            console.log(`VPN IP information:\n${response.data}\n`);
                        })
                        .catch((error) => {
                            console.error(`VPN IP error: ${error}`);
                        });
                }
            })
            .on('error', error => {
                console.log("Error: " + error)
            })
            .on('disconnected', () => {
                // finally destroy the disconnected manager
                console.log("VPM management disconnected");
                mgr.destroy()
            });
    })
    .then(() => {

        console.log("Setting up signal handlers");
        process.on('exit', function () {
            console.log('VPN process terminated.');
        });

        process.on('SIGTERM', function () {
            console.log('Got SIGTERM. Trying to stop VPN server gracefully.');
            openVpnManager.disconnect()
                .then(() => {
                    openVpnManager.destroy();
                    console.log("VPN server stopped.");
                })
                .catch((error) => {
                    console.log(error);
                });
        });

    })
    .catch((error) => {
        console.log(error);
    });

