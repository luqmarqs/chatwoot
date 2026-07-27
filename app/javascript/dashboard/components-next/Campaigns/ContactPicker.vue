<script setup>
import { ref, watch, computed } from 'vue';
import { useDebounceFn } from '@vueuse/core';
import ContactsAPI from 'dashboard/api/contacts';
import Input from 'dashboard/components-next/input/Input.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  modelValue: { type: Array, default: () => [] },
});

const emit = defineEmits(['update:modelValue']);

const search = ref('');
const contacts = ref([]);
const isLoading = ref(false);
const selectedIds = ref(new Set(props.modelValue));

const debouncedSearch = useDebounceFn(async (query) => {
  if (!query || query.length < 2) {
    contacts.value = [];
    return;
  }
  isLoading.value = true;
  try {
    const { data } = await ContactsAPI.search(query);
    contacts.value = data.payload || [];
  } catch {
    contacts.value = [];
  } finally {
    isLoading.value = false;
  }
}, 300);

watch(search, (val) => {
  debouncedSearch(val);
});

const toggle = (id) => {
  const next = new Set(selectedIds.value);
  if (next.has(id)) {
    next.delete(id);
  } else {
    next.add(id);
  }
  selectedIds.value = next;
  emit('update:modelValue', [...next]);
};

const selectedCount = computed(() => selectedIds.value.size);
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <div class="flex flex-col gap-3">
    <div class="flex items-center gap-2">
      <Input
        v-model="search"
        placeholder="Search contacts by name or phone..."
        class="flex-1"
      />
      <span
        v-if="selectedCount > 0"
        class="text-xs font-medium text-n-blue-11 whitespace-nowrap"
      >
        {{ selectedCount }} selected
      </span>
    </div>

    <div class="max-h-48 overflow-y-auto border border-n-weak rounded-lg">
      <div v-if="isLoading" class="flex justify-center py-4">
        <Spinner size="sm" />
      </div>

      <div
        v-else-if="contacts.length === 0 && search.length >= 2"
        class="py-4 text-center text-sm text-n-slate-10"
      >
        No contacts found
      </div>

      <label
        v-for="contact in contacts"
        :key="contact.id"
        class="flex items-center gap-3 px-3 py-2 cursor-pointer hover:bg-n-alpha-2 transition-colors"
        :class="{
          'bg-n-blue-2': selectedIds.has(contact.id),
        }"
      >
        <input
          type="checkbox"
          :checked="selectedIds.has(contact.id)"
          class="rounded"
          @change="toggle(contact.id)"
        />
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-n-slate-12 truncate">
            {{ contact.name || contact.identifier || 'Unnamed' }}
          </p>
          <p class="text-xs text-n-slate-10">
            {{ contact.phone_number || contact.email || '—' }}
          </p>
        </div>
      </label>

      <div
        v-if="!isLoading && search.length < 2"
        class="py-4 text-center text-sm text-n-slate-10"
      >
        Type at least 2 characters to search
      </div>
    </div>
  </div>
</template>
