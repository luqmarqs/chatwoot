<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const { t } = useI18n();
const store = useStore();
const createDialog = ref(null);
const deleteId = ref(null);
const editTemplate = ref(null);

// Form state
const formName = ref('');
const formLanguage = ref('pt_BR');
const formCategory = ref('MARKETING');
const formHeader = ref('');
const formBody = ref('');
const formFooter = ref('');

const templates = useMapGetter('whatsappBulkTemplates/getAll');
const uiFlags = useMapGetter('whatsappBulkTemplates/getUIFlags');

onMounted(() => store.dispatch('whatsappBulkTemplates/get'));

const statusColors = {
  draft: 'bg-n-alpha-2 text-n-slate-12',
  pending: 'bg-n-yellow-3 text-n-yellow-11',
  approved: 'bg-n-green-4 text-n-green-11',
  rejected: 'bg-n-red-3 text-n-red-11',
};

const categoryLabels = {
  MARKETING: 'Marketing',
  UTILITY: 'Utility',
  AUTHENTICATION: 'Authentication',
};

const sync = async () => {
  await store.dispatch('whatsappBulkTemplates/syncFromProvider');
};

const openCreate = () => {
  formName.value = '';
  formLanguage.value = 'pt_BR';
  formCategory.value = 'MARKETING';
  formHeader.value = '';
  formBody.value = '';
  formFooter.value = '';
  editTemplate.value = null;
  createDialog.value?.open();
};

const save = async () => {
  const payload = {
    name: formName.value.trim(),
    language: formLanguage.value,
    category: formCategory.value,
    header_text: formHeader.value.trim() || null,
    body_text: formBody.value.trim() || null,
    footer_text: formFooter.value.trim() || null,
  };
  await store.dispatch('whatsappBulkTemplates/create', payload);
  createDialog.value?.close();
};

const remove = async id => {
  deleteId.value = id;
  await store.dispatch('whatsappBulkTemplates/delete', id);
  deleteId.value = null;
};

const isEmpty = computed(
  () => !uiFlags.value.isFetching && templates.value.length === 0
);
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <div class="flex flex-col h-full p-6 overflow-auto bg-n-surface-1">
    <div class="flex items-center justify-between mb-6">
      <h2 class="text-lg font-semibold text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.TEMPLATES.TITLE') || 'Message Templates' }}
      </h2>
      <div class="flex gap-2">
        <Button
          label="New Template"
          color="blue"
          size="sm"
          @click="openCreate"
        />
        <Button
          :label="t('CAMPAIGN.WHATSAPP.TEMPLATES.SYNC') || 'Sync from WhatsApp'"
          color="blue"
          variant="outline"
          size="sm"
          :is-loading="uiFlags.isSyncing"
          @click="sync"
        />
      </div>
    </div>

    <div v-if="uiFlags.isFetching" class="flex justify-center py-12">
      <Spinner />
    </div>

    <div v-else-if="isEmpty" class="py-14 text-center">
      <p class="text-base font-medium text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.TEMPLATES.EMPTY') || 'No templates yet' }}
      </p>
      <p class="mt-2 text-sm text-n-slate-11">
        {{
          t('CAMPAIGN.WHATSAPP.TEMPLATES.EMPTY_HINT') ||
          'Sync templates from WhatsApp or create a new one'
        }}
      </p>
    </div>

    <div v-else class="grid gap-3">
      <article
        v-for="template in templates"
        :key="template.id"
        class="p-4 border rounded-lg border-n-weak bg-n-surface-2"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <p class="font-medium text-n-slate-12 truncate">
                {{ template.name }}
              </p>
              <span
                class="px-2 py-0.5 text-xs font-medium rounded-full"
                :class="[
                  statusColors[template.status] ||
                    'bg-n-alpha-2 text-n-slate-12',
                ]"
                >{{ template.status }}</span>
              <span
                v-if="template.category"
                class="px-2 py-0.5 text-xs font-medium rounded-full bg-n-blue-3 text-n-blue-11"
                >{{
                  categoryLabels[template.category] || template.category
                }}</span>
            </div>
            <p class="mt-1 text-sm text-n-slate-11 truncate">
              {{ template.body_text || template.provider_template_name }}
            </p>
            <div class="flex gap-3 mt-2 text-xs text-n-slate-10">
              <span>{{ template.language }}</span>
              <span v-if="template.provider_template_name">• {{ template.provider_template_name }}</span>
            </div>
          </div>
          <Button
            label="Delete"
            color="red"
            variant="outline"
            size="xs"
            :is-loading="deleteId === template.id"
            @click="remove(template.id)"
          />
        </div>
      </article>
    </div>

    <!-- Create dialog -->
    <Dialog ref="createDialog" width="lg" @confirm="save">
      <div class="flex flex-col gap-3">
        <span class="text-base font-medium text-n-slate-12">Create Template</span>
        <Input v-model="formName" placeholder="Template name" />
        <div class="flex gap-2">
          <select
            v-model="formLanguage"
            class="flex-1 px-3 py-2 border rounded-lg border-n-weak bg-n-surface-2 text-n-slate-12"
          >
            <option value="pt_BR">pt_BR</option>
            <option value="en">en</option>
            <option value="es">es</option>
          </select>
          <select
            v-model="formCategory"
            class="flex-1 px-3 py-2 border rounded-lg border-n-weak bg-n-surface-2 text-n-slate-12"
          >
            <option value="MARKETING">Marketing</option>
            <option value="UTILITY">Utility</option>
            <option value="AUTHENTICATION">Authentication</option>
          </select>
        </div>
        <Input v-model="formHeader" placeholder="Header text (optional)" />
        <textarea
          v-model="formBody"
          placeholder="Body text"
          class="w-full px-3 py-2 border rounded-lg border-n-weak bg-n-surface-2 text-n-slate-12 resize-none"
          rows="3"
        />
        <Input v-model="formFooter" placeholder="Footer text (optional)" />
      </div>
      <template #footer>
        <div class="flex justify-end gap-3">
          <Button
            :label="t('DIALOG.BUTTONS.CANCEL')"
            variant="link"
            @click="createDialog?.close()"
          />
          <Button
            label="Save"
            type="submit"
            :disabled="!formName.trim() || !formBody.trim()"
            :is-loading="uiFlags.isCreating"
          />
        </div>
      </template>
    </Dialog>
  </div>
</template>
