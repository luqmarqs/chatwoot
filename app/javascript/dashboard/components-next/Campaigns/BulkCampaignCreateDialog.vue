<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useDebounceFn } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ContactPicker from './ContactPicker.vue';
import WhatsappBulkCampaignsAPI from 'dashboard/api/whatsappBulkCampaigns';

const { t } = useI18n();
const store = useStore();
const dialogRef = ref(null);
const step = ref(1);
const TOTAL_STEPS = 4;

// Step 1: Basic info
const name = ref('');
const description = ref('');
const inboxId = ref(null);

// Step 2: Template
const selectedTemplateId = ref(null);

// Step 3: Audience
const audienceType = ref('csv');
const csvFile = ref(null);
const selectedContactIds = ref([]);
const audiencePreview = ref(null);
const isPreviewLoading = ref(false);

// Step 4: Config
const rateLimit = ref(60);
const batchSize = ref(10);
const sendWindowEnabled = ref(false);
const sendWindowStart = ref('08:00');
const sendWindowEnd = ref('20:00');

const isCreating = computed(
  () => useMapGetter('whatsappBulkCampaigns/getUIFlags').value
);
const inboxes = useMapGetter('inboxes/getInboxes');
const templates = useMapGetter('whatsappBulkTemplates/getAll');

const whatsappInboxes = computed(() =>
  inboxes.value.filter(inbox => inbox.channel_type === 'Channel::Whatsapp')
);

const approvedTemplates = computed(() =>
  templates.value.filter(t => t.status === 'approved')
);

const selectedTemplate = computed(() =>
  templates.value.find(t => t.id === selectedTemplateId.value)
);

const templateVariables = computed(() => {
  const tpl = selectedTemplate.value;
  if (!tpl) return [];
  const bodyText = tpl.body_text || tpl.content_snapshot?.body_text || '';
  const matches = bodyText.match(/\{\{(\w+)\}\}/g) || [];
  return [...new Set(matches.map(m => m.replace(/[\{\}]/g, '')))];
});

const isValidStep1 = computed(() => name.value.trim() && inboxId.value);
const isValidStep2 = computed(() => selectedTemplateId.value);
const isValidStep3 = computed(() =>
  audienceType.value === 'csv' ? csvFile.value : selectedContactIds.value.length > 0
);

onMounted(() => {
  store.dispatch('inboxes/get');
  store.dispatch('whatsappBulkTemplates/get');
});

const open = () => {
  step.value = 1;
  dialogRef.value?.open();
};
const close = () => dialogRef.value?.close();

const nextStep = () => {
  if (step.value < TOTAL_STEPS) step.value++;
};
const prevStep = () => {
  if (step.value > 1) step.value--;
};

const fetchAudiencePreview = useDebounceFn(async () => {
  const definition = buildAudienceDefinition();
  if (!Object.keys(definition).length) {
    audiencePreview.value = null;
    return;
  }
  isPreviewLoading.value = true;
  try {
    const { data } = await WhatsappBulkCampaignsAPI.audiencePreview(definition);
    audiencePreview.value = data.audience;
  } catch {
    audiencePreview.value = null;
  } finally {
    isPreviewLoading.value = false;
  }
}, 500);

const buildAudienceDefinition = () => {
  if (audienceType.value === 'contacts' && selectedContactIds.value.length > 0) {
    return { contact_ids: selectedContactIds.value };
  }
  return {};
};

watch([audienceType, selectedContactIds], () => {
  fetchAudiencePreview();
}, { deep: true });

