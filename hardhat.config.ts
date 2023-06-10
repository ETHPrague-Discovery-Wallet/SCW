// import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import 'hardhat-deploy';
import '@typechain/hardhat';
import { HardhatUserConfig } from 'hardhat/types';
import * as fs from 'fs';
import '@nomiclabs/hardhat-etherscan';


require('dotenv').config();
require("@nomicfoundation/hardhat-toolbox");


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork:"localhost",
  networks:{
    localhost: {
      url: "http://127.0.0.1:8545"
    },
  sepolia: {
      url: "https://rpc.sepolia.org",
      accounts: [process.env.PRIVATE_KEY]
  },
  },
  solidity: {
    version: "0.8.12",
    settings: {
      optimizer: {
        enabled: false,
        runs: 100,
      },
    },
  },
};

