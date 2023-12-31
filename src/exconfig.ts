// eslint-disable-next-line import/no-anonymous-default-export
export default {
  enablePasswordEncryption: true,
  showTransactionConfirmationScreen: true,
  factory_address: '0x160C8d17F78e74A359C3328e4b138db82096648E',
  stateVersion: '0.1',
  network: {
    chainID: '11155111',
    family: 'EVM',
    name: 'Sepolia',
    provider: 'https://sepolia.infura.io/v3/0360c67d49e744d7bba3ff9b77235595',
    entryPointAddress: '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789',
    bundler: 'https://sepolia.voltaire.candidewallet.com/rpc',
    baseAsset: {
      symbol: 'ETH',
      name: 'ETH',
      decimals: 18,
      image:
        'https://ethereum.org/static/6b935ac0e6194247347855dc3d328e83/6ed5f/eth-diamond-black.webp',
    },
  },
};
