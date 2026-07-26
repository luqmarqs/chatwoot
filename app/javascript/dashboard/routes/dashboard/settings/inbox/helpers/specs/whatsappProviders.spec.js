import { describe, expect, it } from 'vitest';
import { filterWhatsAppProviders } from '../whatsappProviders';

describe('filterWhatsAppProviders', () => {
  const providers = [{ key: 'whatsapp' }, { key: 'twilio' }];

  it('keeps only the official WhatsApp Cloud provider in restricted mode', () => {
    expect(filterWhatsAppProviders(providers, true)).toEqual([
      { key: 'whatsapp' },
    ]);
  });

  it('preserves providers when restricted mode is disabled', () => {
    expect(filterWhatsAppProviders(providers, false)).toEqual(providers);
  });
});
