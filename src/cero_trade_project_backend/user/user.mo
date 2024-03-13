import UserTypes = "./user_types";

actor User {
    public func echoUser() : async UserTypes.User {
        return UserTypes.exampleUser();
    }
}
