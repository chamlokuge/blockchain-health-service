'use strict';
console.log('Server side code running');

const express = require('express');
const app = express();

const FabricCAServices = require('fabric-ca-client');
const { FileSystemWallet, X509WalletMixin } = require('fabric-network');
const fs = require('fs');
const path = require('path');

const ccpPath = path.resolve(__dirname, 'basic-network', 'connection.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);

//serve files from the health folder
app.use(express.static('health'));
app.listen(8070, () => {
    console.log('listening on 8070');
});