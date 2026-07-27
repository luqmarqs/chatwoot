<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import WhatsappBulkCampaignsAPI from 'dashboard/api/whatsappBulkCampaigns';

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();
const campaignId = computed(() => route.params.campaignId);

const campaign = useMapGetter('whatsappBulkCampaigns/getCurrentCampaign');
const recipients = useMapGetter('whatsappBulkCampaigns/getRecipients');
const uiFlags = useMapGetter('whatsappBulkCampaigns/getUIFlags');

const statusFilter = ref('all');
const searchQuery = ref('');
const isExporting = ref(false);
const actionId = ref(null);
const cancelDialogRef = ref(null);

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

const recipientStatusColors = {
  pending: 'bg-n-alpha-2 text-n-slate-12',
  queued: 'bg-n-blue-3 text-n-blue-11',
  processing: 'bg-n-yellow-3 text-n-yellow-11',
  sent: 'bg-n-blue-3 text-n-blue-11',
  delivered: 'bg-n-green-4 text-n-green-11',
  read: 'bg-n-green-4 text-n-green-11',
  replied: 'bg-n-green-4 text-n-green-11',
  failed: 'bg-n-red-3 text-n-red-11',
  skipped: 'bg-n-slate-3 text-n-slate-10',
  cancelled: 'bg-n-slate-3 text-n-slate-10',
};

onMounted(async () => {
  await store.dispatch('whatsappBulkCampaigns/fetchCampaign', campaignId.value);
  await store.dispatch(
    'whatsappBulkCampaigns/fetchRecipients',
    campaignId.value
  );
});

const statusTabs = [
  { key: 'all', label: t('CAMPAIGN.WHATSAPP.DETAIL.FILTER.ALL') },
  { key: 'pending', label: t('CAMPAIGN.WHATSAPP.DETAIL.FILTER.PENDING') },
  { key: 'sent', label: t('CAMPAIGN.WHATSAPP.DETAIL.FILTER.SENT') },
  { key: 'delivered', label: t('CAMPAIGN.WHATSAPP.DETAIL.FILTER.DELIVERED') },
  { key: 'read', label: t('CAMPAIGN.WHATSAPP.DETAIL.FILTER.READ') },
  { key: 'failed', label: t('CAMPAIGN.WHATSAPP.DETAIL.FILTER.FAILED') },
];

const filteredRecipients = computed(() => {
  let list = recipients.value;
  if (statusFilter.value !== 'all') {
    list = list.filter(r => r.status === statusFilter.value);
  }
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.trim().toLowerCase();
    list = list.filter(
      r =>
        r.phone_number?.toLowerCase().includes(q) ||
        r.recipient_key?.toLowerCase().includes(q) ||
        r.failure_message?.toLowerCase().includes(q)
    );
  }
  return list;
});

const counts = computed(() => {
  const recs = recipients.value;
  return {
    all: recs.length,
    pending: recs.filter(r => r.status === 'pending').length,
    sent: recs.filter(r =>
      ['sent', 'delivered', 'read', 'replied'].includes(r.status)
    ).length,
    delivered: recs.filter(r =>
      ['delivered', 'read', 'replied'].includes(r.status)
    ).length,
    read: recs.filter(r => ['read', 'replied'].includes(r.status)).length,
    failed: recs.filter(r => r.status === 'failed').length,
  };
});

const canSend = c => ['draft', 'validating'].includes(c?.status || '');
const canPause = c => c?.status === 'running';
const canResume = c => c?.status === 'paused';
const canCancel = c =>
  c &&
  !['completed', 'completed_with_errors', 'cancelled', 'failed'].includes(
    c.status
  );

const refresh = () => {
  store.dispatch('whatsappBulkCampaigns/fetchCampaign', campaignId.value);
  store.dispatch('whatsappBulkCampaigns/fetchRecipients', campaignId.value);
};

const doAction = async action => {
  actionId.value = campaignId.value;
  try {
    await store.dispatch(`whatsappBulkCampaigns/${action}`, campaignId.value);
    useAlert(t(`CAMPAIGN.WHATSAPP.API.${action.toUpperCase()}_SUCCESS`));
    refresh();
  } catch {
    useAlert(t(`CAMPAIGN.WHATSAPP.API.${action.toUpperCase()}_ERROR`));
  } finally {
    actionId.value = null;
  }
};