const create = async () => {
  if (!isValidStep1.value || !isValidStep2.value) return;

  const template = selectedTemplate.value;
  const payload = {
    name: name.value.trim(),
    description: description.value.trim(),
    inbox_id: Number(inboxId.value),
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    provider_template_name: template?.provider_template_name || template?.name,
    provider_template_namespace: template?.provider_template_namespace,
    provider_template_language: template?.language,
    provider_template_category: template?.category,
    template_snapshot: template?.content_snapshot || {},
    audience_definition: buildAudienceDefinition(),
    rate_limit_per_minute: Number(rateLimit.value) || 60,
    batch_size: Number(batchSize.value) || 10,
    send_window_enabled: sendWindowEnabled.value,
    send_window_start: sendWindowEnabled.value ? sendWindowStart.value : null,
    send_window_end: sendWindowEnabled.value ? sendWindowEnd.value : null,
  };

  const result = await store.dispatch('whatsappBulkCampaigns/create', payload);

  if (result?.id && csvFile.value) {
    await store.dispatch('whatsappBulkCampaigns/importRecipients', {
      id: result.id,
      file: csvFile.value,
    });
  }

  name.value = '';
  description.value = '';
  inboxId.value = null;
  selectedTemplateId.value = null;
  csvFile.value = null;
  selectedContactIds.value = [];
  audiencePreview.value = null;
  rateLimit.value = 60;
  batchSize.value = 10;
  sendWindowEnabled.value = false;
  close();
};

defineExpose({ open });

const stepLabels = ['Campaign Info', 'Template', 'Audience', 'Config'];
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <Dialog
    ref="dialogRef"
    width="2xl"
    @confirm="step === TOTAL_STEPS ? create() : nextStep()"
  >
    <div class="flex flex-col gap-4">
      <div class="flex items-center gap-2 mb-2">
        <span
          v-for="s in TOTAL_STEPS"
          :key="s"
          class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition-colors"
          :class="[
            s <= step
              ? 'bg-n-blue-9 text-white'
              : 'bg-n-alpha-2 text-n-slate-10',
          ]"
        >
          {{ s }}
        </span>
      </div>

      <span class="text-base font-medium text-n-slate-12">
        {{ stepLabels[step - 1] }}
      </span>

      <!-- Step 1: Info -->
      <template v-if="step === 1">
        <Input
          v-model="name"
          :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.PLACEHOLDER')"
        />
        <Input
          v-model="description"
          :placeholder="
            t('CAMPAIGN.WHATSAPP.CREATE.FORM.DESCRIPTION.PLACEHOLDER') ||
            'Description'
          "
        />
        <select
          v-model="inboxId"
          class="w-full px-3 py-2 border rounded-lg border-n-weak bg-n-surface-2 text-n-slate-12"
        >
          <option :value="null" disabled>
            {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.INBOX.PLACEHOLDER') }}
          </option>
          <option
            v-for="inbox in whatsappInboxes"
            :key="inbox.id"
            :value="inbox.id"
          >
            {{ inbox.name }}
          </option>
        </select>
      </template>

      <!-- Step 2: Template -->
      <template v-if="step === 2">
        <div
          v-if="templates.length === 0"
          class="py-4 text-center text-sm text-n-slate-11"
        >
          No templates. Sync from WhatsApp first.
        </div>
        <div v-else class="grid gap-2 max-h-64 overflow-y-auto">
          <label
            v-for="tpl in approvedTemplates"
            :key="tpl.id"
            class="flex items-center gap-3 p-3 border rounded-lg cursor-pointer transition-colors"
            :class="[
              selectedTemplateId === tpl.id
                ? 'border-n-blue-6 bg-n-blue-2'
                : 'border-n-weak bg-n-surface-2 hover:border-n-blue-6',
            ]"
          >
            <input
              v-model="selectedTemplateId"
              type="radio"
              :value="tpl.id"
              class="hidden"
            />
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-n-slate-12 truncate">
                {{ tpl.name }}
              </p>
              <p class="text-xs text-n-slate-10 truncate">
                {{ tpl.body_text || tpl.provider_template_name }}
              </p>
              <div class="flex gap-2 mt-1">
                <span class="text-xs text-n-slate-10">{{ tpl.language }}</span>
                <span v-if="tpl.category"
