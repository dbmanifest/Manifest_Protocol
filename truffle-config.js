const solcStable = {
  version: '^0.8.0',
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};

module.exports = {
  networks: {
    coverage: {
      host: 'localhost',
      network_id: 1670215246065,
      port: 7545,
      gas: 0xfffffffffff,
      gasPrice: 0x01,
    },
  },

  compilers: {
    solc: solcStable,
  },
  mocha: {
    reporter: 'eth-gas-reporter',
    reporterOptions: { outputFile: './gas-report' },
  },
  plugins: ['solidity-coverage'],
};