const confirmCancel = () => {
  cancelDialogRef.value?.open();
};

const handleCancelConfirm = async () => {
  await doAction('cancel');
  cancelDialogRef.value?.close();
};

const back = () => router.push({ name: 'campaigns_whatsapp_index' });

const exportCsv = async () => {
  isExporting.value = true;
  try {
    const response = await WhatsappBulkCampaignsAPI.exportCsv(campaignId.value);
    const url = window.URL.createObjectURL(new Blob([response.data]));
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute(
      'download',
      `campaign_${campaignId.value}_recipients.csv`
    );
    document.body.appendChild(link);
    link.click();
    link.remove();
    window.URL.revokeObjectURL(url);
  } catch {
    // silently fail
  } finally {
    isExporting.value = false;
  }
};

const formatTime = ts => {
  if (!ts) return t('CAMPAIGN.WHATSAPP.DETAIL.EXPAND.TIME_DISPLAY');
  return new Date(ts).toLocaleString();
};

const expandedId = ref(null);
const toggleExpand = id => {
  expandedId.value = expandedId.value === id ? null : id;
};
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <div class="flex flex-col h-full p-6 overflow-auto bg-n-surface-1">
    <!-- Cancel confirmation dialog -->
    <Dialog
      ref="cancelDialogRef"
      type="alert"
      :title="t('CAMPAIGN.WHATSAPP.CONFIRM.CANCEL_TITLE')"
      :description="t('CAMPAIGN.WHATSAPP.CONFIRM.CANCEL_DESC')"
      :confirm-button-label="t('CAMPAIGN.WHATSAPP.CONFIRM.CANCEL_CONFIRM')"
      @confirm="handleCancelConfirm"
    />

    <!-- Header -->
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center gap-4">
        <Button variant="link" icon="i-lucide-arrow-left" @click="back" />
        <h2 class="text-lg font-semibold text-n-slate-12">
          {{ t('CAMPAIGN.WHATSAPP.DETAIL_TITLE') }}
        </h2>
      </div>
      <Button
        :label="t('CAMPAIGN.WHATSAPP.ACTIONS.EXPORT_CSV')"
        color="slate"
        variant="outline"
        size="sm"
        :is-loading="isExporting"
        icon="i-lucide-download"
        @click="exportCsv"
      />
    </div>

    <!-- Campaign Info Card -->
    <div
      v-if="campaign"
      class="p-5 mb-6 border rounded-xl border-n-weak bg-n-surface-2"
    >
      <div class="flex items-start justify-between gap-4">
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-3">
            <p class="text-lg font-semibold text-n-slate-12">
              {{ campaign.name }}
            </p>
            <span
              class="px-2 py-0.5 text-xs font-medium rounded-full"
              :class="[
                statusColors[campaign.status] || 'bg-n-alpha-2 text-n-slate-12',
              ]"
            >
              {{ t(statusLabels[campaign.status] || campaign.status) }}
            </span>
          </div>
          <p v-if="campaign.description" class="mt-1 text-sm text-n-slate-11">
            {{ campaign.description }}
          </p>
          <div class="flex flex-wrap gap-4 mt-2 text-xs text-n-slate-10">
            <span v-if="campaign.provider_template_name">
              {{ t('CAMPAIGN.WHATSAPP.DETAIL.HEADER.TEMPLATE') }}:
              {{ campaign.provider_template_name }}
            </span>
            <span v-if="campaign.total_recipients">
              {{ t('CAMPAIGN.WHATSAPP.DETAIL.HEADER.RECIPIENTS') }}:
              {{ campaign.total_recipients }}
            </span>
          </div>
        </div>
        <div class="flex gap-1">
          <Button
            v-if="canSend(campaign)"
            :label="t('CAMPAIGN.WHATSAPP.ACTIONS.SEND')"
            color="blue"
            size="sm"
            :is-loading="actionId === campaignId"
            @click="doAction('send')"
          />
          <Button
            v-if="canPause(campaign)"
            :label="t('CAMPAIGN.WHATSAPP.ACTIONS.PAUSE')"
            color="yellow"
            size="sm"
            variant="outline"
            :is-loading="actionId === campaignId"
            @click="doAction('pause')"
          />
          <Button
            v-if="canResume(campaign)"
            :label="t('CAMPAIGN.WHATSAPP.ACTIONS.RESUME')"
            color="green"
            size="sm"
            variant="outline"
            :is-loading="actionId === campaignId"
            @click="doAction('resume')"
          />
          <Button
            v-if="canCancel(campaign)"
            :label="t('CAMPAIGN.WHATSAPP.ACTIONS.CANCEL')"
            color="red"
            size="sm"
            variant="outline"
            :is-loading="actionId === campaignId"
            @click="confirmCancel"
          />
        </div>
      </div>

      <!-- Campaign stats -->
      <div
        v-if="!['draft', 'validating'].includes(campaign.status)"
        class="grid grid-cols-4 gap-3 mt-4 pt-4 border-t border-n-weak"
      >
        <div class="text-center">
          <p class="text-xl font-bold text-n-slate-12">
            {{ campaign.total_recipients || 0 }}
          </p>
          <p class="text-xs text-n-slate-10">
            {{ t('CAMPAIGN.WHATSAPP.DETAIL.HEADER.STATS_TOTAL') }}
          </p>
        </div>
        <div class="text-center">
          <p class="text-xl font-bold text-n-green-11">
            {{ campaign.succeeded_count || 0 }}
          </p>
          <p class="text-xs text-n-slate-10">
            {{ t('CAMPAIGN.WHATSAPP.DETAIL.HEADER.STATS_SENT') }}
          </p>
        </div>
        <div class="text-center">
          <p class="text-xl font-bold text-n-slate-10">
            {{ campaign.pending_count || 0 }}
          </p>
          <p class="text-xs text-n-slate-10">
            {{ t('CAMPAIGN.WHATSAPP.DETAIL.HEADER.STATS_PENDING') }}
          </p>
        </div>
        <div class="text-center">
          <p class="text-xl font-bold text-n-red-11">
            {{ campaign.failed_count || 0 }}
          </p>
          <p class="text-xs text-n-slate-10">
            {{ t('CAMPAIGN.WHATSAPP.DETAIL.HEADER.STATS_FAILED') }}
          </p>
        </div>
      </div>
    </div>

    <!-- Spinner while loading campaign -->
    <div
      v-if="uiFlags.isFetching && !campaign"
      class="flex justify-center py-12"
    >
      <Spinner />
    </div>

    <!-- Recipient Stats -->
    <div v-if="recipients.length" class="grid grid-cols-6 gap-3 mb-4">
      <div
        v-for="tab in statusTabs"
        :key="tab.key"
        class="p-3 text-center border rounded-lg cursor-pointer transition-colors"
        :class="[
          statusFilter === tab.key
            ? 'border-n-blue-6 bg-n-blue-2'
            : 'border-n-weak bg-n-surface-2 hover:border-n-blue-6',
        ]"
        @click="statusFilter = tab.key"
      >
        <p class="text-xl font-bold text-n-slate-12">
          {{ counts[tab.key] || 0 }}
        </p>
        <p class="text-xs text-n-slate-10">{{ tab.label }}</p>
      </div>
    </div>

    <!-- Search -->
    <div v-if="recipients.length" class="mb-4">
      <Input
        v-model="searchQuery"
        :placeholder="t('CAMPAIGN.WHATSAPP.DETAIL.SEARCH_PLACEHOLDER')"
      />
    </div>

    <!-- Content -->
    <div
      v-if="!recipients.length && !uiFlags.isFetching"
      class="py-12 text-center text-n-slate-11"
    >
      {{ t('CAMPAIGN.WHATSAPP.DETAIL.NO_RECIPIENTS') }}
    </div>
    <div v-else-if="recipients.length" class="flex flex-col gap-1">
      <div
        v-for="r in filteredRecipients"
        :key="r.id"
        class="border rounded-lg border-n-weak bg-n-surface-2 overflow-hidden"
      >
        <div
          class="flex items-center justify-between px-4 py-3 cursor-pointer hover:bg-n-alpha-1 transition-colors"
          @click="toggleExpand(r.id)"
        >
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <p class="text-sm font-medium text-n-slate-12">
                {{ r.phone_number }}
              </p>
              <span
                v-if="
                  r.template_parameters &&
                  Object.keys(r.template_parameters).length
                "
                class="text-xs text-n-slate-10"
              >
                ({{ Object.values(r.template_parameters).join(', ') }})
              </span>
            </div>
            <p class="text-xs text-n-slate-10">{{ r.recipient_key }}</p>
          </div>
          <div class="flex items-center gap-3">
            <span
              class="px-2 py-0.5 text-xs font-medium rounded-full"
              :class="[
                recipientStatusColors[r.status] ||
                  'bg-n-alpha-2 text-n-slate-12',
              ]"
            >
              {{ r.status }}
            </span>
            <span class="text-xs text-n-slate-10 w-16 text-right">
              {{ r.sent_at ? formatTime(r.sent_at).split(',')[0] : '—' }}
            </span>
          </div>
        </div>

        <!-- Expanded detail -->
        <div
          v-if="expandedId === r.id"
          class="px-4 pb-3 border-t border-n-weak bg-n-surface-2"
        >
          <div class="grid grid-cols-2 gap-2 mt-3 text-sm">
            <div>
              <span class="text-n-slate-10"
                >{{ t('CAMPAIGN.WHATSAPP.DETAIL.EXPAND.MESSAGE_ID') }}:</span
              >
              <p class="text-n-slate-12 font-mono text-xs break-all">
                {{ r.provider_message_id || '—' }}
              </p>
            </div>
            <div>
              <span class="text-n-slate-10"
                >{{ t('CAMPAIGN.WHATSAPP.DETAIL.EXPAND.ATTEMPTS') }}:</span
              >
              <p class="text-n-slate-12">{{ r.attempt_count || 0 }}</p>
            </div>
            <div>
              <span class="text-n-slate-10"
                >{{ t('CAMPAIGN.WHATSAPP.DETAIL.EXPAND.SENT') }}:</span
              >
              <p class="text-n-slate-12">{{ formatTime(r.sent_at) }}</p>
            </div>
            <div>
              <span class="text-n-slate-10"
                >{{ t('CAMPAIGN.WHATSAPP.DETAIL.EXPAND.DELIVERED') }}:</span
              >
              <p class="text-n-slate-12">
                {{ formatTime(r.delivered_at) }}
              </p>
            </div>
            <div>
              <span class="text-n-slate-10"
                >{{ t('CAMPAIGN.WHATSAPP.DETAIL.EXPAND.READ') }}:</span
              >
              <p class="text-n-slate-12">{{ formatTime(r.read_at) }}</p>
            </div>
            <div>
              <span class="text-n-slate-10"
                >{{ t('CAMPAIGN.WHATSAPP.DETAIL.EXPAND.FAILED') }}:</span
              >
              <p class="text-n-slate-12">{{ formatTime(r.failed_at) }}</p>
            </div>
            <div v-if="r.failure_message" class="col-span-2">
              <span class="text-n-slate-10"
                >{{ t('CAMPAIGN.WHATSAPP.DETAIL.EXPAND.ERROR') }}:</span
              >
              <p class="text-n-red-11 text-xs">{{ r.failure_message }}</p>
            </div>
            <div
              v-if="
                r.template_parameters &&
                Object.keys(r.template_parameters).length
              "
              class="col-span-2"
            >
              <span class="text-n-slate-10"
                >{{ t('CAMPAIGN.WHATSAPP.DETAIL.EXPAND.PARAMS') }}:</span
              >
              <p class="text-n-slate-12 text-xs">
                <code>{{ JSON.stringify(r.template_parameters) }}</code>
              </p>
            </div>
          </div>
        </div>
      </div>

      <div
        v-if="filteredRecipients.length === 0 && recipients.length > 0"
        class="py-8 text-center text-sm text-n-slate-11"
      >
        {{ t('CAMPAIGN.WHATSAPP.DETAIL.NO_MATCH') }}
      </div>
    </div>
  </div>
</template>
