<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import BulkCampaignCreateDialog from 'dashboard/components-next/Campaigns/BulkCampaignCreateDialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const createDialog = ref(null);
const sendingId = ref(null);
const actionId = ref(null);
const cancelTarget = ref(null);
const cancelDialogRef = ref(null);

const campaigns = useMapGetter('whatsappBulkCampaigns/getAll');
const uiFlags = useMapGetter('whatsappBulkCampaigns/getUIFlags');
const isEmpty = computed(
  () => !uiFlags.value.isFetching && campaigns.value.length === 0
);

let pollInterval = null;
const hasActiveCampaigns = computed(() =>
  campaigns.value.some(c => ['queued', 'running'].includes(c.status))
);

const startPoll = () => {
  if (pollInterval) return;
  pollInterval = setInterval(() => {
    if (hasActiveCampaigns.value) {
      store.dispatch('whatsappBulkCampaigns/get');
    }
  }, 5000);
};

const stopPoll = () => {
  if (pollInterval) {
    clearInterval(pollInterval);
    pollInterval = null;
  }
};

onMounted(() => {
  store.dispatch('whatsappBulkCampaigns/get');
  startPoll();
});

onUnmounted(() => {
  stopPoll();
});

const statusLabels = {
  draft: 'CAMPAIGN.WHATSAPP.STATUS.DRAFT',
  validating: 'CAMPAIGN.WHATSAPP.STATUS.VALIDATING',
  scheduled: 'CAMPAIGN.WHATSAPP.STATUS.SCHEDULED',
  queued: 'CAMPAIGN.WHATSAPP.STATUS.QUEUED',
  running: 'CAMPAIGN.WHATSAPP.STATUS.RUNNING',
  paused: 'CAMPAIGN.WHATSAPP.STATUS.PAUSED',
  completed: 'CAMPAIGN.WHATSAPP.STATUS.COMPLETED',
  completed_with_errors: 'CAMPAIGN.WHATSAPP.STATUS.COMPLETED_WITH_ERRORS',
  failed: 'CAMPAIGN.WHATSAPP.STATUS.FAILED',
  cancelled: 'CAMPAIGN.WHATSAPP.STATUS.CANCELLED',
};

const statusColors = {
  draft: 'bg-n-alpha-2 text-n-slate-12',
  validating: 'bg-n-yellow-3 text-n-yellow-11',
  scheduled: 'bg-n-blue-3 text-n-blue-11',
  queued: 'bg-n-blue-3 text-n-blue-11',
  running: 'bg-n-green-3 text-n-green-11',
  paused: 'bg-n-yellow-3 text-n-yellow-11',
  completed: 'bg-n-green-4 text-n-green-11',
  completed_with_errors: 'bg-n-yellow-3 text-n-yellow-11',
  failed: 'bg-n-red-3 text-n-red-11',
  cancelled: 'bg-n-slate-4 text-n-slate-11',
};

const refresh = () => store.dispatch('whatsappBulkCampaigns/get');

const send = async campaign => {
  sendingId.value = campaign.id;
  try {
    await store.dispatch('whatsappBulkCampaigns/send', campaign.id);
    useAlert(t('CAMPAIGN.WHATSAPP.API.SEND_SUCCESS'));
    refresh();
  } catch {
    useAlert(t('CAMPAIGN.WHATSAPP.API.SEND_ERROR'));
  } finally {
    sendingId.value = null;
  }
};

const doAction = async (action, campaign) => {
  actionId.value = campaign.id;
  try {
    await store.dispatch(`whatsappBulkCampaigns/${action}`, campaign.id);
    const key = action.toUpperCase();
    useAlert(t(`CAMPAIGN.WHATSAPP.API.${key}_SUCCESS`));
    refresh();
  } catch {
    const key = action.toUpperCase();
    useAlert(t(`CAMPAIGN.WHATSAPP.API.${key}_ERROR`));
  } finally {
    actionId.value = null;
  }
};

const confirmCancel = campaign => {
  cancelTarget.value = campaign;
  cancelDialogRef.value?.open();
};

const handleCancelConfirm = async () => {
  if (!cancelTarget.value) return;
  await doAction('cancel', cancelTarget.value);
  cancelDialogRef.value?.close();
  cancelTarget.value = null;
};

const canSend = c => ['draft', 'validating'].includes(c.status);
const canPause = c => c.status === 'running';
const canResume = c => c.status === 'paused';
const canCancel = c =>
  !['completed', 'completed_with_errors', 'cancelled', 'failed'].includes(
    c.status
  );

