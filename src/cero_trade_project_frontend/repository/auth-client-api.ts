export class ClientAuthApi {
    client: any
    constructor({ client }) {
      this.client = client
    }
  
    signOut(returnTo?: string): void {
      this.client.logout({ returnTo })
    }
  
    signIn(onComplete: Function): void {
      this.client.login({
        // 7 days in nanoseconds
        maxTimeToLive: BigInt(7 * 24 * 60 * 60 * 1000 * 1000 * 1000),
        onSuccess: () => this.onSignedIdentity(onComplete),
      });
    }
  
    onSignedIdentity(onComplete: Function): void {
      console.log("you are authenticated");
  
      onComplete()
    }
  }
  