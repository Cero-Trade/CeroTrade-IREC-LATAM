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
  }): Promise<string> {
    try {
      const fileCompressed = await fileCompression(data.companyLogo[0]),
      arrayBuffer = await getImageArrayBuffer(fileCompressed),
      userForm = JSON.stringify({...data, companyLogo: arrayBuffer})

      return await agent().register(userForm) as string
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }
}