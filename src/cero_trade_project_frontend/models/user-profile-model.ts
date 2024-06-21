import store from "@/store";
import { Principal } from "@dfinity/principal";

export class UserProfileModel {
  companyLogo: string;
  principalId: Principal;
  companyId: string;
  companyName: string;
  city: string;
  country: string;
  address: string;
  email: string;
  createdAt: Date;
  updatedAt: Date;

  static get(): UserProfileModel  {
    return store.state.profile;
  }
}
