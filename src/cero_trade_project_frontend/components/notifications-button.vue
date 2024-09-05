<template>
  <modal-approve
    ref="modalApprove"
    :token-id="currentNotificationEvent?.tokenId"
    @approve="redeemRequested"
    @close="loadingExecute = null"
  ></modal-approve>

  <v-menu v-model="menuNotifications" width="400" height="498" offset="10" location="bottom center" content-class="notifications-menu" :close-on-content-click="false">
    <template #activator="{ props }">
      <v-badge v-model="showBadge" color="rgb(var(--v-theme-primary))">
        <v-btn color="grey" variant="text" size="30" v-bind="props">
          <img src="@/assets/sources/icons/bell.svg" alt="bell icon">
        </v-btn>

        <template #badge>
          <span class="text-black">{{ getTabLength() }}</span>
        </template>
      </v-badge>
    </template>

    <v-list class="px-3 py-4">
      <div class="flex-space-center">
        <h5 class="mb-0">Notifications</h5>

        <v-btn
          variant="text"
          color="#667085"
          :disabled="!tabs[0].data?.length"
          :loading="loadingClear"
          :class="{ hidden: currentTab !== 0 }"
          @click="clearGeneralNotifications"
        >Clear notifications</v-btn>
      </div>

      <v-tabs v-model="currentTab" height="32">
        <v-tab v-for="(item, i) in tabs" :key="i">
          {{ item.text }}

          <v-btn
            v-if="getTabLength(item)"
            size="20"
            color="#333"
            class="pa-0 ml-1"
            style="border-radius: 6px !important;"
          >
            <span style="font-size: 10px !important;">{{ getTabLength(item) }}</span>
          </v-btn>
        </v-tab>

        <div class="ml-auto">
          <v-btn size="32" variant="text" color="#333" :disabled="loadingData" :class="{ 'rotate-infinite': loadingData }" @click="getData(currentTab)">
            <img src="@/assets/sources/icons/reload-icon.png" alt="reload icon" style="width: 22px; height: 22px">
          </v-btn>

          <v-btn size="32" variant="text" color="#333">
            <img src="@/assets/sources/icons/config.svg" alt="config icon" style="filter: invert(70%);">
          </v-btn>
        </div>
      </v-tabs>

      <v-divider class="mb-3" style="translate: 0 -2px;" />

      <section>
        <span v-if="!tabs[currentTab].data?.length" class="d-flex justify-center">
          {{ currentTab === 0 ? 'Notifications not found' : 'Events not found' }}
        </span>

        <template v-for="(item, i) in tabs[currentTab].data" :key="i">
          <div class="d-flex mb-1" style="width: 100%">
            <img src="@/assets/sources/images/avatar.png" alt="notification icon" class="mr-2" style="width: 40px; height: 40px;">

            <div class="flex-column">
              <div class="mb-1 d-flex align-center">
                <h6 class="mb-0">{{ item.title }}</h6>
                <v-badge :model-value="item.status === NotificationStatus.sent" dot :offset-x="-15" color="rgb(var(--v-theme-primary))">
                  <span class="date-text ml-3">{{ moment(item.createdAt).fromNow() }}</span>
                </v-badge>
              </div>

              <p v-if="item.content">{{ item.content }}</p>
              <p v-else>status: 
                <v-chip
                  density="compact"
                  :style="`--color: rgb(var(--v-theme-${item.eventStatus === NotificationEventStatus.accepted
                    ? 'success'
                    : item.eventStatus === NotificationEventStatus.declined 
                      ? 'error'
                      : 'warning'}))`
                  "
                  color="var(--color)"
                  style="
                    font-weight: 500 !important;
                    border: 1.5px solid var(--color);
                    border-radius: 60px !important;
                    text-transform: capitalize !important;
                    font-size: 13px !important;
                  "
                >{{ item.eventStatus }}</v-chip>
              </p>

              <v-btn
                v-if="item.notificationType === NotificationType.general"
                height="28"
                min-height="28"
                width="min-content"
                min-width="min-content"
                variant="text"
                color="#667085"
                class="px-2"
                style="translate: -8px 0;"
                :loading="loadingDismiss === item.id"
                @click="dismiss(item)"
              >Dismiss</v-btn>

              <template v-else>
                <div class="d-flex" style="gap: 10px;">
                  <v-btn
                    height="28"
                    min-height="28"
                    width="min-content"
                    min-width="min-content"
                    variant="text"
                    color="#667085"
                    class="px-2"
                    style="translate: -8px 0;"
                    :loading="loadingDismiss === item.id"
                    @click="dismiss(item)"
                  >{{ isReceiver(item) ? 'Decline' : 'Dismiss' }}</v-btn>

                  <v-btn
                    v-if="isReceiver(item) && item.eventStatus === NotificationEventStatus.pending"
                    height="28"
                    min-height="28"
                    width="min-content"
                    min-width="min-content"
                    variant="text"
                    class="px-2"
                    style="translate: -8px 0;"
                    :loading="loadingExecute === item.id"
                    @click="execute(item)"
                  >Accept</v-btn>
                </div>
              </template>
            </div>
          </div>

          <v-divider v-if="i + 1 !== (tabs[currentTab].data?.length ?? 0)" class="mb-2" />
        </template>
      </section>
    </v-list>
  </v-menu>
</template>

<script setup>
import ModalApprove from '@/components/modals/modal-approve.vue'
import { NotificationEventStatus, NotificationStatus, NotificationType } from '@/models/notifications-model';
import { UserProfileModel } from '@/models/user-profile-model';
import { AgentCanister } from '@/repository/agent-canister';
import { computed, onBeforeMount, ref, watch } from 'vue';
import { useToast } from 'vue-toastification';
import moment from 'moment'
import { closeLoader, showLoader } from '@/plugins/functions';

const
  toast = useToast(),

profile = UserProfileModel.get(),
menuNotifications = ref(false),
loadingData = ref(false),
currentTab = ref(0),
tabs = ref([
  {
    key: [NotificationType.general],
    text: "General",
    data: undefined
  },
  {
    key: [NotificationType.beneficiary, NotificationType.redeem],
    text: "Events",
    data: undefined
  },
]),
loadingSeen = ref(false),
loadingClear = ref(false),
loadingDismiss = ref(null),
loadingExecute = ref(null),

modalApprove = ref(),

currentNotificationEvent = computed(() => tabs.value[1].data?.find(e => e.id === loadingExecute.value))


function isReceiver(item) {
  return item.receivedBy?.toString() === profile.principalId.toString()
}

function getTabLength(item) {
  if (!item) {
    let values = []
    for (const item of tabs.value) {
      const array = item.data?.filter(e => e?.status !== NotificationStatus.seen);
      if (!array) continue
      values = values.concat(array)
    }

    return values.length
  }

  if (item.key.includes(NotificationType.general)) return item.data?.filter(e => e.status === NotificationStatus.sent)?.length

  return item.data?.length
}
const showBadge = computed(() => !!getTabLength())

watch(menuNotifications, (_) => markNotificationsAsSeen())

onBeforeMount(getData)

async function getData(tab) {
  if (loadingData.value) return
  loadingData.value = true

  const notificationTypes = tab != null ? tabs.value[tab].key : tabs.value.flatMap(e => e.key)

  try {
    const response = await AgentCanister.getNotifications(null, null, notificationTypes)

    for (const tab of tabs.value) {
      const notifications = response.filter(e => tab.key.includes(e.notificationType))
      if (notifications.length) tab.data = notifications
    }

    markNotificationsAsSeen()
  } catch (error) {
    for (let i = 0; i < tabs.value.length; i++)
      tabs.value[i].data = []
    toast.error(error)
  }

  loadingData.value = false
}

async function markNotificationsAsSeen() {
  if (!menuNotifications.value || loadingSeen.value) return
  loadingSeen.value = true

  try {
    const [generalTab] = tabs.value,
    notificationIds = generalTab.data?.filter(e => e.status === NotificationStatus.sent).map(e => e.id)
    if (!notificationIds?.length) return

    await AgentCanister.updateGeneralNotifications(notificationIds)

    for (const id of notificationIds) {
      const index = tabs.value[0].data.findIndex(e => e.id === id)
      tabs.value[0].data[index].status = NotificationStatus.sent
    }
  } catch (error) {
    toast.error(error)
  }

  loadingSeen.value = false
}

async function clearGeneralNotifications() {
  if (loadingClear.value) return
  loadingClear.value = true

  try {
    const [generalTab] = tabs.value,
    notificationIds = generalTab.data?.map(e => e.id)
    if (!notificationIds?.length) return

    await AgentCanister.clearNotifications(notificationIds)

    tabs.value[0].data = []
  } catch (error) {
    toast.error(error)
  }

  loadingClear.value = false
}

async function dismiss(item) {
  if (loadingDismiss.value || loadingExecute.value) return
  loadingDismiss.value = item.id

  try {
    if (item.notificationType === NotificationType.general) {
      await AgentCanister.clearNotifications([item.id])
    } else {
      await AgentCanister.updateEventNotification(item.id, NotificationEventStatus.declined)
    }

    const index = tabs.value[currentTab.value].data.findIndex(e => e.id === item.id)
    tabs.value[currentTab.value].data.splice(index, 1)
  } catch (error) {
    toast.error(error)
  }

  loadingDismiss.value = null
}

async function execute(item) {
  if (loadingExecute.value || loadingDismiss.value || !isReceiver(item)) return
  loadingExecute.value = item.id

  try {
    switch (item.notificationType) {

      case NotificationType.beneficiary:
          await AgentCanister.addBeneficiaryRequested(item.id)
        break;

      case NotificationType.redeem:
          modalApprove.value.showModal(item)
        return;
    }

    const index = tabs.value[currentTab.value].data.findIndex(e => e.id === item.id)
    tabs.value[currentTab.value].data.splice(index, 1)

  } catch (error) {
    toast.error(error)
  }

  loadingExecute.value = null
}

async function redeemRequested(item) {
  showLoader()

  try {
    await AgentCanister.redeemTokenRequested(item.id)

    const index = tabs.value[currentTab.value].data.findIndex(e => e.id === item.id)
    tabs.value[currentTab.value].data.splice(index, 1)
  } catch (error) {
    toast.error(error.toString())
  }

  closeLoader()
}
</script>

<style lang="scss">
.notifications-menu {
  > * {
    overflow: hidden !important;
  }

  .v-list {
    border-radius: 12px !important;

    section {
      overflow-y: auto;
      overflow-x: hidden;
      height: calc(100% - (26px * 3));
    }
  }

  h5 {
    font-size: 18px !important;
    font-weight: 700 !important;
  }

  .date-text {
    font-size: 12px !important;
    color: #667085 !important;
  }

  h6 {
    font-size: 13.5px !important;
    font-weight: 700 !important;
  }

  p {
    font-size: 12.5px !important;
  }

  .v-btn--variant-text span {
    font-size: 12px !important;
    font-weight: 600 !important;
  }

  .v-tab {
    width: min-content !important;
    min-width: min-content !important;
    border: none !important;
    padding-inline: 6px;
    border-radius: 10px !important;
  }
}
</style>
