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
Below is the system architecture used by Cero Trade, which includes ICP Canisters, Docker API services, and Evident API for integrating IREC functionalities. Regarding canisters, we created a complex system of directories that allow us to dynamically create and map our canisters. Transactions, notifications, users, tokens, and any other canister that will indefinetaly be growing in size has their index' counterpart. Tokens (IRECs) and users are stored in one canister each, for maximum scalability. On the other hand, the agent canister handles all intercanister calls, and all http calls are handled by the HTTP Service canister.

**Canister architecture**
![Canister Architecture](https://github.com/Cero-Trade/CeroTrade-IREC-LATAM/blob/main/readme_assets/canister_architecture.jpg)

- **Frontend canister:** This canister contains the webapp and allows interaction with our users.
- **User Canisters:** These canisters manage user data, including identities, interactions, and other key information that traders need to access. Each user’s data is securely stored and can be retrieved when required.
- **Token Canisters:** These canisters store and handle the management of tokenized climate assets like i-RECs. They are indexed via a Token Index, ensuring that each transaction involving tokens is accounted for and managed properly.
- **Cero Trade Agent:** This is the core canister that handles the marketplace logic, including processing trades, managing notifications, and ensuring that transactions happen smoothly between users and the assets they trade.
- **Marketplace Canister:** The marketplace interface interacts with the Cero Trade Agent, allowing users to easily access, trade, and redeem climate assets.
- **Notifications & Transaction Index:** These canisters are responsible for managing the flow of notifications and the tracking of transactions, providing transparency and real-time updates to users.
- **Statistics Canister:** This provides analytical insights and tracks overall usage, trends, and statistics within the platform.


**UML diagram**
![Architecture Diagram](https://github.com/Cero-Trade/CeroTrade-IREC-LATAM/blob/main/readme_assets/nueva_arqui.png)

- **User Interface & API Gateway:** Users interact with the system through our UI, which is connected to an API Gateway. This allows for secure communication between users and our internal components.
- **Nginx Proxy & Load Balancer:** We use a reverse proxy (Nginx) and load balancer to ensure that the platform handles traffic smoothly, while the firewall (WAF) adds an extra layer of security to protect against external threats.
- **EC2 Instances & Docker Containers:** Our core API services, hosted in Docker containers, manage user data and handle interactions with external APIs (Evident API, and Cero Trade API).
- **ICP Canisters:** The key logic of the platform, as we mentioned earlier, runs on Internet Computer Canisters. This ensures the security and decentralized nature of the platform while allowing for seamless interaction with the outside infrastructure.

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
