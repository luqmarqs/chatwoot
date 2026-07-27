<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();
const campaignId = computed(() => route.params.campaignId);

const recipients = useMapGetter('whatsappBulkCampaigns/getRecipients');
const uiFlags = useMapGetter('whatsappBulkCampaigns/getUIFlags');

onMounted(() =>
  store.dispatch('whatsappBulkCampaigns/fetchRecipients', campaignId.value)
);

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

const back = () => router.push({ name: 'campaigns_whatsapp_index' });

const stats = computed(() => {
  const recs = recipients.value;
  if (!recs.length) return null;
  return {
    total: recs.length,
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
</script>

<template>
  <div class="flex flex-col h-full p-6 overflow-auto bg-n-surface-1">
    <div class="flex items-center gap-4 mb-6">
      <Button variant="link" icon="i-lucide-arrow-left" @click="back" />
      <h2 class="text-lg font-semibold text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.HEADER_TITLE') }}
      </h2>
    </div>

    <div v-if="stats" class="grid grid-cols-5 gap-3 mb-6">
      <div
        class="p-3 text-center border rounded-lg border-n-weak bg-n-surface-2"
      >
        <p class="text-xl font-bold text-n-slate-12">{{ stats.total }}</p>
        <p class="text-xs text-n-slate-10">Total</p>
      </div>
      <div
        class="p-3 text-center border rounded-lg border-n-weak bg-n-surface-2"
      >
        <p class="text-xl font-bold text-n-blue-11">{{ stats.sent }}</p>
        <p class="text-xs text-n-slate-10">Enviado</p>
      </div>
      <div
        class="p-3 text-center border rounded-lg border-n-weak bg-n-surface-2"
      >
        <p class="text-xl font-bold text-n-green-11">{{ stats.delivered }}</p>
        <p class="text-xs text-n-slate-10">Entregue</p>
      </div>
      <div
        class="p-3 text-center border rounded-lg border-n-weak bg-n-surface-2"
      >
        <p class="text-xl font-bold text-n-green-11">{{ stats.read }}</p>
        <p class="text-xs text-n-slate-10">Lido</p>
      </div>
      <div
        class="p-3 text-center border rounded-lg border-n-weak bg-n-surface-2"
      >
        <p class="text-xl font-bold text-n-red-11">{{ stats.failed }}</p>
        <p class="text-xs text-n-slate-10">Falha</p>
      </div>
    </div>

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
        v-for="r in recipients"
        :key="r.id"
        class="flex items-center justify-between px-4 py-3 border rounded-lg border-n-weak bg-n-surface-2"
      >
        <div>
          <p class="text-sm font-medium text-n-slate-12">
            {{ r.phone_number }}
          </p>
          <p class="text-xs text-n-slate-10">{{ r.recipient_key }}</p>
        </div>
        <span
          :class="['px-2 py-0.5 text-xs font-medium rounded-full', statusColors[r.status] || 'bg-n-alpha-2 text-n-slate-12']"
        >
          {{ r.status }}
        </span>
      </div>
    </div>
  </div>
</template>
