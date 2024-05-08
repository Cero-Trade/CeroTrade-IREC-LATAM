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

  static async registerToken(tokenId: string): Promise<Principal> {
    try {
      return await agent().registerToken(tokenId) as Principal
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async mintTokenToUser({ user, tokenId, tokenAmount }: {
    user: string,
    tokenId: string,
    tokenAmount: number,
  }): Promise<void> {
    try {
      await agent().mintTokenToUser(user, tokenId, tokenAmount)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }
}
