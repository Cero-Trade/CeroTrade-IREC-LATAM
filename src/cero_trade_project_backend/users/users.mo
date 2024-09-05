import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Source "mo:uuid/async/SourceV4";
import UUID "mo:uuid/UUID";


// types
import T "../types";

shared({ caller = userIndexCaller }) actor class Users() = this {
  private func _callValidation(caller: Principal) { assert userIndexCaller == caller or Principal.fromActor(this) == caller };

  /// funcs to persistent collection state
  system func preupgrade() {
    portfolioEntries := Iter.toArray(portfolio.entries());

    notificationsEntries := Iter.toArray(notifications.entries());
  };
  system func postupgrade() {
    portfolio := HM.fromIter<T.TokenId, T.SinglePortfolio>(portfolioEntries.vals(), 16, Text.equal, Text.hash);
    portfolioEntries := [];

    notifications := HM.fromIter<T.NotificationId, T.NotificationInfo>(notificationsEntries.vals(), 16, Text.equal, Text.hash);
    notificationsEntries := [];
  };

  // constants
  stable let notInitialized: Text = "Canister not initialized";

  // ======================================================================================================== //
  // ======================================== Profile ===================================================== //
  // ======================================================================================================== //
  stable var userInfo: ?T.UserInfo = null;


  /// get vaultToken
  public shared({ caller }) func getUserToken() : async T.UserTokenAuth {
    _callValidation(caller);

    switch (userInfo) {
      case(null) throw Error.reject(notInitialized);
      case(?info) return info.vaultToken;
    };
  };

  /// update token stored
  public shared({ caller }) func updateUserToken(token: Text): async() {
    _callValidation(caller);

    let info = switch(userInfo) {
      case(null) throw Error.reject(notInitialized);
      case(?value) value;
    };

    userInfo := ?{ info with vaultToken = token };
  };


  /// store user company logo
  public shared({ caller }) func storeCompanyLogo(avatar: T.ArrayFile): async() {
    _callValidation(caller);

    let info = switch(userInfo) {
      case(null) throw Error.reject(notInitialized);
      case(?value) value;
    };

    userInfo := ?{ info with companyLogo = ?avatar };
  };

  /// initialize user info data
  public shared({ caller }) func createProfile(info: T.UserInfo): async() {
    _callValidation(caller);
    assert userInfo == null;

    userInfo := ?info;
  };

  /// get user profile
  public shared({ caller }) func getProfile() : async T.UserProfile {
    _callValidation(caller);

    let info = switch (userInfo) {
      case(null) throw Error.reject(notInitialized);
      case(?value) value;
    };

    switch(info.companyLogo) {
      case(null) throw Error.reject("Logo not found");
      case(?companyLogo) return {
        companyLogo;
        principalId = info.principal;
        companyId = info.companyId;
        companyName = info.companyName;
        city = info.city;
        country = info.country;
        address = info.address;
        email = info.email;
      };
    }
  };


  /// update user collection
  public shared({ caller }) func updateProfile(form: T.UpdateUserForm) : async() {
    _callValidation(caller);

    let info = switch(userInfo) {
      case(null) throw Error.reject(notInitialized);
      case(?value) value;
    };

    userInfo := ?{
      info with
      companyId = form.companyId;
      companyName = form.companyName;
      country = form.country;
      city = form.city;
      address = form.address;
      email = form.email;
    };
  };


  // ======================================================================================================== //
  // ======================================== Portfolio ===================================================== //
  // ======================================================================================================== //
  var portfolio: HM.HashMap<T.TokenId, T.SinglePortfolio> = HM.HashMap(16, Text.equal, Text.hash);
  stable var portfolioEntries : [(T.TokenId, T.SinglePortfolio)] = [];

  // get single portfolio
  public shared({ caller }) func getSinglePortfolio(tokenId: T.TokenId): async T.SinglePortfolio {
    _callValidation(caller);

    switch(portfolio.get(tokenId)) {
      case(null) throw Error.reject("Token not found in user portfolio");
      case(?value) value;
    };
  };

  // get portfolio
  public shared({ caller }) func getPortfolio(page: ?Nat, length: ?Nat, assetTypes: ?[T.AssetType], country: ?Text, mwhRange: ?[T.TokenAmount]): async {
    data: [T.Portfolio];
    totalPages: Nat;
  } {
    _callValidation(caller);

    // define page based on statement
    let startPage = switch(page) {
      case(null) 1;
      case(?value) value;
    };

    // define length based on statement
    let maxLength = switch(length) {
      case(null) 50;
      case(?value) value;
    };

    let portfolioFiltered = Buffer.Buffer<T.Portfolio>(50);

    // calculate range of elements returned
    let startIndex: Nat = (startPage - 1) * maxLength;
    var i = 0;

    Debug.print(debug_show ("before getPortfolio: " # Nat.toText(Cycles.balance())));


    for({ tokenInfo; redemptions } in portfolio.vals()) {
      if (i >= startIndex and i < startIndex + maxLength) {
        // filter by filterRange
        let filterRange: Bool = switch(mwhRange) {
          case(null) true;
          case(?range) tokenInfo.totalAmount >= range[0] and tokenInfo.totalAmount <= range[1];
        };

        // filter by assetTypes
        let filterAssetType = switch (assetTypes) {
          case(null) true;
          case(?assets) {
            let assetType = Array.find<T.AssetType>(assets, func (assetType) { assetType == tokenInfo.assetInfo.deviceDetails.deviceType });
            assetType != null
          };
        };

        // filter by country
        let filterCountry = switch (country) {
          case(null) true;
          case(?value) tokenInfo.assetInfo.specifications.country == value;
        };

        if (filterRange and filterAssetType and filterCountry) portfolioFiltered.add({
          tokenInfo;
          redemptions = Array.map<T.TransactionInfo, T.TokenAmount>(redemptions, func x = x.tokenAmount);
        });
      };
      i += 1;
    };


    Debug.print(debug_show ("later getPortfolio: " # Nat.toText(Cycles.balance())));

    var totalPages: Nat = i / maxLength;
    if (totalPages <= 0) totalPages := 1;

    {
      data = Buffer.toArray<T.Portfolio>(portfolioFiltered);
      totalPages;
    }
  };

  /// add single portfolio
  public shared({ caller }) func addPortfolio(assetInfo: T.AssetInfo): async() {
    _callValidation(caller);

    let tokenId = assetInfo.tokenId;

    portfolio.put(tokenId, {
      tokenInfo = {
        tokenId;
        assetInfo;
        totalAmount = 0;
        inMarket = 0;
      };
      redemptions = [];
    });
  };

  /// remove single portfolio
  public shared({ caller }) func removePortfolio(tokenId: T.TokenId): async() {
    _callValidation(caller);
    portfolio.delete(tokenId);
  };

  /// update portfolio
  public shared({ caller }) func updatePortfolio({ tokenId: T.TokenId; inMarket: ?T.TokenAmount = amountInMarket; redemption: ?T.TransactionInfo }): async() {
    _callValidation(caller);

    let singlePortfolio = switch(portfolio.get(tokenId)) {
      case(null) throw Error.reject("Token not found in user portfolio");
      case(?value) value;
    };


    let inMarket = switch(amountInMarket) {
      case(null) singlePortfolio.tokenInfo.inMarket;
      case(?value) value;
    };

    let redemptions = switch(redemption) {
      case(null) singlePortfolio.redemptions;
      case(?value) {
        let exists = Array.find<T.TransactionInfo>(singlePortfolio.redemptions, func x = x.transactionId == value.transactionId);
        if (exists != null) throw Error.reject("Redemption already exists");

        Array.flatten<T.TransactionInfo>([singlePortfolio.redemptions, [value]]);
      };
    };

    portfolio.put(tokenId, {
      singlePortfolio with 
      tokenInfo = { singlePortfolio.tokenInfo with inMarket; };
      redemptions;
    });
  };



  // ======================================================================================================== //
  // ======================================== Notifications ===================================================== //
  // ======================================================================================================== //
  var notifications: HM.HashMap<T.NotificationId, T.NotificationInfo> = HM.HashMap(16, Text.equal, Text.hash);
  stable var notificationsEntries : [(T.NotificationId, T.NotificationInfo)] = [];

  private func generateNotificationId(): async Text {
    let g = Source.Source();
    UUID.toText(await g.new());
  };

  // get notifications
  public shared({ caller }) func getNotification(notificationId: T.NotificationId): async T.NotificationInfo {
    _callValidation(caller);

    switch(notifications.get(notificationId)) {
      case(null) throw Error.reject("Notification not found");
      case(?value) value;
    };
  };

  // get notifications
  public shared({ caller }) func getNotifications(page: ?Nat, length: ?Nat, notificationTypes: [T.NotificationType]): async {
    data: [T.NotificationInfo];
    totalPages: Nat;
  } {
    _callValidation(caller);

    // define page based on statement
    let startPage = switch(page) {
      case(null) 1;
      case(?value) value;
    };

    // define length based on statement
    let maxLength = switch(length) {
      case(null) 50;
      case(?value) value;
    };

    let notificationsFiltered = Buffer.Buffer<T.NotificationInfo>(50);

    // calculate range of elements returned
    let startIndex: Nat = (startPage - 1) * maxLength;
    var i = 0;

    Debug.print(debug_show ("before getNotifications: " # Nat.toText(Cycles.balance())));


    for(notification in notifications.vals()) {
      if (i >= startIndex and i < startIndex + maxLength) {
        // filter by notificationTypes
        let filterNotificationType = switch (notificationTypes.size() < 1) {
          case(true) true;
          case(false) {
            let notificationType = Array.find<T.NotificationType>(notificationTypes, func (notificationType) { notificationType == notification.notificationType });
            notificationType != null
          };
        };

        if (filterNotificationType) notificationsFiltered.add(notification);
      };
      i += 1;
    };


    Debug.print(debug_show ("later getNotifications: " # Nat.toText(Cycles.balance())));

    var totalPages: Nat = i / maxLength;
    if (totalPages <= 0) totalPages := 1;

    {
      data = Buffer.toArray<T.NotificationInfo>(notificationsFiltered);
      totalPages;
    }
  };

  /// add notification
  public shared({ caller }) func addNotification(notification: T.NotificationInfo): async T.NotificationId {
    _callValidation(caller);

    let id = await generateNotificationId();
    let buildNotification = { notification with id };

    notifications.put(buildNotification.id, buildNotification);
    id
  };

  /// clear notifications
  public shared({ caller }) func clearNotifications(notificationIds: ?[T.NotificationId]): async() {
    _callValidation(caller);

    switch(notificationIds) {
      case(null) {
        for(notification in notifications.keys()) {
          notifications.delete(notification);
        };
      };

      case(?value) {
        for(notification in value.vals()) {
          notifications.delete(notification);
        };
      };
    };
  };

  /// update general notification statuses
  public shared({ caller }) func updateGeneral(notificationIds: ?[T.NotificationId]): async() {
    _callValidation(caller);

    switch(notificationIds) {
      case(null) {
        for((id, notification) in notifications.entries()) {
          if (notification.notificationType == #general("general")) {
            notifications.put(id, { notification with status = ?#seen("seen") });
          };
        };
      };

      case(?value) {
        for(notificationId in value.vals()) {
          let notification = switch(notifications.get(notificationId)) {
            case(null) throw Error.reject("Notification not found");
            case(?value) value;
          };

          if (notification.notificationType == #general("general")) {
            notifications.put(notificationId, { notification with status = ?#seen("seen") });
          };
        };
      };
    };
  };

  /// update event notification statuses
  public shared({ caller }) func updateEvent(notificationId: T.NotificationId, eventStatus: T.NotificationEventStatus): async() {
    _callValidation(caller);

    var notification = switch(notifications.get(notificationId)) {
      case(null) throw Error.reject("Notification not found");
      case(?value) value;
    };

    if (notification.notificationType != #general("general")) {
      notification := { notification with eventStatus = ?eventStatus };
    };

    notifications.put(notificationId, notification);
  };



  // ======================================================================================================== //
  // ======================================== Beneficiaries ===================================================== //
  // ======================================================================================================== //
  stable var beneficiaries: [T.BID] = [];

  public shared({ caller }) func getBeneficiaries(): async [T.BID] {
    _callValidation(caller);
    beneficiaries
  };

  public shared({ caller }) func checkBeneficiary(beneficiaryId: T.BID): async Bool {
    _callValidation(caller);
    Array.find<T.BID>(beneficiaries, func x = x == beneficiaryId) != null;
  };

  public shared({ caller }) func addBeneficiary(beneficiaryId: T.BID): async() {
    _callValidation(caller);

    let exists = Array.find<T.BID>(beneficiaries, func x = x == beneficiaryId);
    if (exists != null) throw Error.reject("Beneficiary already exists");

    beneficiaries := Array.flatten<T.BID>([beneficiaries, [beneficiaryId]]);
  };

  public shared({ caller }) func removeBeneficiary(beneficiaryId: T.BID): async() {
    _callValidation(caller);

    let exists = Array.find<T.BID>(beneficiaries, func x = x == beneficiaryId);
    if (exists == null) throw Error.reject("Beneficiary doesn't exists");

    beneficiaries := Array.filter<T.BID>(beneficiaries, func x = x != beneficiaryId);
  };



  // ======================================================================================================== //
  // ======================================== Transactions ===================================================== //
  // ======================================================================================================== //
  stable var transactions: [T.TransactionId] = [];

  public shared ({ caller }) func getTransactions(page: ?Nat, length: ?Nat): async {
    data: [T.TransactionId];
    totalPages: Nat;
  } {
    _callValidation(caller);

    // define page based on statement
    let startPage = switch(page) {
      case(null) 1;
      case(?value) value;
    };

    // define length based on statement
    let maxLength = switch(length) {
      case(null) 50;
      case(?value) value;
    };

    let txFiltered = Buffer.Buffer<T.TransactionId>(50);

    // calculate range of elements returned
    let startIndex: Nat = (startPage - 1) * maxLength;
    var i = 0;

    for (txId in transactions.vals()) {
      if (i >= startIndex and i < startIndex + maxLength) txFiltered.add(txId);
      i += 1;
    };

    var totalPages: Nat = i / maxLength;
    if (totalPages <= 0) totalPages := 1;

    { data = Buffer.toArray<T.TransactionId>(txFiltered); totalPages }
  };

  public shared({ caller }) func addTransaction(transactionId: T.TransactionId): async() {
    _callValidation(caller);

    let exists = Array.find<T.TransactionId>(transactions, func x = x == transactionId);
    if (exists != null) throw Error.reject("Transaction already exists");

    transactions := Array.flatten<T.TransactionId>([transactions, [transactionId]]);
  };

  public shared({ caller }) func updateMarketplace(tokenId: T.TokenId, inMarket: T.TokenAmount, transactionId: T.TransactionId): async() {
    _callValidation(caller);

    await updatePortfolio({ tokenId; inMarket = ?inMarket; redemption = null });

    await addTransaction(transactionId);
  };
}
