import { storageSecureCollection } from "@/plugins/vue3-storage-secure";
import { useAuthClient as client } from "@/services/icp-provider";
import { AnonymousIdentity } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";
import { useStorage } from "vue3-storage-secure";

export class AuthClientApi {
  static async signOut(returnTo?: string): Promise<void> {
    useStorage().removeStorageSync(storageSecureCollection.tokenAuth)
    await client()?.logout({ returnTo })
  }

  static async signIn(onComplete: Function): Promise<void> {
    await client().login({
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
      return false
    }
  }

  static isAnonymous(): Boolean {
    return client()?.getIdentity().getPrincipal().isAnonymous() ?? true
  }

  static getPrincipal(): Principal {
    return client()?.getIdentity().getPrincipal() ?? new AnonymousIdentity().getPrincipal()
  }
}
