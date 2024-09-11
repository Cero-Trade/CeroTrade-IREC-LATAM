# 🚀 **Cero Trade**  
Cero Trade is a decentralized platform for trading, buying, and redeeming tokenized IRECs (International Renewable Energy Certificates). It features a marketplace where users can manage their assets, redeem certificates, and list them for sale. With real-time data from the I-TRACK API, traders can make informed decisions.

---

## 📋 **Introduction**  
Cero Trade enables users to:
- Create an account with Internet Identity.
- Import IRECs that have been manually transfered from their Evident Participant account into our Platform Operator account.
- Tokenize IRECs and list them for sale or purchase tokenized IRECs from others.
- Track all transaction records and redeem IRECs on behalf of other users.

---

## 🌟 **Key Features**  
- **🔄 IREC Tokenization and Trading**: Easily tokenize IRECs and list them in the marketplace.
- **🔐 Internet Identity**: Secure user accounts with the ICP’s Internet Identity.
- **🛒 Marketplace**: Buy and sell tokenized IRECs seamlessly.
- **📊 Transaction Records**: View transaction history for all actions.
- **🔖 IREC Redemption**: Redeem IRECs for other users' accounts.

---

## 🛠️ **Architecture Overview**  
Below is the system architecture used by Cero Trade, which includes ICP Canisters, Docker API services, and Evident API for integrating IREC functionalities.

![Architecture Diagram](https://github.com/Cero-Trade/CeroTrade-IREC-LATAM/blob/main/readme_assets/nueva_arqui.png)

Regarding canisters, we created a complex system of directories that allow us to dynamically create and map our canisters. Transactions, notifications, users, tokens, and any other canister that will indefinetaly be growing in size has their index' counterpart. Tokens (IRECs) and users are stored in one canister each, for maximum scalability. On the other hand, the agent canister handles all intercanister calls, and all http calls are handled by the HTTP Service canister.

![Canister Architecture](https://github.com/Cero-Trade/CeroTrade-IREC-LATAM/blob/main/readme_assets/canister_architecture.jpg)

---

## 📸 **Screenshots / Demos**  

![](https://github.com/Cero-Trade/CeroTrade-IREC-LATAM/blob/main/readme_assets/demo_gif.gif)

---

## 🌐 **Live Version**  
You can access the live version of the Cero Trade platform here:  
[Live Platform](https://z2mgf-dqaaa-aaaak-qihbq-cai.icp0.io/auth/login?canisterId=z2mgf-dqaaa-aaaak-qihbq-cai)

---

## ⚙️ **Installation Instructions**

### 🔧 **Prerequisites**  
Before installing, ensure you have the following:
- **DFX SDK** installed
- **NNS Extension**: If not installed, run:
```
dfx extension install nns
```
## 🛤️ Roadmap
The upcoming features and improvements include:

- 🔜 Integration with the real Evident API (not sandbox).
- 🔜 Bidding system for redemptions: users will be able to create redemption requests, and sellers can accept or negotiate the price.
- 🔜 Koywe integration: On-ramp and off-ramp services.
- 🔜 Optimization of HTTP call times and general code improvements for cycle costs and load time.

---

## 📄 License
This project is licensed under the MIT License. See the `LICENSE.md` file for details.

---

## 🙏 Acknowledgements
We would like to thank:

- **DFINITY Foundation** for their support and granting us the Developer Grant.
- **Startup Chile** for accelerating our development.
- **Startup Bootcamp in Amsterdam**, for accepting us into their program and supporting our upcoming functional launch.
