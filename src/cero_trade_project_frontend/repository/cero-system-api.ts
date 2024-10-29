import { getImageArrayBuffer, getUrlFromArrayBuffer, numberToToken } from "@/plugins/functions";
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

  static async mintTokenToUser({ user, tokenId, tokenAmount, debugMode }: {
    user: string,
    tokenId: string,
    tokenAmount: number,
    debugMode: boolean,
  }): Promise<void> {
    debugMode ||= false

    try {
      await agent().mintTokenToUser(Principal.fromText(user), tokenId, numberToToken(tokenAmount), { debugMode })
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }
}
