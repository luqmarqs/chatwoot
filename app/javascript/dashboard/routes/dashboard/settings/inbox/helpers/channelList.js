export function filterChannelsForWhatsAppOnly(channels, isWhatsAppOnly) {
  if (!isWhatsAppOnly) return channels;

  return channels.filter(({ key }) => key === 'whatsapp');
}

export function filterOnboardingChannelsForWhatsAppOnly(
  channels,
  isWhatsAppOnly
) {
  if (!isWhatsAppOnly) return channels;

  return channels.filter(({ type }) => type === 'whatsapp');
}

export function filterInboxesForWhatsAppOnly(inboxes, isWhatsAppOnly) {
  if (!isWhatsAppOnly) return inboxes;

  return inboxes.filter(
    inbox =>
      inbox.channel_type === 'Channel::Whatsapp' &&
      inbox.provider === 'whatsapp_cloud'
  );
}
