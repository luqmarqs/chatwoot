import { computed } from 'vue';

export function useWhatsAppOnly() {
  const isWhatsAppOnly = computed(
    () => window.chatwootConfig?.whatsappOnly === true
  );

  return { isWhatsAppOnly };
}
