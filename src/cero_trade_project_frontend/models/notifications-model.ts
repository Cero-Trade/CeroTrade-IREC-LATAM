import { Principal } from "@dfinity/principal";

export enum NotificationType {
  general = "general",
  redeem = "redeem",
  beneficiary = "beneficiary",
}
export type NotificationTypeDef = keyof typeof NotificationType

export enum NotificationStatus {
  sent = "sent",
  seen = "seen",
}
export type NotificationStatusDef = keyof typeof NotificationStatus

export enum NotificationEventStatus {
  pending = "pending",
  declined = "declined",
  accepted = "accepted",
}
export type NotificationEventStatusDef = keyof typeof NotificationEventStatus

export interface NotificationInfo {
  id: string;
  title: string;
  content?: string;
  notificationType: NotificationTypeDef;
  createdAt: Date;
  status?: NotificationStatusDef;

  eventStatus?: NotificationEventStatusDef;
  tokenId?: string;
  receivedBy: Principal;
  triggeredBy?: Principal;
  quantity?: number;
}
