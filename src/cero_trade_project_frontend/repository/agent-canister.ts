import { fileCompression, getUrlFromArrayBuffer, getImageArrayBuffer, getFileFromArrayBuffer, tokenToNumber, numberToToken } from "@/plugins/functions";
import { useAgentCanister as agent, getErrorMessage } from "@/services/icp-provider";
import avatar from '@/assets/sources/images/avatar-online.svg'
import store from "@/store";
import { UserProfileModel } from "@/models/user-profile-model";
import { AssetInfoModel, AssetType, Portfolio, SinglePortfolio } from "@/models/token-model";
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

  static async getPortfolio({ page, length, assetTypes, country, mwhRange }: {
    page?: number,
    length?: number,
    assetTypes?: string[],
    country?: string,
    mwhRange?: number[],
  }): Promise<{ data: [Portfolio]; totalPages: number; }> {
    assetTypes ??= []
    mwhRange ??= []

    try {
      const response = await agent().getPortfolio(
        page ? [page] : [],
        length ? [length] : [],
        assetTypes.length ? [assetTypes.map(energy => ({ [energy]: energy }))] : [],
        country ? [country] : [],
        mwhRange.length ? [mwhRange] : [],
      ) as {
        data: [Portfolio];
        totalPages: number;
      }

      for (const item of response.data) {
        // format record value
        item.tokenInfo.assetInfo.deviceDetails.deviceType = Object.values(item.tokenInfo.assetInfo.deviceDetails.deviceType)[0] as AssetType
        item.tokenInfo.assetInfo.volumeProduced = tokenToNumber(item.tokenInfo.assetInfo.volumeProduced)
        item.tokenInfo.totalAmount = tokenToNumber(item.tokenInfo.totalAmount)
        item.tokenInfo.inMarket = tokenToNumber(item.tokenInfo.inMarket)
        // format dates
        item.tokenInfo.assetInfo.startDate = new Date(item.tokenInfo.assetInfo.startDate)
        item.tokenInfo.assetInfo.endDate = new Date(item.tokenInfo.assetInfo.endDate)

        item.redemptions = item.redemptions.map(e => tokenToNumber(e)) as number[]
      }

      response.totalPages = Number(response.totalPages)

      return response
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async getSinglePortfolio(tokenId: string): Promise<SinglePortfolio> {
    try {
      const portfolio = await agent().getSinglePortfolio(tokenId) as SinglePortfolio

      // format record value
      portfolio.tokenInfo.assetInfo.volumeProduced = tokenToNumber(portfolio.tokenInfo.assetInfo.volumeProduced)
      portfolio.tokenInfo.totalAmount = tokenToNumber(portfolio.tokenInfo.totalAmount)
      portfolio.tokenInfo.inMarket = tokenToNumber(portfolio.tokenInfo.inMarket)
      // format dates
      portfolio.tokenInfo.assetInfo.deviceDetails.deviceType = Object.values(portfolio.tokenInfo.assetInfo.deviceDetails.deviceType)[0] as AssetType
      portfolio.tokenInfo.assetInfo.startDate = new Date(portfolio.tokenInfo.assetInfo.startDate)
      portfolio.tokenInfo.assetInfo.endDate = new Date(portfolio.tokenInfo.assetInfo.endDate)

      for (const redemption of portfolio.redemptions) {
        redemption.txType = Object.values(redemption.txType)[0] as TxTypeDef
        redemption.to = redemption.to[0]
        redemption.tokenAmount = tokenToNumber(redemption.tokenAmount)

        const conversion = getFileFromArrayBuffer(redemption.redemptionPdf, { fileName: 'certificate', fileType: 'application/pdf' })
        redemption.redemptionPdf = conversion.file
        redemption['url'] = URL.createObjectURL(conversion.blob)
      }

      return portfolio
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async filterUsers(user: string): Promise<{ principalId: Principal; companyName: string }[]> {
    try {
      const users = await agent().filterUsers(user) as { principalId: Principal; companyName: string }[]

      const profile = UserProfileModel.get(),
      profileIndex = users.findIndex(e => e.principalId.toString() == profile.principalId.toString())
      if (profileIndex != -1) users.splice(profileIndex, 1)

      for (const user of users) {
        user.principalId = Principal.fromText(user.principalId.toString())
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
        transaction.mwh = tokenToNumber(transaction.mwh)
        transaction.assetInfo.volumeProduced = tokenToNumber(transaction.assetInfo.volumeProduced)
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
        priceRange.length ? [priceRange.map(price => ({ e8s: numberToToken(price) }))] : [],
      ) as { data: MarketplaceInfo[], totalPages: number }

      for (const item of response.data) {
        // format record value
        item.assetInfo.deviceDetails.deviceType = Object.values(item.assetInfo.deviceDetails.deviceType)[0] as AssetType
        item.assetInfo.volumeProduced = tokenToNumber(item.assetInfo.volumeProduced)
        item.mwh = tokenToNumber(item.mwh)

        // convert e8s to icp
        item.lowerPriceE8S = tokenToNumber(item.lowerPriceE8S['e8s'])
        item.higherPriceE8S = tokenToNumber(item.higherPriceE8S['e8s'])
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
        priceRange.length ? [priceRange.map(price => ({ e8s: numberToToken(price) }))] : [],
        excludeCaller,
      ) as { data: MarketplaceSellersInfo[], totalPages: number }

      for (const item of response.data) {
        // format record value
        item.mwh = tokenToNumber(item.mwh)

        // get nullable object
        item.assetInfo = item.assetInfo[0]
        item.assetInfo.deviceDetails.deviceType = Object.values(item.assetInfo.deviceDetails.deviceType)[0] as AssetType
        item.assetInfo.volumeProduced = tokenToNumber(item.assetInfo.volumeProduced)

        // convert e8s to icp
        item.priceE8S = tokenToNumber(item.priceE8S['e8s'])
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
      const tx = await agent().purchaseToken(tokenId, recipent, numberToToken(amount)) as TransactionInfo
      tx.txType = Object.values(tx.txType)[0] as TxTypeDef
      tx.to = tx.to[0]
      tx.method = Object.values(tx.method)[0] as TxMethodDef
      tx.priceE8S = tx.priceE8S[0] ? tokenToNumber(tx.priceE8S[0]['e8s']) : null

      return tx
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async putOnSale(tokenId: string, quantity: number, price: TokensICP): Promise<void> {
    try {
      const res = await agent().sellToken(tokenId, numberToToken(quantity), { e8s: numberToToken(price) })
      console.log(res);
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async takeTokenOffMarket(tokenId: string, quantity: number): Promise<void> {
    try {
      await agent().takeTokenOffMarket(tokenId, numberToToken(quantity))
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }


  static async requestRedeemToken({ items, beneficiary, periodStart, periodEnd, locale }: {
    items: { id: string, volume: number }[],
    beneficiary: Principal,
    periodStart: Date,
    periodEnd: Date,
    locale: string,
  }): Promise<void> {
    try {
      await agent().requestRedeemToken(
        items.map(({ volume, id }) => ({ id, volume: numberToToken(volume) })),
        beneficiary,
        moment(periodStart).format(variables.evidentDateFormat),
        moment(periodEnd).format(variables.evidentDateFormat),
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


  static async redeemToken({ items, periodStart, periodEnd, locale }: {
    items: { id: string, volume: number }[],
    periodStart: Date,
    periodEnd: Date,
    locale: string,
  }): Promise<TransactionInfo> {
    try {
      const txs = await agent().redeemToken(
        items.map(({ volume, id }) => ({ id, volume: numberToToken(volume) })),
        moment(periodStart).format(variables.evidentDateFormat),
        moment(periodEnd).format(variables.evidentDateFormat),
        locale
      ) as TransactionInfo[]

      for (const tx of txs) {
        tx.txType = Object.values(tx.txType)[0] as TxTypeDef
        tx.to = tx.to[0]
        tx.method = Object.values(tx.method)[0] as TxMethodDef
        tx.priceE8S = tx.priceE8S[0] ? tokenToNumber(tx.priceE8S[0]['e8s']) : null
      }

      return txs[0]
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async getLedgerTransactions({ page, length, mwhRange, rangeDates, tokenId }: {
    page?: number,
    length?: number,
    mwhRange?: number[],
    rangeDates?: Date[],
    tokenId?: string,
  }): Promise<{ data: TransactionHistoryInfo[]; totalPages: number; }> {
    mwhRange ??= []
    rangeDates ??= []

    try {
      const response = await agent().getLedgerTransactions(
        page ? [page] : [],
        length ? [length] : [],
        mwhRange.length ? [mwhRange] : [],
        rangeDates.length ? [rangeDates.map(e => moment(e).format(variables.dateFormat))] : [],
        tokenId ? [tokenId] : [],
      ) as { data: TransactionHistoryInfo[]; totalPages: number; }

      for (const item of response.data) {
        // format record value
        item.tokenAmount = tokenToNumber(item.tokenAmount)
        item.txType = Object.values(item.txType)[0] as TxTypeDef
        item.method = Object.values(item.method)[0] as TxMethodDef
        item.date = new Date(item.date)

        const conversion = getFileFromArrayBuffer(item.redemptionPdf, { fileName: 'certificate', fileType: 'application/pdf' })
        item.redemptionPdf = conversion.file
        item['url'] = URL.createObjectURL(conversion.blob)

        // get nullable object
        item.to = item.to[0]
        item.assetInfo = item.assetInfo[0]
        item.assetInfo.deviceDetails.deviceType = Object.values(item.assetInfo.deviceDetails.deviceType)[0] as AssetType
        item.assetInfo.volumeProduced = tokenToNumber(item.assetInfo.volumeProduced)

        // convert e8s to icp
        item.priceE8S = item.priceE8S[0] ? tokenToNumber(item.priceE8S[0]['e8s']) : null
      }

      response.totalPages = Number(response.totalPages)

      return response
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async getPlatformTransactions({ page, length, mwhRange, rangeDates, tokenId }: {
    page?: number,
    length?: number,
    mwhRange?: number[],
    rangeDates?: Date[],
    tokenId?: string,
  }): Promise<{ data: TransactionHistoryInfo[]; totalPages: number; }> {
    mwhRange ??= []
    rangeDates ??= []

    try {
      const response = await agent().getPlatformTransactions(
        page ? [page] : [],
        length ? [length] : [],
        mwhRange.length ? [mwhRange] : [],
        rangeDates.length ? [rangeDates.map(e => moment(e).format(variables.dateFormat))] : [],
        tokenId ? [tokenId] : [],
      ) as { data: TransactionHistoryInfo[]; totalPages: number; }

      for (const item of response.data) {
        // format record value
        item.tokenAmount = tokenToNumber(item.tokenAmount)
        item.txType = Object.values(item.txType)[0] as TxTypeDef
        item.method = Object.values(item.method)[0] as TxMethodDef
        item.date = new Date(item.date)

        const conversion = getFileFromArrayBuffer(item.redemptionPdf, { fileName: 'certificate', fileType: 'application/pdf' })
        item.redemptionPdf = conversion.file
        item['url'] = URL.createObjectURL(conversion.blob)

        // get nullable object
        item.to = item.to[0]
        item.assetInfo = item.assetInfo[0]
        item.assetInfo.deviceDetails.deviceType = Object.values(item.assetInfo.deviceDetails.deviceType)[0] as AssetType
        item.assetInfo.volumeProduced = tokenToNumber(item.assetInfo.volumeProduced)

        // convert e8s to icp
        item.priceE8S = item.priceE8S[0] ? tokenToNumber(item.priceE8S[0]['e8s']) : null
      }

      response.totalPages = Number(response.totalPages)

      return response
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
        priceRange.length ? [priceRange.map(price => ({ e8s: numberToToken(price) }))] : [],
        mwhRange.length ? [mwhRange] : [],
        assetTypes.length ? [assetTypes.map(energy => ({ [energy]: energy }))] : [],
        method ? [{[method]: method}] : [],
        rangeDates.length ? [rangeDates.map(e => moment(e).format(variables.dateFormat))] : [],
        tokenId ? [tokenId] : [],
      ) as { data: TransactionHistoryInfo[]; totalPages: number; }

      for (const item of response.data) {
        // format record value
        item.tokenAmount = tokenToNumber(item.tokenAmount)
        item.txType = Object.values(item.txType)[0] as TxTypeDef
        item.method = Object.values(item.method)[0] as TxMethodDef
        item.date = new Date(item.date)

        const conversion = getFileFromArrayBuffer(item.redemptionPdf, { fileName: 'certificate', fileType: 'application/pdf' })
        item.redemptionPdf = conversion.file
        item['url'] = URL.createObjectURL(conversion.blob)

        // get nullable object
        item.to = item.to[0]
        item.assetInfo = item.assetInfo[0]
        item.assetInfo.deviceDetails.deviceType = Object.values(item.assetInfo.deviceDetails.deviceType)[0] as AssetType
        item.assetInfo.volumeProduced = tokenToNumber(item.assetInfo.volumeProduced)

        // convert e8s to icp
        item.priceE8S = item.priceE8S[0] ? tokenToNumber(item.priceE8S[0]['e8s']) : null
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
        item[1].mwh = tokenToNumber(item[1].mwh)
        item[1].assetType = Object.values(item[1].assetType)[0] as AssetType
        item[1].redemptions = tokenToNumber(item[1].redemptions)
        item[1].priceE8STrend = tokenToNumber(item[1].priceE8STrend['e8s'])
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

      res.mwh = tokenToNumber(res.mwh)
      res.assetType = Object.values(res.assetType)[0] as AssetType
      res.redemptions = tokenToNumber(res.redemptions)
      res.sells = tokenToNumber(res.sells)
      res.priceE8STrend = tokenToNumber(res.priceE8STrend['e8s'])

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
      ) as {
        data: NotificationInfo[],
        totalPages: bigint;
      }

      for (const item of res.data) {
        item.notificationType = Object.values(item.notificationType)[0] as NotificationTypeDef
        item.eventStatus = item.eventStatus[0] ? Object.values(item.eventStatus[0])[0] as NotificationEventStatusDef : null
        item.status = item.status[0] ? Object.values(item.status[0])[0] as NotificationStatusDef : null
        item.content = item.content[0]
        item.triggeredBy = item.triggeredBy[0]
        item.tokenId = item.tokenId[0]
        item.quantity = tokenToNumber(item.quantity[0]) || null
        item.createdAt = new Date(item.createdAt)
      }

      return res.data
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

  // clear notifications
  static async clearNotifications(notificationIds?: [Text]): Promise<void> {
    try {
      await agent().clearNotifications(notificationIds?.length ? [notificationIds] : []);
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