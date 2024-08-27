import { fileCompression, getUrlFromArrayBuffer, getImageArrayBuffer, convertE8SToICP, getFileFromArrayBuffer } from "@/plugins/functions";
import { useAgentCanister as agent, getErrorMessage } from "@/services/icp-provider";
import avatar from '@/assets/sources/images/avatar-online.svg'
import store from "@/store";
import { UserProfileModel } from "@/models/user-profile-model";
import { AssetInfoModel, AssetType, TokenModel } from "@/models/token-model";
import { Tokens, TokensICP, TransactionHistoryInfo, TransactionInfo, TxMethodDef, TxTypeDef } from "@/models/transaction-model";
import { MarketplaceInfo, MarketplaceSellersInfo } from "@/models/marketplace-model";
import { Principal } from "@dfinity/principal";
import moment from "moment";
import variables from "@/mixins/variables";
import { NotificationEventStatusDef, NotificationInfo, NotificationStatusDef, NotificationTypeDef } from "@/models/notifications-model";
import { AssetStatistic } from "@/models/statistics-model";

export class AgentCanister {
  static async register(data: {
    companyId: string,
    evidentId: string,
    companyName: string,
    companyLogo: File[],
    country: string,
    city: string,
    address: string,
    email: string,
  }, beneficiary?: string): Promise<void> {
    try {
      // store user
      await agent().register({
        companyId: data.companyId,
        evidentId: data.evidentId,
        companyName: data.companyName,
        country: data.country,
        city: data.city,
        address: data.address,
        email: data.email,
      }, beneficiary ? [Principal.fromText(beneficiary)] : [])

      // store user company logo
      const fileCompressed = await fileCompression(data.companyLogo[0]),
      arrayBuffer = await getImageArrayBuffer(fileCompressed)
      await AgentCanister.storeCompanyLogo(arrayBuffer)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async updateUserInfo(data: {
    companyId: string,
    companyName: string,
    companyLogo?: File[],
    country: string,
    city: string,
    address: string,
    email: string,
  }): Promise<void> {
    try {
      // update user
      await agent().updateUserInfo({
        companyId: data.companyId,
        companyName: data.companyName,
        country: data.country,
        city: data.city,
        address: data.address,
        email: data.email,
      })

      if (data.companyLogo?.length) {
        // store user company logo
        const fileCompressed = await fileCompression(data.companyLogo[0]),
        arrayBuffer = await getImageArrayBuffer(fileCompressed)
        await AgentCanister.storeCompanyLogo(arrayBuffer)
      }

      await this.getProfile()
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
      userProfile.principalId = Principal.fromText(userProfile.principalId.toString())
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
      const balance = await agent().balanceOf(tokenId) as bigint
      return balance > BigInt(0)
    } catch (_) {
      return false
    }
  }

  static async checkUserTokenInMarket(tokenId: string): Promise<boolean> {
    try {
      return await agent().checkUserTokenInMarket(tokenId) as boolean
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
        item.assetInfo.deviceDetails.deviceType = Object.values(item.assetInfo.deviceDetails.deviceType)[0] as AssetType
        item.assetInfo.volumeProduced = Number(item.assetInfo.volumeProduced)
        item.totalAmount = Number(item.totalAmount)
        item.inMarket = Number(item.inMarket)
        item.assetInfo.specifications.capacity = Number(item.assetInfo.specifications.capacity)
        // format dates
        item.assetInfo.startDate = new Date(item.assetInfo.startDate)
        item.assetInfo.endDate = new Date(item.assetInfo.endDate)
      }

      response.tokensInfo.totalPages = Number(response.tokensInfo.totalPages)

      for (const item of response.tokensRedemption) {
        item.txType = Object.values(item.txType)[0] as TxTypeDef
        item.to = Object.values(item.to)[0] as string
        item.tokenAmount = Number(item.tokenAmount)
        item.redemptionPdf = await getFileFromArrayBuffer(item.redemptionPdf, { fileName: 'certificate', fileType: 'application/pdf' })
        item['url'] = URL.createObjectURL(item.redemptionPdf)
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
      token.assetInfo.deviceDetails.deviceType = Object.values(token.assetInfo.deviceDetails.deviceType)[0] as AssetType
      token.assetInfo.startDate = new Date(token.assetInfo.startDate)
      token.assetInfo.endDate = new Date(token.assetInfo.endDate)

      return token
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async filterUsers(user: string): Promise<UserProfileModel[]> {
    try {
      const users = await agent().filterUsers(user) as UserProfileModel[]

      const profile = UserProfileModel.get(),
      profileIndex = users.findIndex(e => e.principalId.toString() == profile.principalId.toString())
      if (profileIndex != -1) users.splice(profileIndex, 1)

      for (const user of users) {
        user.principalId = Principal.fromText(user.principalId.toString())
        user.companyLogo = getUrlFromArrayBuffer(user.companyLogo) || avatar
        user.createdAt = new Date(user.createdAt)
        user.updatedAt = new Date(user.updatedAt)
      }

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

  static async addBeneficiaryRequested(notificationId: string): Promise<void> {
    try {
      await agent().addBeneficiaryRequested(notificationId)
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

  static async importUserTokens(): Promise<{ mwh: number, assetInfo: AssetInfoModel }[]> {
    try {
      const transactions = await agent().importUserTokens() as { mwh: number, assetInfo: AssetInfoModel }[]

      for (const transaction of transactions) {
        // format record value
        transaction.mwh = Number(transaction.mwh)
        transaction.assetInfo.volumeProduced = Number(transaction.assetInfo.volumeProduced)
        transaction.assetInfo.specifications.capacity = Number(transaction.assetInfo.specifications.capacity)
        // format dates
        transaction.assetInfo.deviceDetails.deviceType = Object.values(transaction.assetInfo.deviceDetails.deviceType)[0] as AssetType
        transaction.assetInfo.startDate = new Date(transaction.assetInfo.startDate)
        transaction.assetInfo.endDate = new Date(transaction.assetInfo.endDate)
      }

      console.log(transactions);

      return transactions
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
      token.assetInfo.deviceDetails.deviceType = Object.values(token.assetInfo.deviceDetails.deviceType)[0] as AssetType
      token.assetInfo.startDate = new Date(token.assetInfo.startDate)
      token.assetInfo.endDate = new Date(token.assetInfo.endDate)

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
        item.assetInfo.deviceDetails.deviceType = Object.values(item.assetInfo.deviceDetails.deviceType)[0] as AssetType
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
        item.assetInfo.deviceDetails.deviceType = Object.values(item.assetInfo.deviceDetails.deviceType)[0] as AssetType
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
      tx.to = tx.to[0] as string
      tx.method = Object.values(tx.method)[0] as TxMethodDef
      tx.priceE8S = tx.priceE8S[0] ? convertE8SToICP(Number(tx.priceE8S[0]['e8s'])) : null

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


  static async requestRedeemToken({ tokenId, amount, beneficiary, periodStart, periodEnd, locale }: {
    tokenId: string,
    amount: number,
    beneficiary: Principal,
    periodStart: Date,
    periodEnd: Date,
    locale: string,
  }): Promise<void> {
    try {
      await agent().requestRedeemToken(
        tokenId,
        amount,
        beneficiary,
        moment(periodStart).format(variables.dateFormat),
        moment(periodEnd).format(variables.dateFormat),
        locale
      )
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async redeemTokenRequested(notificationId: string): Promise<void> {
    try {
      await agent().redeemTokenRequested(notificationId)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async redeemToken({ tokenId, amount, periodStart, periodEnd, locale }: {
    tokenId: string,
    amount: number,
    periodStart: Date,
    periodEnd: Date,
    locale: string,
  }): Promise<TransactionInfo> {
    try {
      const tx = await agent().redeemToken(
        tokenId,
        amount,
        moment(periodStart).format(variables.dateFormat),
        moment(periodEnd).format(variables.dateFormat),
        locale
      ) as TransactionInfo
      tx.txType = Object.values(tx.txType)[0] as TxTypeDef
      tx.to = tx.to[0] as string
      tx.method = Object.values(tx.method)[0] as TxMethodDef
      tx.priceE8S = tx.priceE8S[0] ? convertE8SToICP(Number(tx.priceE8S[0]['e8s'])) : null

      return tx
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async getTransactions({ page, length, txType, country, priceRange, mwhRange, assetTypes, method, rangeDates, tokenId }: {
    page?: number,
    length?: number,
    txType?: TxTypeDef,
    country?: string,
    priceRange?: Tokens[],
    mwhRange?: number[],
    assetTypes?: AssetType[],
    method?: TxMethodDef,
    rangeDates?: Date[],
    tokenId?: string,
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
        tokenId ? [tokenId] : [],
      ) as { data: TransactionHistoryInfo[]; totalPages: number; }

      for (const item of response.data) {
        // format record value
        item.tokenAmount = Number(item.tokenAmount)
        item.txType = Object.values(item.txType)[0] as TxTypeDef
        item.method = Object.values(item.method)[0] as TxMethodDef
        item.date = new Date(item.date)
        item.redemptionPdf = await getFileFromArrayBuffer(item.redemptionPdf, { fileName: 'certificate', fileType: 'application/pdf' })
        item['url'] = URL.createObjectURL(item.redemptionPdf)

        // get nullable object
        item.to = item.to[0]
        item.assetInfo = item.assetInfo[0]
        item.assetInfo.deviceDetails.deviceType = Object.values(item.assetInfo.deviceDetails.deviceType)[0] as AssetType
        item.assetInfo.volumeProduced = Number(item.assetInfo.volumeProduced)
        item.assetInfo.specifications.capacity = Number(item.assetInfo.specifications.capacity)

        // convert e8s to icp
        item.priceE8S = item.priceE8S[0] ? convertE8SToICP(Number(item.priceE8S[0]['e8s'])) : null
      }

      response.totalPages = Number(response.totalPages)

      return response
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async getAllAssetStatistics(): Promise<[string, AssetStatistic][]> {
    try {
      const res = await agent().getAllAssetStatistics() as [string, AssetStatistic][]

      for (const item of res) {
        item[1].mwh = Number(item[1].mwh)
        item[1].assetType = Object.values(item[1].assetType)[0] as AssetType
        item[1].redemptions = Number(item[1].redemptions)
      }

      return res
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async getAssetStatistics(tokenId: string): Promise<AssetStatistic> {
    try {
      const res = await agent().getAssetStatistics(tokenId) as AssetStatistic

      res.mwh = Number(res.mwh)
      res.assetType = Object.values(res.assetType)[0] as AssetType
      res.redemptions = Number(res.redemptions)

      return res
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async getNotifications(page?: number, length?: number, notificationTypes?: NotificationTypeDef[]): Promise<NotificationInfo[]> {
    try {
      const res = await agent().getNotifications(
        page ? [page] : [],
        length ? [length] : [],
        notificationTypes?.map(e => ({[e]: e})) ?? [],
      ) as NotificationInfo[]

      for (const item of res) {
        item.notificationType = Object.values(item.notificationType)[0] as NotificationTypeDef
        item.eventStatus = item.eventStatus[0] ? Object.values(item.eventStatus[0])[0] as NotificationEventStatusDef : null
        item.status = item.status[0] ? Object.values(item.status[0])[0] as NotificationStatusDef : null
        item.content = item.content[0]
        item.triggeredBy = item.triggeredBy[0]
        item.tokenId = item.tokenId[0]
        item.quantity = Number(item.quantity[0]) || null
        item.createdAt = new Date(item.createdAt)
      }

      return res
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  // update general notifications
  static async updateGeneralNotifications(notificationIds: [string]): Promise<void> {
    try {
      await agent().updateGeneralNotifications(notificationIds);
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  };

  // clear general notifications
  static async clearGeneralNotifications(notificationIds: [Text]): Promise<void> {
    try {
      await agent().clearGeneralNotifications(notificationIds);
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  };

  // update event notification
  static async updateEventNotification(notificationId: string, receiverEventStatus?: NotificationEventStatusDef): Promise<void> {
    try {
      await agent().updateEventNotification(notificationId, receiverEventStatus ? [{[receiverEventStatus]: receiverEventStatus}] : [])
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }
}