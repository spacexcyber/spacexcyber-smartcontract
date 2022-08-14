/** @type import('hardhat/config').HardhatUserConfig */
require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
const { alchemyApiKey, mnemonic } = require('./secrets.json');
module.exports = {
  solidity: "0.8.9",
  networks: {
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${alchemyApiKey}`,
      accounts: { mnemonic: mnemonic },
    },
    testnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545/`,
      chainId: 97,
      gasPrice: 20000000000,
      accounts: { mnemonic: mnemonic }
    },
  },
  external: {
    contracts: [
      {
        artifacts: 'node_modules/@uniswap/v2-core/build',
      },
      {
        artifacts: 'node_modules/@uniswap/v2-periphery/build',
      },
    ],
  },
};
