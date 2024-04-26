import { fileCompression, getUrlFromArrayBuffer, getImageArrayBuffer } from "@/plugins/functions";
import { useAgentCanister as agent, getErrorMessage } from "@/services/icp-provider";
import avatar from '@/assets/sources/images/avatar-online.svg'
import store from "@/store";
import { UserProfileModel } from "@/models/user-profile-model";
import { AssetType, TokenModel, TokenStatus } from "@/models/token-model";

export class AgentCanister {
  static async register(data: {
    companyId: string,
    companyName: string,
    companyLogo: [File],
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
      const { companyLogo, profile } = await agent().getProfile() as { companyLogo: [number], profile: string },
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

  static async getPortfolio(): Promise<[TokenModel]> {
    try {
      // TODO format to date values
      const response = await agent().getPortfolio() as [TokenModel]
      for (const item of response) {
        item.status = Object.values(item.status)[0] as TokenStatus
        item.assetInfo.assetType = Object.values(item.assetInfo.assetType)[0] as AssetType
      }
      return response
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async getSinglePortfolio(tokenId: string): Promise<TokenModel> {
    try {
      // TODO format to date values
      const token = await agent().getSinglePortfolio(tokenId) as TokenModel
      token.status = Object.values(token.status)[0] as TokenStatus
      token.assetInfo.assetType = Object.values(token.assetInfo.assetType)[0] as AssetType
      return token
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async putOnSale(tokenId: string, quantity: number): Promise<void> {
    try {
      const res = await agent().sellToken(tokenId, quantity)
      console.log(res);
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async purchaseToken(tokenId: string, recipent: string, amount: number): Promise<void> {
    try {
      await agent().purchaseToken(tokenId, recipent, amount)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async takeTokenOffMarket(tokenId: string): Promise<void> {
    try {
      await agent().getRemainingToken(tokenId)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async redeemToken(tokenId: string, beneficiary: string, amount: number): Promise<void> {
    try {
      await agent().redeemToken(tokenId, beneficiary, amount)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }
}