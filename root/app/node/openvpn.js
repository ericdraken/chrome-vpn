/*
 * Copyright (c) 2020. Eric Draken - ericdraken.com
 */
'use strict';
const {getRandomVPNConfig, downloadOVPNFiles} = require('./utils');
const openVpnManager = require('node-openvpn');
const childProcess = require('child_process');
const process = require('process');
const axios = require('axios');
const fs = require('fs');

const apiUrl = process.env.URL_NORDVPN_API;
const category = process.env.CATEGORY;
const countries = process.env.COUNTRIES;
const maxLoad = parseInt(process.env.MAX_LOAD, 10);
const ovpnUrl = process.env.URL_OVPN_FILES;
const authFile = process.env.AUTH_FILE;
const vpnOpts = process.env.OPENVPN_OPTS;
const usedVPNsFile = process.env.USED_VPNS_FILE;
const maxUsedVPNs = process.env.MAX_ALLOWED_USED_VPNS;
const protocol = "openvpn_udp"; // Hard-coded only!
const ovpnFolder = "/ovpn";

//////////////

const management = {
    host: "127.0.0.1",
    port: 1337
};

let currentOVPN = '';

downloadOVPNFiles(ovpnUrl, ovpnFolder)
    .then(()=>{
        console.log(`Max allowed used VPNs: ${maxUsedVPNs}`);
        // Get used VPNs
        let usedVPNsListPsv = '';
        try {
            usedVPNsListPsv = fs.readFileSync(usedVPNsFile, 'ascii');
            usedVPNsListPsv = usedVPNsListPsv.replace(/^\|+|\n+|\r+/, ''); // Replace the first pipe, if any
            console.log(`Used VPNs: ${usedVPNsListPsv.replace('/\|/g', ', ')}`);

            // Reset the used VPNs periodically
            if (usedVPNsListPsv.split('|').length >= maxUsedVPNs) {
                console.log(`Clearing the used VPNs list as it exceeded ${maxUsedVPNs} entries.`);
                fs.writeFileSync(usedVPNsFile, '', 'ascii');
                usedVPNsListPsv = '';
            }
        } catch(err) {
            if (err.code === 'ENOENT') {
                console.log('Used VPNs file not found. Skipping.');
            } else {
                console.log(`Used VPNs file error: ${err}`);
            }
        }
        return usedVPNsListPsv;
    })
    .then((usedVPNsListPsv) => {
        return getRandomVPNConfig(apiUrl, countries, protocol, category, maxLoad, ovpnFolder, usedVPNsListPsv);
    })
    .then((ovpn)=>{
        if(typeof ovpn !== 'string') {
            fs.writeFileSync(usedVPNsFile, '', 'ascii');
            throw new Error("Didn't get an OVPN config file. Cleared unused VPN list.");
        }
        return ovpn;
    })
    .then((ovpn) => {
        currentOVPN = ovpn;

        console.log("Preparing VPN server");
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
            console.log("Checking for existing OpenVPN daemons");
            childProcess.execSync('pkill -15 openvpn'); // SIGTERM
        } catch (e) {
        }

        // This will throw an error if the exit code is non-zero
        childProcess.execFileSync('openvpn', args);
    })
    .then(async () => {
        await new Promise(resolve => setTimeout(resolve, 2000));
        const mgr = openVpnManager.connect({host: management.host, port: management.port});
        mgr
            .on('connected', () => {
                console.log("VPN management established")
            })
            // This is too noisy. See state changes and error below instead.
            // .on('console-output', output => {
            //     console.log(output)
            // })
            .on('state-change', async (state) => {
                console.log("State: " + state);
                if (/CONNECTED,SUCCESS/g.test(state)) {
                    await axios.get("https://ipinfo.io/",  { responseType: 'json' })
                        .then((response) => {
                            let json = response.data;
                            if (typeof json !== 'string') {
                                json = JSON.stringify(json, null, 2);
                            }
                            console.log(`VPN IP information:\n${json}`);
                        })
                        .then(()=>{
                            // Save this VPN to the blacklist for the next run
                            // e.g. /ovpn/us3097.nordvpn.com.udp.ovpn --> us3097
                            let vpn = currentOVPN.replace(/^\/.+\/([^.]+).+$/g, '$1');
                            fs.appendFileSync(usedVPNsFile, `|${vpn}`);
                            console.log(`Saved ${vpn} to the used VPNs list.`);
                        })
                        .catch((error) => {
                            console.error(`VPN IP: ${error}`);
                            // Restart the container by ending the manager
                            mgr.destroy();
                        });
                }
            })
            .on('error', error => {
                console.error("Error: " + error);
            })
            .on('disconnected', () => {
                // finally destroy the disconnected manager
                console.log("VPM management disconnected");
                mgr.destroy();
            });
    })
    .then(() => {

        console.log("Setting up signal handlers");
        process.on('exit', function () {
            console.log('VPN process terminated.');
        });

        process.on('SIGTERM', async () => {
            console.log('Got SIGTERM. Trying to stop VPN server gracefully.');
            await openVpnManager.disconnect()
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

