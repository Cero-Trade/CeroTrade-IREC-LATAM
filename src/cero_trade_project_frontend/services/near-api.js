import * as nearAPI from 'near-api-js'

export default async (app) => {
  const
    { connect, keyStores, WalletConnection } = nearAPI,
    keyStore = new keyStores.BrowserLocalStorageKeyStore(),

    appKeyPrefix = "YOUR_APP_KEY_PREFIX_HERE",

    config = {
      networkId: "testnet",
      keyStore, 
      nodeUrl: "https://rpc.testnet.near.org",
      walletUrl: localStorage.getItem("walletUrl"),
      helperUrl: "https://helper.testnet.near.org",
      explorerUrl: "https://explorer.testnet.near.org",
    },

    // connect to NEAR
    near = await connect(config),

    // create wallet connection
    wallet = new WalletConnection(near, appKeyPrefix);

  app.config.globalProperties.$wallet = wallet
}

/*   when need buy
// create contract connection
const contract = new Contract(wallet.account(), item.contract_market, {
  changeMethods: ["buy"],
  sender: wallet.account(),
})
*/
