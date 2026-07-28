<script setup>
import { onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignSettingsAPI from 'dashboard/api/campaignSettings';

const { t } = useI18n();

const isLoading = ref(false);
const isSaving = ref(false);
const settings = ref({});

const defaults = {
  rate_limit_per_minute: 10,
  batch_size: 20,
  max_retry_attempts: 3,
  send_window_enabled: false,
  send_window_start: '08:00',
  send_window_end: '20:00',
  default_timezone: 'America/Sao_Paulo',
};

onMounted(async () => {
  isLoading.value = true;
  try {
    const { data } = await CampaignSettingsAPI.get();
    settings.value = { ...defaults, ...data.settings };
  } finally {
    isLoading.value = false;
  }
});

const save = async () => {
  isSaving.value = true;
  try {
    await CampaignSettingsAPI.update(settings.value);
    useAlert(t('CAMPAIGN.WHATSAPP.SETTINGS.SAVED'));
  } catch {
    useAlert(t('CAMPAIGN.WHATSAPP.SETTINGS.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col h-full p-6 overflow-auto bg-n-surface-1">
    <div class="max-w-2xl">
      <h2 class="text-lg font-semibold text-n-slate-12 mb-6">
        {{ t('CAMPAIGN.WHATSAPP.SETTINGS.TITLE') }}
      </h2>

      <div v-if="isLoading" class="flex justify-center py-12">
        <Spinner />
      </div>

      <div v-else class="flex flex-col gap-6">
        <!-- Rate limit -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('CAMPAIGN.WHATSAPP.SETTINGS.RATE_LIMIT') }}
          </label>
          <Input
            v-model.number="settings.rate_limit_per_minute"
            type="number"
            class="w-32"
          />
          <p class="text-xs text-n-slate-10 mt-1">
            {{ t('CAMPAIGN.WHATSAPP.SETTINGS.RATE_LIMIT_HINT') }}
          </p>
        </div>

        <!-- Batch size -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('CAMPAIGN.WHATSAPP.SETTINGS.BATCH_SIZE') }}
          </label>
          <Input
            v-model.number="settings.batch_size"
            type="number"
            class="w-32"
          />
          <p class="text-xs text-n-slate-10 mt-1">
            {{ t('CAMPAIGN.WHATSAPP.SETTINGS.BATCH_SIZE_HINT') }}
          </p>
        </div>

        <!-- Max retry attempts -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('CAMPAIGN.WHATSAPP.SETTINGS.MAX_RETRIES') }}
          </label>
          <Input
            v-model.number="settings.max_retry_attempts"
            type="number"
            class="w-32"
          />
        </div>

        <!-- Send window -->
        <div class="border border-n-weak rounded-lg p-4 bg-n-surface-2">
          <label class="flex items-center gap-2 mb-3">
            <input
              v-model="settings.send_window_enabled"
              type="checkbox"
              class="rounded border-n-weak"
            />
            <span class="text-sm font-medium text-n-slate-11">
              {{ t('CAMPAIGN.WHATSAPP.SETTINGS.SEND_WINDOW_ENABLE') }}
            </span>
          </label>

          <div v-if="settings.send_window_enabled" class="flex gap-4">
            <div>
              <label class="block text-xs text-n-slate-10 mb-1">
                {{ t('CAMPAIGN.WHATSAPP.SETTINGS.SEND_WINDOW_START') }}
              </label>
              <Input
                v-model="settings.send_window_start"
                type="time"
                class="w-36"
              />
            </div>
            <div>
              <label class="block text-xs text-n-slate-10 mb-1">
                {{ t('CAMPAIGN.WHATSAPP.SETTINGS.SEND_WINDOW_END') }}
              </label>
              <Input
                v-model="settings.send_window_end"
                type="time"
                class="w-36"
              />
            </div>
          </div>
        </div>

        <!-- Default timezone -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('CAMPAIGN.WHATSAPP.SETTINGS.DEFAULT_TIMEZONE') }}
          </label>
          <Input
            v-model="settings.default_timezone"
            class="w-64"
          />
        </div>

        <div class="pt-4">
          <Button
            :label="t('CAMPAIGN.WHATSAPP.SETTINGS.SAVE')"
            color="blue"
            :is-loading="isSaving"
            @click="save"
          />
        </div>
      </div>
    </div>
  </div>
</template>