class="text-xs text-n-slate-10"
                  >• {{ tpl.category }}</span>
              </div>
            </div>
          </label>
        </div>

        <div
          v-if="templateVariables.length"
          class="mt-4 p-3 border border-n-weak rounded-lg bg-n-surface-2"
        >
          <p class="text-xs font-medium text-n-slate-11 mb-2">
            Template Variables
          </p>
          <div class="flex flex-wrap gap-2">
            <span
              v-for="v in templateVariables"
              :key="v"
              class="px-2 py-0.5 text-xs font-mono rounded bg-n-alpha-2 text-n-slate-12"
            >
              {{ '{{' + v + '}}' }}
            </span>
          </div>
          <p class="mt-2 text-xs text-n-slate-10">
            For CSV: include a <code>params</code> column like
            <code>{ "nome": "Lucas" }</code>
          </p>
        </div>
      </template>

      <!-- Step 3: Audience -->
      <template v-if="step === 3">
        <div class="flex gap-2">
          <Button
            label="CSV Upload"
            :color="audienceType === 'csv' ? 'blue' : 'slate'"
            size="sm"
            variant="outline"
            @click="audienceType = 'csv'"
          />
          <Button
            label="Contacts"
            :color="audienceType === 'contacts' ? 'blue' : 'slate'"
            size="sm"
            variant="outline"
            @click="audienceType = 'contacts'"
          />
        </div>

        <div v-if="audienceType === 'csv'" class="mt-3">
          <input
            type="file"
            accept=".csv"
            class="w-full"
            @change="csvFile = $event.target.files[0]"
          />
          <p class="mt-1 text-xs text-n-slate-10">
            CSV with columns: phone, name, params (optional)
          </p>
        </div>

        <div v-else class="mt-3">
          <ContactPicker v-model="selectedContactIds" />
        </div>

        <div
          v-if="isPreviewLoading"
          class="mt-3 py-2 text-center text-sm text-n-slate-10"
        >
          Calculating audience...
        </div>
        <div
          v-else-if="audiencePreview"
          class="mt-3 p-3 border border-n-weak rounded-lg bg-n-surface-2"
        >
          <p class="text-sm font-medium text-n-slate-12">
            {{ audiencePreview.total }} recipient(s) matched
          </p>
          <p
            v-if="audiencePreview.sample?.length"
            class="text-xs text-n-slate-10 mt-1"
          >
            Sample: {{ audiencePreview.sample.map(s => s.name || s.phone).join(', ') }}
          </p>
        </div>
      </template>

      <!-- Step 4: Config -->
      <template v-if="step === 4">
        <div class="grid gap-3">
          <div>
            <label class="text-xs font-medium text-n-slate-11">Rate limit (per minute)</label>
            <Input v-model="rateLimit" type="number" placeholder="60" />
          </div>
          <div>
            <label class="text-xs font-medium text-n-slate-11">Batch size</label>
            <Input v-model="batchSize" type="number" placeholder="10" />
          </div>
          <label class="flex items-center gap-2 cursor-pointer">
            <input
              v-model="sendWindowEnabled"
              type="checkbox"
              class="rounded"
            />
            <span class="text-sm text-n-slate-11">Enable send window</span>
          </label>
          <div v-if="sendWindowEnabled" class="flex gap-3">
            <div class="flex-1">
              <label class="text-xs font-medium text-n-slate-11">Start</label>
              <Input v-model="sendWindowStart" type="time" />
            </div>
            <div class="flex-1">
              <label class="text-xs font-medium text-n-slate-11">End</label>
              <Input v-model="sendWindowEnd" type="time" />
            </div>
          </div>
        </div>
      </template>
    </div>
    <template #footer>
      <div class="flex justify-between w-full gap-3">
        <Button v-if="step > 1" label="Back" variant="link" @click="prevStep" />
        <div class="flex gap-3 ml-auto">
          <Button
            :label="t('DIALOG.BUTTONS.CANCEL')"
            variant="link"
            @click="close"
          />
          <Button
            :label="
              step === TOTAL_STEPS
                ? t('CAMPAIGN.WHATSAPP.CREATE.BUTTONS.CREATE')
                : 'Next'
            "
            type="submit"
            :disabled="
              (step === 1 && !isValidStep1) ||
              (step === 2 && !isValidStep2) ||
              (step === 3 && !isValidStep3)
            "
            :is-loading="isCreating.isCreating"
          />
        </div>
      </div>
    </template>
  </Dialog>
</template>
