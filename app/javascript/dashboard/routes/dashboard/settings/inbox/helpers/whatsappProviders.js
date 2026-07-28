export function filterWhatsAppProviders(providers, isWhatsAppOnly) {
  if (!isWhatsAppOnly) return providers;

  return providers.filter(({ key }) => key === 'whatsapp');
}
