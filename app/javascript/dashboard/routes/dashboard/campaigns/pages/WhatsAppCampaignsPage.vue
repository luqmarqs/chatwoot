<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import BulkCampaignCreateDialog from 'dashboard/components-next/Campaigns/BulkCampaignCreateDialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const createDialog = ref(null);
const sendingId = ref(null);
const actionId = ref(null);

const campaigns = useMapGetter('whatsappBulkCampaigns/getAll');
const uiFlags = useMapGetter('whatsappBulkCampaigns/getUIFlags');
const isEmpty = computed(
  () => !uiFlags.value.isFetching && campaigns.value.length === 0
);

onMounted(() => store.dispatch('whatsappBulkCampaigns/get'));

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
    refresh();
  } finally {
    sendingId.value = null;
  }
};

const doAction = async (action, campaign) => {
  actionId.value = campaign.id;
  try {
    await store.dispatch(`whatsappBulkCampaigns/${action}`, campaign.id);
    refresh();
  } finally {
    actionId.value = null;
  }
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
                {{ campaign.status }}
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
              <span v-if="campaign.total_recipients">• {{ campaign.total_recipients }} recipients</span>
            </div>
          </div>
          <div class="flex gap-1" @click.stop>
            <Button
              v-if="canSend(campaign)"
              label="Send"
              color="blue"
              size="sm"
              :is-loading="sendingId === campaign.id"
              @click="send(campaign)"
            />
            <Button
              v-if="canPause(campaign)"
              label="Pause"
              color="yellow"
              size="sm"
              variant="outline"
              :is-loading="actionId === campaign.id"
              @click="doAction('pause', campaign)"
            />
            <Button
              v-if="canResume(campaign)"
              label="Resume"
              color="green"
              size="sm"
              variant="outline"
              :is-loading="actionId === campaign.id"
              @click="doAction('resume', campaign)"
            />
            <Button
              v-if="canCancel(campaign)"
              label="Cancel"
              color="red"
              size="sm"
              variant="outline"
              :is-loading="actionId === campaign.id"
              @click="doAction('cancel', campaign)"
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
            <p class="text-xs text-n-slate-10">Total</p>
          </div>
          <div class="text-center">
            <p class="text-lg font-semibold text-n-green-11">
              {{ campaign.succeeded_count || 0 }}
            </p>
            <p class="text-xs text-n-slate-10">Enviado</p>
          </div>
          <div class="text-center">
            <p class="text-lg font-semibold text-n-slate-10">
              {{ campaign.pending_count || 0 }}
            </p>
            <p class="text-xs text-n-slate-10">Pendente</p>
          </div>
          <div class="text-center">
            <p class="text-lg font-semibold text-n-red-11">
              {{ campaign.failed_count || 0 }}
            </p>
            <p class="text-xs text-n-slate-10">Falha</p>
          </div>
        </div>
      </article>
    </div>
  </CampaignLayout>
</template>
