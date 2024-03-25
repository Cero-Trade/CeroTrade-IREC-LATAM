export class UserCanister {
    user: any
    constructor({ user }) {
      this.user = user
    }
  
    async init(): Promise<void> {
      console.log("here", this.user);
    }
  }
  