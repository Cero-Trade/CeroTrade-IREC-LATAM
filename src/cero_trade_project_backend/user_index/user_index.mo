import UserIndexTypes = "./user_index_types";

actor UserIndex {
    public func echoUserIndex() : async UserIndexTypes.UserIndex {
        return UserIndexTypes.exampleUserIndex();
    }
}
