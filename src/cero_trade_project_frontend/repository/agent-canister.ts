import { fileCompression, getImageArrayBuffer } from "@/plugins/functions";
import { useAgentCanister as agent, getErrorMessage } from "@/services/icp-provider";

export class AgentCanister {
  static async register(data: {
    companyID: string,
    companyName: string,
    companyLogo: [File],
    country: string,
    city: string,
    address: string,
    email: string,
  }): Promise<void> {
    try {
      const fileCompressed = await fileCompression(data.companyLogo[0]),
      arrayBuffer = await getImageArrayBuffer(fileCompressed),
      userForm = JSON.stringify({...data, companyLogo: arrayBuffer})

      await agent().register(userForm)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async login(): Promise<void> {
    try {
      await agent().login()
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }
}