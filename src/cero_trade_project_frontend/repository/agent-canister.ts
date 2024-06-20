import { fileCompression, getUrlFromArrayBuffer, getImageArrayBuffer, convertE8SToICP } from "@/plugins/functions";
import { useAgentCanister as agent, getErrorMessage } from "@/services/icp-provider";
import avatar from '@/assets/sources/images/avatar-online.svg'
import store from "@/store";
import { UserProfileModel } from "@/models/user-profile-model";
import { AssetType, TokenModel } from "@/models/token-model";
import { Tokens, TokensICP, TransactionHistoryInfo, TransactionInfo, TxMethodDef, TxTypeDef } from "@/models/transaction-model";
import { MarketplaceInfo, MarketplaceSellersInfo } from "@/models/marketplace-model";
import { Principal } from "@dfinity/principal";
import moment from "moment";
import variables from "@/mixins/variables";
import { NotificationInfo, NotificationTypeDef } from "@/models/notifications-model";

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


  static async getProfile(uid?: Principal): Promise<UserProfileModel> {
    try {
      const userProfile = await agent().getProfile(uid ? [uid] : []) as UserProfileModel
      userProfile.companyLogo = getUrlFromArrayBuffer(userProfile.companyLogo) || avatar
      userProfile.createdAt = new Date(userProfile.createdAt)
      userProfile.updatedAt = new Date(userProfile.updatedAt)

      if (!uid) store.commit('setProfile', userProfile)
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


  static async getPortfolio({ page, length, assetTypes, country, mwhRange }:
    {
      page?: number,
      length?: number,
      assetTypes?: string[],
      country?: string,
      mwhRange?: number[],
    }): Promise<{
    tokensInfo: { data: TokenModel[]; totalPages: number; },
    tokensRedemption: TransactionInfo[]
  }> {
    assetTypes ??= []
    mwhRange ??= []

    try {
      const response = await agent().getPortfolio(
        page ? [page] : [],
        length ? [length] : [],
        assetTypes.length ? [assetTypes.map(energy => ({ [energy]: energy }))] : [],
        country ? [country] : [],
        mwhRange.length ? [mwhRange] : [],
      ) as {tokensInfo: { data: TokenModel[]; totalPages: number; }, tokensRedemption: TransactionInfo[]}

      for (const item of response.tokensInfo.data) {
        // format record value
        item.assetInfo.assetType = Object.values(item.assetInfo.assetType)[0] as AssetType
        item.assetInfo.volumeProduced = Number(item.assetInfo.volumeProduced)
        item.totalAmount = Number(item.totalAmount)
        item.inMarket = Number(item.inMarket)
        item.assetInfo.specifications.capacity = Number(item.assetInfo.specifications.capacity)
        // format dates
        item.assetInfo.startDate = new Date(item.assetInfo.startDate)
        item.assetInfo.endDate = new Date(item.assetInfo.endDate)
        item.assetInfo.dates.forEach(e => { e = new Date(e) })
      }

      response.tokensInfo.totalPages = Number(response.tokensInfo.totalPages)

      for (const item of response.tokensRedemption) {
        item.txType = Object.values(item.txType)[0] as TxTypeDef
        item.to = Object.values(item.to)[0] as string
        item.tokenAmount = Number(item.tokenAmount)
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
      token.assetInfo.volumeProduced = Number(token.assetInfo.volumeProduced)
      token.totalAmount = Number(token.totalAmount)
      token.inMarket = Number(token.inMarket)
      token.assetInfo.specifications.capacity = Number(token.assetInfo.specifications.capacity)
      // format dates
      token.assetInfo.assetType = Object.values(token.assetInfo.assetType)[0] as AssetType
      token.assetInfo.startDate = new Date(token.assetInfo.startDate)
      token.assetInfo.endDate = new Date(token.assetInfo.endDate)

      const dates: Date[] = [];
      for (const date of token.assetInfo.dates) dates.push(new Date(date))
      token.assetInfo.dates = dates

      return token
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async filterUsers(user: string): Promise<UserProfileModel[]> {
    try {
      const users = await agent().filterUsers(user) as UserProfileModel[]

      for (const user of users) user.companyLogo = getUrlFromArrayBuffer(user.companyLogo) || avatar

      return users
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async getBeneficiaries(): Promise<UserProfileModel[]> {
    try {
      const users = await agent().getBeneficiaries() as UserProfileModel[]

      for (const user of users) user.companyLogo = getUrlFromArrayBuffer(user.companyLogo) || avatar

      return users
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async updateBeneficiaries(beneficiaryId: Principal, { remove }: { remove: boolean }): Promise<void> {
    try {
      await agent().updateBeneficiaries(beneficiaryId, { "delete": remove })
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async requestBeneficiary(beneficiaryId: Principal): Promise<void> {
    try {
      await agent().requestBeneficiary(beneficiaryId)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async getTokenDetails(tokenId: string): Promise<TokenModel> {
    try {
      const token = await agent().getTokenDetails(tokenId) as TokenModel

      // format record value
      token.assetInfo.volumeProduced = Number(token.assetInfo.volumeProduced)
      token.totalAmount = Number(token.totalAmount)
      token.inMarket = Number(token.inMarket)
      token.assetInfo.specifications.capacity = Number(token.assetInfo.specifications.capacity)
      // format dates
      token.assetInfo.assetType = Object.values(token.assetInfo.assetType)[0] as AssetType
      token.assetInfo.startDate = new Date(token.assetInfo.startDate)
      token.assetInfo.endDate = new Date(token.assetInfo.endDate)

      const dates: Date[] = [];
      for (const date of token.assetInfo.dates) dates.push(new Date(date))
      token.assetInfo.dates = dates

      return token
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async getTokenCanister(tokenId: string): Promise<Principal> {
    try {
      return await agent().getTokenCanister(tokenId) as Principal
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async getMarketplace({ page, length, assetTypes, country, priceRange }: {
    page?: number,
    length?: number,
    assetTypes?: string[],
    country?: string,
    priceRange?: number[],
  }): Promise<{ data: MarketplaceInfo[], totalPages: number }> {
    assetTypes ??= []
    priceRange ??= []

    try {
      const response = await agent().getMarketplace(
        page ? [page] : [],
        length ? [length] : [],
        assetTypes.length ? [assetTypes.map(energy => ({ [energy]: energy }))] : [],
        country ? [country] : [],
        priceRange.length ? [priceRange.map(price => ({ e8s: price }))] : [],
      ) as { data: MarketplaceInfo[], totalPages: number }

      for (const item of response.data) {
        // format record value
        item.assetInfo.assetType = Object.values(item.assetInfo.assetType)[0] as AssetType
        item.assetInfo.volumeProduced = Number(item.assetInfo.volumeProduced)
        item.assetInfo.specifications.capacity = Number(item.assetInfo.specifications.capacity)
        item.mwh = Number(item.mwh)

        // convert e8s to icp
        item.lowerPriceE8S = convertE8SToICP(Number(item.lowerPriceE8S['e8s']))
        item.higherPriceE8S = convertE8SToICP(Number(item.higherPriceE8S['e8s']))
      }

      response.totalPages = Number(response.totalPages)

      return response
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async getMarketplaceSellers({ page, length, tokenId, country, priceRange, excludeCaller }: {
    page?: number,
    length?: number,
    tokenId?: string,
    country?: string,
    priceRange?: number[],
    excludeCaller: boolean,
  }): Promise<{ data: MarketplaceSellersInfo[], totalPages: number }> {
    priceRange ??= []
    excludeCaller ??= false

    try {
      const response = await agent().getMarketplaceSellers(
        page ? [page] : [],
        length ? [length] : [],
        tokenId ? [tokenId] : [],
        country ? [country] : [],
        priceRange.length ? [priceRange.map(price => ({ e8s: price }))] : [],
        excludeCaller,
      ) as { data: MarketplaceSellersInfo[], totalPages: number }

      for (const item of response.data) {
        // format record value
        item.mwh = Number(item.mwh)

        // get nullable object
        item.assetInfo = item.assetInfo[0]
        item.assetInfo.assetType = Object.values(item.assetInfo.assetType)[0] as AssetType
        item.assetInfo.volumeProduced = Number(item.assetInfo.volumeProduced)
        item.assetInfo.specifications.capacity = Number(item.assetInfo.specifications.capacity)

        // convert e8s to icp
        item.priceE8S = convertE8SToICP(Number(item.priceE8S['e8s']))
      }

      response.totalPages = Number(response.totalPages)

      return response
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async purchaseToken(tokenId: string, recipent: Principal, amount: number): Promise<TransactionInfo> {
    try {
      const tx = await agent().purchaseToken(tokenId, recipent, amount) as TransactionInfo
      tx.txType = Object.values(tx.txType)[0] as TxTypeDef
      tx.to = Object.values(tx.to)[0] as string

      return tx
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async putOnSale(tokenId: string, quantity: number, price: TokensICP): Promise<void> {
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
  

  static async requestRedeemToken(tokenId: string, amount: number, beneficiary: Principal): Promise<void> {
    try {
      await agent().requestRedeemToken(tokenId, amount, beneficiary)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async redeemToken(tokenId: string, amount: number, beneficiary?: Principal): Promise<TransactionInfo> {
    try {
      const tx = await agent().redeemToken(tokenId, amount, beneficiary ? [beneficiary] : []) as TransactionInfo
      tx.txType = Object.values(tx.txType)[0] as TxTypeDef
      tx.to = Object.values(tx.to)[0] as string

      return tx
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async getTransactions({ page, length, txType, country, priceRange, mwhRange, assetTypes, method, rangeDates }: {
    page?: number,
    length?: number,
    txType?: TxTypeDef,
    country?: string,
    priceRange?: Tokens[],
    mwhRange?: number[],
    assetTypes?: AssetType[],
    method?: TxMethodDef,
    rangeDates?: Date[],
  }): Promise<{ data: TransactionHistoryInfo[]; totalPages: number; }> {
    priceRange ??= []
    mwhRange ??= []
    assetTypes ??= []
    rangeDates ??= []

    try {
      const response = await agent().getTransactionsByUser(
        page ? [page] : [],
        length ? [length] : [],
        txType ? [{[txType]: txType}] : [],
        country ? [country] : [],
        priceRange.length ? [priceRange.map(price => ({ e8s: price }))] : [],
        mwhRange.length ? [mwhRange] : [],
        assetTypes.length ? [assetTypes.map(energy => ({ [energy]: energy }))] : [],
        method ? [{[method]: method}] : [],
        rangeDates.length ? [rangeDates.map(e => moment(e).format(variables.dateFormat))] : [],
      ) as { data: TransactionHistoryInfo[]; totalPages: number; }

      for (const item of response.data) {
        // format record value
        item.tokenAmount = Number(item.tokenAmount)
        item.txType = Object.values(item.txType)[0] as TxTypeDef
        item.method = Object.values(item.method)[0] as TxMethodDef
        item.date = new Date(item.date)

        // get nullable object
        item.to = item.to[0]
        item.assetInfo = item.assetInfo[0]
        item.assetInfo.assetType = Object.values(item.assetInfo.assetType)[0] as AssetType
        item.assetInfo.volumeProduced = Number(item.assetInfo.volumeProduced)
        item.assetInfo.specifications.capacity = Number(item.assetInfo.specifications.capacity)

        // convert e8s to icp
        item.priceE8S = convertE8SToICP(Number(item.priceE8S['e8s']))
      }

      response.totalPages = Number(response.totalPages)

      return response
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async getAssetStatistics(): Promise<[string, number][]> {
    try {
      const res = await agent().getAssetStatistics() as [string, number][]
      for (const item of res)
        item[1] = Number(item[1])

      return res
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async getNotifications(page?: number, length?: number, notificationType?: NotificationTypeDef): Promise<NotificationInfo[]> {
    try {
      const res = await agent().getNotifications(
        page ? [page] : [],
        length ? [length] : [],
        notificationType ? [{[notificationType]: notificationType}] : [],
      ) as NotificationInfo[]

      for (const item of res) {
        item.notificationType = Object.values(item.notificationType)[0] as string
        item.callerBeneficiaryId = item.callerBeneficiaryId[0]
        item.tokenId = item.tokenId[0]
        item.quantity = item.quantity[0] ? Number(item.quantity[0]) : null
        item.createdAt = new Date(item.createdAt)
      }

      return res
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async removeNotification(notificationId: string): Promise<void> {
    try {
      await agent().getNotifications(notificationId)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async clearNotificationsByType(notificationType: NotificationTypeDef): Promise<void> {
    try {
      await agent().clearNotificationsByType({[notificationType]: notificationType})
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }
}