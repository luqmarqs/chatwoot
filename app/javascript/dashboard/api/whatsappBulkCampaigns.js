import ApiClient from './ApiClient';

class WhatsappBulkCampaignsAPI extends ApiClient {
  constructor() {
    super('whatsapp/bulk_campaigns', { accountScoped: true });
  }

  send(id) {
    return axios.post(`${this.url}/${id}/send`);
  }

  recipients(id) {
    return axios.get(`${this.url}/${id}/recipients`);
  }
}

export default new WhatsappBulkCampaignsAPI();
