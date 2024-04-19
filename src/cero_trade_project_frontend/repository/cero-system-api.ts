import { useAgentCanister as agent, getErrorMessage } from "@/services/icp-provider";

export class CeroSystemApi {
  // TODO invest how to generate correctly array from wasm module
  // static async generateWasmModule(input: string): Promise<void> {
  //   try {
  //     let module: Response,
  //     moduleName = {};
  //     moduleName[input] = input
  
  //     switch (input) {
  //       case "users": module = await fetch('../../../.dfx/local/canisters/users');
  //         break;
  //       case "transactions": module = await fetch('../../../.dfx/local/canisters/transactions');
  //         break;
  //       case "token": module = await fetch('../../../.dfx/local/canisters/token');
  //         break;
  //     }

  //     const data = await module.arrayBuffer(),
  //     nat8Array = Array.from(new Uint8Array(data));

  //     const res = await agent().registerTokenWasmModule(moduleName, nat8Array)
  //     console.log(res);
  //   } catch (error) {
  //     console.error(error);
  //     throw getErrorMessage(error)
  //   }
  // }

  static async generateWasmModule(moduleName: string, wasmModule: [number]): Promise<void> {
    try {
      const res = await agent().registerTokenWasmModule(moduleName, wasmModule)
      console.log(res);
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }
}
