<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import BulkCampaignCreateDialog from 'dashboard/components-next/Campaigns/BulkCampaignCreateDialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const { t } = useI18n();
const store = useStore();
const createDialog = ref(null);
const campaigns = useMapGetter('whatsappBulkCampaigns/getAll');
const uiFlags = useMapGetter('whatsappBulkCampaigns/getUIFlags');
const isEmpty = computed(() => !uiFlags.value.isFetching && campaigns.value.length === 0);

onMounted(() => store.dispatch('whatsappBulkCampaigns/get'));
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.WHATSAPP.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.WHATSAPP.NEW_CAMPAIGN')"
    @click="createDialog?.open()"
  >
    <template #action>
      <BulkCampaignCreateDialog ref="createDialog" />
    </template>
    <div v-if="uiFlags.isFetching" class="flex justify-center py-12"><Spinner /></div>
    <div v-else-if="isEmpty" class="py-14 text-center">
      <p class="text-base font-medium text-n-slate-12">{{ t('CAMPAIGN.WHATSAPP.EMPTY_STATE.TITLE') }}</p>
      <p class="mt-2 text-sm text-n-slate-11">{{ t('CAMPAIGN.WHATSAPP.EMPTY_STATE.SUBTITLE') }}</p>
    </div>
    <div v-else class="grid gap-3">
      <article v-for="campaign in campaigns" :key="campaign.id" class="p-4 border rounded-xl border-n-weak bg-n-surface-2">
        <div class="flex items-start justify-between gap-4">
          <div><p class="font-medium text-n-slate-12">{{ campaign.name }}</p><p class="mt-1 text-sm text-n-slate-11">{{ campaign.provider_template_name }}</p></div>
          <span class="px-2 py-1 text-xs font-medium rounded-md bg-n-alpha-2 text-n-slate-12">{{ campaign.status }}</span>
        </div>
      </article>
    </div>
  </CampaignLayout>
</template>
