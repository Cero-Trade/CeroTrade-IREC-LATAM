import { getImageArrayBuffer, getUrlFromArrayBuffer } from "@/plugins/functions";
import { useAgentCanister as agent, getErrorMessage } from "@/services/icp-provider";
import { Principal } from "@dfinity/principal";

export class CeroSystemApi {
  static async registerWasmModule(input: string): Promise<void> {
    try {
      await agent().registerWasmModule({[input]: input})
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  // static async registerToken({ tokenId, name, symbol, logo }: {
  //   tokenId: string,
  //   name: string,
  //   symbol: string,
  //   logo: File[]
  // }): Promise<Principal> {
  //   const logoUrl = getUrlFromArrayBuffer(getImageArrayBuffer(logo[0]))

  //   try {
  //     return await agent().registerToken(tokenId, name, symbol, logoUrl) as Principal
  //   } catch (error) {
  //     console.error(error);
  //     throw getErrorMessage(error)
  //   }
  // }

  static async mintTokenToUser({ user, tokenId, tokenAmount }: {
    user: string,
    tokenId: string,
    tokenAmount: number,
  }): Promise<void> {
    try {
      await agent().mintTokenToUser(Principal.fromText(user), tokenId, tokenAmount)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }
}
