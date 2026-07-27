<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const { t } = useI18n();
const store = useStore();
const dialogRef = ref(null);
const name = ref('');
const inboxId = ref(null);
const templateName = ref('');
const isCreating = useMapGetter('whatsappBulkCampaigns/getUIFlags');
const inboxes = useMapGetter('inboxes/getInboxes');

const whatsappInboxes = computed(() =>
  inboxes.value.filter(inbox => inbox.channel_type === 'Channel::Whatsapp')
);
const isInvalid = computed(() => !name.value.trim() || !inboxId.value || !templateName.value.trim());

onMounted(() => store.dispatch('inboxes/get'));

const open = () => dialogRef.value?.open();
const close = () => dialogRef.value?.close();
const create = async () => {
  if (isInvalid.value) return;
  await store.dispatch('whatsappBulkCampaigns/create', {
    name: name.value.trim(),
    inbox_id: Number(inboxId.value),
    provider_template_name: templateName.value.trim(),
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  });
  name.value = '';
  inboxId.value = null;
  templateName.value = '';
  close();
};

defineExpose({ open });
</script>

<template>
  <Dialog ref="dialogRef" width="2xl" @confirm="create">
    <div class="flex flex-col gap-4">
      <span class="text-base font-medium text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.TITLE') }}
      </span>
      <Input v-model="name" :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.PLACEHOLDER')" />
      <select v-model="inboxId" class="w-full px-3 py-2 border rounded-lg border-n-weak bg-n-surface-2 text-n-slate-12">
        <option :value="null" disabled>{{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.INBOX.PLACEHOLDER') }}</option>
        <option v-for="inbox in whatsappInboxes" :key="inbox.id" :value="inbox.id">{{ inbox.name }}</option>
      </select>
      <Input v-model="templateName" :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.PLACEHOLDER')" />
    </div>
    <template #footer>
      <div class="flex justify-end gap-3">
        <Button :label="t('DIALOG.BUTTONS.CANCEL')" variant="link" @click="close" />
        <Button :label="t('CAMPAIGN.WHATSAPP.CREATE.BUTTONS.CREATE')" type="submit" :disabled="isInvalid" :is-loading="isCreating.isCreating" />
      </div>
    </template>
  </Dialog>
</template>
