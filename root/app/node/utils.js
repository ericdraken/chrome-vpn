/*
 * Copyright (c) 2020. Eric Draken - ericdraken.com
 */
'use strict';
const jq = require('node-jq');
const fs = require('fs');
const axios = require('axios');
const AdmZip = require('adm-zip');

/**
 * Ensure the NordVPN OVPN files are downloaded
 */
const downloadOVPNFiles = async (ovpnUrl, ovpnFolder) => {
    if (await isDirEmpty(ovpnFolder) !== true) {
        console.log("Download of OVPN files not needed");
        return;
    }
    await axios.get(ovpnUrl, {responseType: "arraybuffer"})
        .then((response) => {
            const zip = new AdmZip(response.data);
            const zipEntries = zip.getEntries();
            console.log(`Found ${zipEntries.length} OVPN files. Saving to ${ovpnFolder}`);
            zipEntries.forEach(entry => {
                zip.extractEntryTo(entry, ovpnFolder, false, true);
            });
        })
        .catch((error) => {
            console.log(error);
        });
};

const getRandomVPNConfig = async (apiUrl, countries, protocol, category, maxLoad, ovpnFolder) => {
    console.log('Finding random VPN server');

    // TODO: Make sure server is reachable first or else it will hang
    await new Promise(resolve => setTimeout(resolve, 2000));

    return axios.get(apiUrl, { responseType: 'json', timeout: 5000 })
        .then((response) => {
            console.log(`Found ${response.data.length} servers`);
            return {data: response.data};
        })
        .then((json) => {
            return jq.run(`[ .data[] | select(.features.${protocol} == true) ]`, json, {
                input: 'json',
                output: 'json'
            })
                .then((res) => {
                    console.log(`Found ${res.length} servers with protocol: ${protocol}`);
                    return {data: res};
                });
        })
        .then(async (json) => {
            let filtered = [];
            for (const country of countries.split(",")) {
                filtered = filtered.concat(
                    await jq.run(`[ .data[] | select(.country == "${country}") ]`, json, {
                        input: 'json', output: 'json'
                    }).then((res) => {
                        console.log(`Found ${res.length} servers in country: ${country}`);
                        return res;
                    })
                );
            }
            return {data: filtered};
        })
        .then((json) => {
            return jq.run(`[ .data[] | select(.categories[].name == "${category}") ]`, json, {
                input: 'json', output: 'json'
            })
                .then((res) => {
                    console.log(`Found ${res.length} servers with category: ${category}`);
                    return {data: res};
                });
        })
        .then((json) => {
            return jq.run(`[ .data[] | select(.load <= ${maxLoad}) ]`, json, {input: 'json', output: 'json'})
                .then((res) => {
                    console.log(`Found ${res.length} servers with max load: ${maxLoad}%`);
                    return {data: res};
                });
        })
        .then((json) => {
            shuffle(json.data);
            let bestVPNs = json.data.slice(0, 10);
            bestVPNs.sort((a, b) => a.load - b.load);
            let domains = [];
            console.log("Best randomized servers:\n------------------------");
            bestVPNs.forEach(v => {
                console.log(`${v.country} ${v.domain} ${v.load}%`);
                domains.push(v.domain);
            });
            return domains;
        })
        .then((domains) => {
            for (const domain of domains) {
                let config = `${ovpnFolder}/${domain}.udp.ovpn`;
                if (fs.existsSync(config)) {
                    console.log(`Using: ${config}`);
                    return config;
                }
            }
            throw new Error("No valid config was found");
        })
        .catch((error) => {
            console.log(error);
        });
};

/**
 * Shuffles array in place. ES6 version
 * @param {Array} a items An array containing the items.
 * REF: https://stackoverflow.com/a/6274381/1938889
 */
function shuffle(a) {
    for (let i = a.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
}

function isDirEmpty(dirname) {
    return fs.promises.readdir(dirname).then(files => {
        return files.length === 0;
    });
}

module.exports = {
    getRandomVPNConfig: getRandomVPNConfig,
    downloadOVPNFiles: downloadOVPNFiles
};