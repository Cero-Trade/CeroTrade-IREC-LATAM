import { useAuthClient as client } from "@/services/icp-provider";
import { Principal } from "@dfinity/principal";

export class AuthClientApi {
  static signOut(returnTo?: string): void {
    client().logout({ returnTo })
  }

  static signIn(onComplete: Function): void {
    client().login({
      // 7 days in nanoseconds
      maxTimeToLive: BigInt(7 * 24 * 60 * 60 * 1000 * 1000 * 1000),
      onSuccess: () => this.onSignedIdentity(onComplete),
    });
  }

  static onSignedIdentity(onComplete: Function): void {
    console.log("you are authenticated");

    onComplete()
  }

  static async isAuthenticated(): Promise<boolean> {
    try {
      return await client().isAuthenticated()
    } catch (error) {
      throw error.toString()
    }
  }

  static getPrincipal(): Principal {
    return client().getIdentity().getPrincipal()
  }
}
