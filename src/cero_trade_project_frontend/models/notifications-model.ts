import { Principal } from "@dfinity/principal";

export enum NotificationType {
  general = "general",
  redeem = "redeem",
  beneficiary = "beneficiary",
}
export type NotificationTypeDef = keyof typeof NotificationType

export interface NotificationInfo {
  id: string;
  title: string;
  content: string;
  notificationType: string;
  tokenId?: string;
  callerBeneficiaryId?: Principal;
  quantity?: number;
  createdAt: Date;
}
