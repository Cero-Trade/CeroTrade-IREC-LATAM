import variables from "@/mixins/variables";
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
    const identityProvider = process.env.DFX_NETWORK === "ic"
      ? "https://identity.ic0.app/#authorize"
      : variables.isSafari ? 
        `http://localhost:8080/?canisterId=${process.env.CANISTER_ID_INTERNET_IDENTITY}`
          :`http://${process.env.CANISTER_ID_INTERNET_IDENTITY}.localhost:8080/`;

    await client().login({
      // 7 days in nanoseconds
      identityProvider,
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
