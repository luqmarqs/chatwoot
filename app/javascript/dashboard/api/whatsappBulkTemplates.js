/* global axios */
import ApiClient from './ApiClient';

class WhatsappBulkTemplatesAPI extends ApiClient {
  constructor() {
    super('whatsapp/bulk_templates', { accountScoped: true });
  }

  syncFromProvider() {
    return axios.post(`${this.url}/sync_from_provider`);
  }
}

export default new WhatsappBulkTemplatesAPI();
