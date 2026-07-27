<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import WhatsappBulkCampaignsAPI from 'dashboard/api/whatsappBulkCampaigns';

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();
const campaignId = computed(() => route.params.campaignId);

const recipients = useMapGetter('whatsappBulkCampaigns/getRecipients');
const uiFlags = useMapGetter('whatsappBulkCampaigns/getUIFlags');

const statusFilter = ref('all');
const searchQuery = ref('');
const isExporting = ref(false);

onMounted(() =>
  store.dispatch('whatsappBulkCampaigns/fetchRecipients', campaignId.value)
);

const statusTabs = [
  { key: 'all', label: 'All' },
  { key: 'pending', label: 'Pending' },
  { key: 'sent', label: 'Sent' },
  { key: 'delivered', label: 'Delivered' },
  { key: 'read', label: 'Read' },
  { key: 'failed', label: 'Failed' },
];

const statusColors = {
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
    sent: recs.filter(r => ['sent', 'delivered', 'read', 'replied'].includes(r.status)).length,
    delivered: recs.filter(r => ['delivered', 'read', 'replied'].includes(r.status)).length,
    read: recs.filter(r => ['read', 'replied'].includes(r.status)).length,
    failed: recs.filter(r => r.status === 'failed').length,
  };
});

const back = () => router.push({ name: 'campaigns_whatsapp_index' });

const exportCsv = async () => {
  isExporting.value = true;
  try {
    const response = await WhatsappBulkCampaignsAPI.exportCsv(campaignId.value);
    const url = window.URL.createObjectURL(new Blob([response.data]));
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `campaign_${campaignId.value}_recipients.csv`);
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

const formatTime = (ts) => {
  if (!ts) return '—';
  return new Date(ts).toLocaleString();
};

const expandedId = ref(null);
const toggleExpand = (id) => {
  expandedId.value = expandedId.value === id ? null : id;
};
</script>

<template>
  <div class="flex flex-col h-full p-6 overflow-auto bg-n-surface-1">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center gap-4">
        <Button variant="link" icon="i-lucide-arrow-left" @click="back" />
        <h2 class="text-lg font-semibold text-n-slate-12">
          {{ t('CAMPAIGN.WHATSAPP.HEADER_TITLE') }}
        </h2>
      </div>
      <Button
        label="Export CSV"
        color="slate"
        variant="outline"
        size="sm"
        :is-loading="isExporting"
        icon="i-lucide-download"
        @click="exportCsv"
      />
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-6 gap-3 mb-4">
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
        <p class="text-xl font-bold text-n-slate-12">{{ counts[tab.key] || 0 }}</p>
        <p class="text-xs text-n-slate-10">{{ tab.label }}</p>
      </div>
    </div>

    <!-- Search -->
    <div class="mb-4">
      <Input
        v-model="searchQuery"
        placeholder="Search by phone, key, or error..."
      />
    </div>

    <!-- Content -->
    <div v-if="uiFlags.isFetching" class="flex justify-center py-12">
      <Spinner />
    </div>
    <div
      v-else-if="!recipients.length"
      class="py-12 text-center text-n-slate-11"
    >
      No recipients yet
    </div>
    <div v-else class="flex flex-col gap-1">
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
                v-if="r.template_parameters && Object.keys(r.template_parameters).length"
                class="text-xs text-n-slate-10"
              >
                ({{ Object.values(r.template_parameters).join(', ') }})
              </span>
            </div>
            <p class="text-xs text-n-slate-10">{{ r.recipient_key }}</p>
          </div>
          <div class="flex items-center gap-3">
            <span
              :class="[
                'px-2 py-0.5 text-xs font-medium rounded-full',
                statusColors[r.status] || 'bg-n-alpha-2 text-n-slate-12',
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
              <span class="text-n-slate-10">Message ID:</span>
              <p class="text-n-slate-12 font-mono text-xs break-all">
                {{ r.provider_message_id || '—' }}
              </p>
            </div>
            <div>
              <span class="text-n-slate-10">Attempts:</span>
              <p class="text-n-slate-12">{{ r.attempt_count || 0 }}</p>
            </div>
            <div>
              <span class="text-n-slate-10">Sent:</span>
              <p class="text-n-slate-12">{{ formatTime(r.sent_at) }}</p>
            </div>
            <div>
              <span class="text-n-slate-10">Delivered:</span>
              <p class="text-n-slate-12">{{ formatTime(r.delivered_at) }}</p>
            </div>
            <div>
              <span class="text-n-slate-10">Read:</span>
              <p class="text-n-slate-12">{{ formatTime(r.read_at) }}</p>
            </div>
            <div>
              <span class="text-n-slate-10">Failed:</span>
              <p class="text-n-slate-12">{{ formatTime(r.failed_at) }}</p>
            </div>
            <div v-if="r.failure_message" class="col-span-2">
              <span class="text-n-slate-10">Error:</span>
              <p class="text-n-red-11 text-xs">{{ r.failure_message }}</p>
            </div>
            <div v-if="r.template_parameters && Object.keys(r.template_parameters).length" class="col-span-2">
              <span class="text-n-slate-10">Template Params:</span>
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
        No recipients match the current filter.
      </div>
    </div>
  </div>
</template>
