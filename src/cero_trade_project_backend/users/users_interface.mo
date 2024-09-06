import Principal "mo:base/Principal";

// types
import T "../types"

module UsersInterface {
  public func canister(cid: Principal): Users { actor (Principal.toText(cid)) };

  public type Users = actor {
    // ======================================== Profile ===================================================== //
    getUserToken: () -> async T.UserTokenAuth;
    updateUserToken: (token: Text) -> async();
    createProfile: (userInfo: T.UserInfo) -> async();
    storeCompanyLogo: (avatar: T.ArrayFile) -> async();
    getProfile: () -> async T.UserProfile;
    updateProfile: (form: T.UpdateUserForm) -> async();
    // ======================================== Portfolio ===================================================== //
    getSinglePortfolio: (tokenId: T.TokenId) -> async T.SinglePortfolio;
    getPortfolio: (page: ?Nat, length: ?Nat, assetTypes: ?[T.AssetType], country: ?Text, mwhRange: ?[T.TokenAmount]) -> async { data: [T.Portfolio]; totalPages: Nat; };
    addTokensPortfolio: (assets: [T.AssetInfo]) -> async();
    removeTokensPortfolio: (tokenIds: [T.TokenId]) -> async();
    updatePortfolio: ({ tokenId: T.TokenId; inMarket: ?T.TokenAmount; redemption: ?T.TransactionInfo }) -> async();
    // ======================================== Notifications ===================================================== //
    getNotification: (notificationId: T.NotificationId) -> async T.NotificationInfo;
    getNotifications: (page: ?Nat, length: ?Nat, notificationTypes: [T.NotificationType]) -> async { data: [T.NotificationInfo]; totalPages: Nat; };
    addNotification: (notification: T.NotificationInfo) -> async T.NotificationId;
    updateGeneral: (notificationIds: ?[T.NotificationId]) -> async();
    updateEvent: (notificationId: T.NotificationId, eventStatus: T.NotificationEventStatus) -> async();
    clearNotifications: (notificationIds: ?[T.NotificationId]) -> async();
    // ======================================== Beneficiaries ===================================================== //
    getBeneficiaries: () -> async [T.BID];
    checkBeneficiary: (beneficiaryId: T.BID) -> async Bool;
    addBeneficiary: (beneficiaryId: T.BID) -> async();
    removeBeneficiary: (beneficiaryId: T.BID) -> async();
    // ======================================== Transactions ===================================================== //
    getTransactions: (page: ?Nat, length: ?Nat) -> async { data: [T.TransactionId]; totalPages: Nat; };
    addTransaction: (transactionId: T.TransactionId) -> async();
    addTokensWithTransaction: (assets: T.AssetInfo, transactionId: T.TransactionId) -> async();
    updateMarketplaceWithTransaction: (inMarket: T.TokenAmount, transaction: T.TransactionInfo) -> async();
    updateRedemptions: (transaction: T.TransactionInfo) -> async();
  };
}