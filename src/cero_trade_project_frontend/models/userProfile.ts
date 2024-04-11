import store from "@/store";

export class UserProfileModel {
  companyLogo: string

  static get(): UserProfileModel  {
    return store.state.profile;
  }
}
