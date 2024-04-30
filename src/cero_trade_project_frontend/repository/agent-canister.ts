import { fileCompression, getUrlFromArrayBuffer, getImageArrayBuffer } from "@/plugins/functions";
import { useAgentCanister as agent, getErrorMessage } from "@/services/icp-provider";
import avatar from '@/assets/sources/images/avatar-online.svg'
import store from "@/store";
import { UserProfileModel } from "@/models/user-profile-model";
import { AssetType, TokenModel, TokenStatus } from "@/models/token-model";
import { TransactionInfo, TxType } from "@/models/transaction-model";
import { MarketplaceInfo } from "@/models/marketplace-model";
import { IDL } from "@dfinity/candid";

export class AgentCanister {
  static async register(data: {
    companyId: string,
    companyName: string,
    companyLogo: File[],
    country: string,
    city: string,
    address: string,
    email: string,
  }): Promise<void> {
    try {
      // store user
      await agent().register({
        companyId: data.companyId,
        companyName: data.companyName,
        country: data.country,
        city: data.city,
        address: data.address,
        email: data.email,
      })

      // store user company logo
      const fileCompressed = await fileCompression(data.companyLogo[0]),
      arrayBuffer = await getImageArrayBuffer(fileCompressed)
      await AgentCanister.storeCompanyLogo(arrayBuffer)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async storeCompanyLogo(companyLogo: Blob): Promise<void> {
    try {
      await agent().storeCompanyLogo(companyLogo)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async login(): Promise<void> {
    try {
      await agent().login()
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async deleteUser(): Promise<void> {
    try {
      await agent().deleteUser()
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async getProfile(): Promise<UserProfileModel> {
    try {
      const { companyLogo, profile } = await agent().getProfile() as { companyLogo: number[], profile: string },
      profileData = JSON.parse(profile),
      userProfile = {
        companyLogo: getUrlFromArrayBuffer(companyLogo) || avatar,
        ...profileData
      }

      store.commit('setProfile', userProfile)
      return userProfile
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async checkUserToken(tokenId: string): Promise<boolean> {
    try {
      return await agent().checkUserToken(tokenId) as boolean
    } catch (_) {
      return false
    }
  }


  static async getPortfolio(): Promise<{tokensInfo: TokenModel[], tokensRedemption: TransactionInfo[]}> {
    try {
      const response = await agent().getPortfolio() as {tokensInfo: TokenModel[], tokensRedemption: TransactionInfo[]}

      for (const item of response.tokensInfo) {
        item.status = Object.values(item.status)[0] as TokenStatus
        // format record value
        item.assetInfo.assetType = Object.values(item.assetInfo.assetType)[0] as AssetType
        item.assetInfo.volumeProduced = Number(item.assetInfo.volumeProduced)
        item.totalAmount = Number(item.totalAmount)
        item.inMarket = Number(item.inMarket)
        item.assetInfo.specifications.capacity = Number(item.assetInfo.specifications.capacity)
        // format dates
        item.assetInfo.startDate = new Date(Number(item.assetInfo.startDate))
        item.assetInfo.endDate = new Date(Number(item.assetInfo.endDate))
        item.assetInfo.dates.forEach(e => { e = new Date(Number(e)) })
      }

      for (const item of response.tokensRedemption) {
        item.txType = Object.values(item.txType)[0] as TxType
        item.to = Object.values(item.to)[0] as string
      }

      return response
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async getSinglePortfolio(tokenId: string): Promise<TokenModel> {
    try {
      const token = await agent().getSinglePortfolio(tokenId) as TokenModel

      // format record value
      token.status = Object.values(token.status)[0] as TokenStatus
      token.assetInfo.volumeProduced = Number(token.assetInfo.volumeProduced)
      token.totalAmount = Number(token.totalAmount)
      token.inMarket = Number(token.inMarket)
      token.assetInfo.specifications.capacity = Number(token.assetInfo.specifications.capacity)
      // format dates
      token.assetInfo.assetType = Object.values(token.assetInfo.assetType)[0] as AssetType
      token.assetInfo.startDate = new Date(Number(token.assetInfo.startDate))
      token.assetInfo.endDate = new Date(Number(token.assetInfo.endDate))

      const dates: Date[] = [];
      for (const date of token.assetInfo.dates) dates.push(new Date(Number(date)))
      token.assetInfo.dates = dates

      return token
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async getTokenDetails(tokenId: string): Promise<TokenModel> {
    try {
      const token = await agent().getTokenDetails(tokenId) as TokenModel

      // format record value
      token.status = Object.values(token.status)[0] as TokenStatus
      token.assetInfo.volumeProduced = Number(token.assetInfo.volumeProduced)
      token.totalAmount = Number(token.totalAmount)
      token.inMarket = Number(token.inMarket)
      token.assetInfo.specifications.capacity = Number(token.assetInfo.specifications.capacity)
      // format dates
      token.assetInfo.assetType = Object.values(token.assetInfo.assetType)[0] as AssetType
      token.assetInfo.startDate = new Date(Number(token.assetInfo.startDate))
      token.assetInfo.endDate = new Date(Number(token.assetInfo.endDate))

      const dates: Date[] = [];
      for (const date of token.assetInfo.dates) dates.push(new Date(Number(date)))
      token.assetInfo.dates = dates

      return token
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async getMarketplace(): Promise<MarketplaceInfo[]> {
    try {
      const response = await agent().getMarketplace() as MarketplaceInfo[]

      for (const item of response) {
        // format record value
        item.lowerPriceICP = Number(item.lowerPriceICP['e8s'])
        item.higherPriceICP = Number(item.higherPriceICP['e8s'])
        item.assetInfo.assetType = Object.values(item.assetInfo.assetType)[0] as AssetType
        item.assetInfo.volumeProduced = Number(item.assetInfo.volumeProduced)
        item.assetInfo.specifications.capacity = Number(item.assetInfo.specifications.capacity)
      }

      return response
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async purchaseToken(tokenId: string, recipent: string, amount: number, price: number): Promise<TransactionInfo> {
    try {
      const tx = await agent().purchaseToken(tokenId, recipent, amount, price) as TransactionInfo
      tx.txType = Object.values(tx.txType)[0] as TxType
      tx.to = Object.values(tx.to)[0] as string

      return tx
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async putOnSale(tokenId: string, quantity: number, price: number): Promise<void> {
    try {
      const res = await agent().sellToken(tokenId, quantity, price)
      console.log(res);
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async takeTokenOffMarket(tokenId: string, quantity: number): Promise<void> {
    try {
      await agent().takeTokenOffMarket(tokenId, quantity)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async redeemToken(tokenId: string, beneficiary: string, amount: number): Promise<TransactionInfo> {
    try {
      const tx = await agent().redeemToken(tokenId, beneficiary, amount) as TransactionInfo
      tx.txType = Object.values(tx.txType)[0] as TxType
      tx.to = Object.values(tx.to)[0] as string

      return tx
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }
}