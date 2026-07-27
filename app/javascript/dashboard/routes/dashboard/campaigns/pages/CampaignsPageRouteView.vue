<script setup>
import { onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useWhatsAppOnly } from 'dashboard/composables/useWhatsAppOnly';

defineProps({
  keepAlive: { type: Boolean, default: true },
});

const store = useStore();
const { isWhatsAppOnly } = useWhatsAppOnly();

onMounted(() => {
  if (isWhatsAppOnly.value) {
    store.dispatch('whatsappBulkCampaigns/get');
    return;
  }

  store.dispatch('campaigns/get');
  store.dispatch('labels/get');
});
</script>

<template>
  <div
    class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-n-surface-1"
  >
    <router-view v-slot="{ Component }">
      <keep-alive v-if="keepAlive">
        <component :is="Component" />
      </keep-alive>
      <component :is="Component" v-else />
    </router-view>
  </div>
</template>
