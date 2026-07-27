/* global axios */
import ApiClient from './ApiClient';

class WhatsappBulkCampaignsAPI extends ApiClient {
  constructor() {
    super('whatsapp/bulk_campaigns', { accountScoped: true });
  }

  send(id) {
    return axios.post(`${this.url}/${id}/send`);
  }

  pause(id) {
    return axios.post(`${this.url}/${id}/pause`);
  }

  resume(id) {
    return axios.post(`${this.url}/${id}/resume`);
  }

  cancel(id) {
    return axios.post(`${this.url}/${id}/cancel`);
  }

  recipients(id) {
    return axios.get(`${this.url}/${id}/recipients`);
  }

  exportCsv(id) {
    return axios.get(`${this.url}/${id}/export_csv`, { responseType: 'blob' });
  }
}

export default new WhatsappBulkCampaignsAPI();