const openDetail = campaign => {
  router.push({
    name: 'campaigns_whatsapp_detail',
    params: { campaignId: campaign.id },
  });
};
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.WHATSAPP.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.WHATSAPP.NEW_CAMPAIGN')"
    @click="createDialog?.open()"
  >
    <template #action>
      <BulkCampaignCreateDialog ref="createDialog" />
    </template>

    <!-- Cancel confirmation -->
    <Dialog
      ref="cancelDialogRef"
      type="alert"
      :title="t('CAMPAIGN.WHATSAPP.CONFIRM.CANCEL_TITLE')"
      :description="t('CAMPAIGN.WHATSAPP.CONFIRM.CANCEL_DESC')"
      :confirm-button-label="t('CAMPAIGN.WHATSAPP.CONFIRM.CANCEL_CONFIRM')"
      @confirm="handleCancelConfirm"
    />

    <div v-if="uiFlags.isFetching" class="flex justify-center py-12">
      <Spinner />
    </div>
    <div v-else-if="isEmpty" class="py-14 text-center">
      <p class="text-base font-medium text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.EMPTY_STATE.TITLE') }}
      </p>
      <p class="mt-2 text-sm text-n-slate-11">
        {{ t('CAMPAIGN.WHATSAPP.EMPTY_STATE.SUBTITLE') }}
      </p>
    </div>
    <div v-else class="grid gap-4">
      <article
        v-for="campaign in campaigns"
        :key="campaign.id"
        class="p-5 border rounded-xl border-n-weak bg-n-surface-2 cursor-pointer hover:border-n-blue-6 transition-colors"
        @click="openDetail(campaign)"
      >
        <div class="flex items-start justify-between gap-4">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-3">
              <p class="font-semibold text-n-slate-12 truncate">
                {{ campaign.name }}
              </p>
              <span
                class="px-2 py-0.5 text-xs font-medium rounded-full"
                :class="[
                  statusColors[campaign.status] ||
                    'bg-n-alpha-2 text-n-slate-12',
                ]"
              >
                {{ t(statusLabels[campaign.status] || campaign.status) }}
              </span>
            </div>
            <p
              v-if="campaign.description"
              class="mt-1 text-sm text-n-slate-11 truncate"
            >
              {{ campaign.description }}
            </p>
            <div class="flex flex-wrap gap-4 mt-2 text-xs text-n-slate-10">
              <span v-if="campaign.provider_template_name">{{
                campaign.provider_template_name
              }}</span>
              <span v-if="campaign.total_recipients"
                >• {{ t('CAMPAIGN.WHATSAPP.DETAIL.HEADER.RECIPIENTS') }}:
                {{ campaign.total_recipients }}</span
              >
            </div>
          </div>
          <div class="flex gap-1" @click.stop>
            <Button
              v-if="canSend(campaign)"
              :label="t('CAMPAIGN.WHATSAPP.ACTIONS.SEND')"
              color="blue"
              size="sm"
              :is-loading="sendingId === campaign.id"
              @click="send(campaign)"
            />
            <Button
              v-if="canPause(campaign)"
              :label="t('CAMPAIGN.WHATSAPP.ACTIONS.PAUSE')"
              color="yellow"
              size="sm"
              variant="outline"
              :is-loading="actionId === campaign.id"
              @click="doAction('pause', campaign)"
            />
            <Button
              v-if="canResume(campaign)"
              :label="t('CAMPAIGN.WHATSAPP.ACTIONS.RESUME')"
              color="green"
              size="sm"
              variant="outline"
              :is-loading="actionId === campaign.id"
              @click="doAction('resume', campaign)"
            />
            <Button
              v-if="canCancel(campaign)"
              :label="t('CAMPAIGN.WHATSAPP.ACTIONS.CANCEL')"
              color="red"
              size="sm"
              variant="outline"
              :is-loading="
                actionId === campaign.id && cancelTarget?.id === campaign.id
              "
              @click="confirmCancel(campaign)"
            />
          </div>
        </div>

        <!-- Stats row for active/completed campaigns -->
        <div
          v-if="
            campaign.status &&
            !['draft', 'validating'].includes(campaign.status)
          "
          class="grid grid-cols-4 gap-3 mt-4 pt-4 border-t border-n-weak"
        >
          <div class="text-center">
            <p class="text-lg font-semibold text-n-slate-12">
              {{ campaign.total_recipients || 0 }}
            </p>
            <p class="text-xs text-n-slate-10">
              {{ t('CAMPAIGN.WHATSAPP.DETAIL.HEADER.STATS_TOTAL') }}
            </p>
          </div>
          <div class="text-center">
            <p class="text-lg font-semibold text-n-green-11">
              {{ campaign.succeeded_count || 0 }}
            </p>
            <p class="text-xs text-n-slate-10">
              {{ t('CAMPAIGN.WHATSAPP.DETAIL.HEADER.STATS_SENT') }}
            </p>
          </div>
          <div class="text-center">
            <p class="text-lg font-semibold text-n-slate-10">
              {{ campaign.pending_count || 0 }}
            </p>
            <p class="text-xs text-n-slate-10">
              {{ t('CAMPAIGN.WHATSAPP.DETAIL.HEADER.STATS_PENDING') }}
            </p>
          </div>
          <div class="text-center">
            <p class="text-lg font-semibold text-n-red-11">
              {{ campaign.failed_count || 0 }}
            </p>
            <p class="text-xs text-n-slate-10">
              {{ t('CAMPAIGN.WHATSAPP.DETAIL.HEADER.STATS_FAILED') }}
            </p>
          </div>
        </div>
      </article>
    </div>
  </CampaignLayout>
</template>
