import { describe, expect, it } from 'vitest';
import { useWhatsAppOnly } from '../useWhatsAppOnly';

describe('useWhatsAppOnly', () => {
  it('enables the restricted experience only for a boolean true config value', () => {
    window.chatwootConfig = { whatsappOnly: true };
    expect(useWhatsAppOnly().isWhatsAppOnly.value).toBe(true);

    window.chatwootConfig = { whatsappOnly: false };
    expect(useWhatsAppOnly().isWhatsAppOnly.value).toBe(false);

    window.chatwootConfig = { whatsappOnly: 'true' };
    expect(useWhatsAppOnly().isWhatsAppOnly.value).toBe(false);

    window.chatwootConfig = {};
    expect(useWhatsAppOnly().isWhatsAppOnly.value).toBe(false);
  });
});
