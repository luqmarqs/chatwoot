import { describe, expect, it } from 'vitest';
import {
  filterChannelsForWhatsAppOnly,
  filterInboxesForWhatsAppOnly,
  filterOnboardingChannelsForWhatsAppOnly,
} from '../channelList';

describe('filterChannelsForWhatsAppOnly', () => {
  const channels = [{ key: 'website' }, { key: 'whatsapp' }, { key: 'email' }];

  it('returns only WhatsApp when the restricted mode is active', () => {
    expect(filterChannelsForWhatsAppOnly(channels, true)).toEqual([
      { key: 'whatsapp' },
    ]);
  });

  it('preserves the upstream channel catalogue when the restricted mode is inactive', () => {
    expect(filterChannelsForWhatsAppOnly(channels, false)).toEqual(channels);
  });
});

describe('filterOnboardingChannelsForWhatsAppOnly', () => {
  const channels = [
    { type: 'facebook' },
    { type: 'whatsapp' },
    { type: 'email' },
  ];

  it('keeps only WhatsApp suggestions in restricted mode', () => {
    expect(filterOnboardingChannelsForWhatsAppOnly(channels, true)).toEqual([
      { type: 'whatsapp' },
    ]);
  });

  it('preserves onboarding suggestions when restricted mode is disabled', () => {
    expect(filterOnboardingChannelsForWhatsAppOnly(channels, false)).toEqual(
      channels
    );
  });
});

describe('filterInboxesForWhatsAppOnly', () => {
  const inboxes = [
    { channel_type: 'Channel::WebWidget', provider: null },
    { channel_type: 'Channel::Whatsapp', provider: 'default' },
    { channel_type: 'Channel::Whatsapp', provider: 'whatsapp_cloud' },
  ];

  it('keeps only WhatsApp Cloud inboxes when restricted mode is enabled', () => {
    expect(filterInboxesForWhatsAppOnly(inboxes, true)).toEqual([
      { channel_type: 'Channel::Whatsapp', provider: 'whatsapp_cloud' },
    ]);
  });

  it('keeps legacy inboxes visible when restricted mode is disabled', () => {
    expect(filterInboxesForWhatsAppOnly(inboxes, false)).toEqual(inboxes);
  });
});
