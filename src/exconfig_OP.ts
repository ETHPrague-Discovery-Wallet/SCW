// eslint-disable-next-line import/no-anonymous-default-export
export default {
    enablePasswordEncryption: true,
    showTransactionConfirmationScreen: true,
    factory_address: '',
    stateVersion: '0.1',
    network: {
      chainID: '10',
      family: 'EVM',
      name: 'Optimism',
      provider: 'https://optimism-mainnet.infura.io/v3/0360c67d49e744d7bba3ff9b77235595',
      entryPointAddress: '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789',
      bundler: 'https://api.stackup.sh/v1/node/aded0118070b1153f20f333ca6896c61ee611351615803946a83739f2f40ca18',
      baseAsset: {
        symbol: 'ETH',
        name: 'ETH',
        decimals: 18,
        image:
          'https://ethereum.org/static/6b935ac0e6194247347855dc3d328e83/6ed5f/eth-diamond-black.webp',
      },
    },
  };
  