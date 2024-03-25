export class UserIndexCanister {
    user_index: any
    constructor({ user_index }) {
      this.user_index = user_index
    }
  
    async init(): Promise<void> {
      console.log("here", this.user_index);
    }
  }
  