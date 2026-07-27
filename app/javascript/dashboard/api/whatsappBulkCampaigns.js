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

  audiencePreview(definition) {
    return axios.post(`${this.url}/audience_preview`, {
      audience_definition: definition,
    });
  }

  importRecipients(id, file) {
    const formData = new FormData();
    formData.append('file', file);
    const accountId = window.location.pathname.split('/')[2];
    return axios.post(
      `/api/v1/accounts/${accountId}/whatsapp/bulk_campaigns/${id}/import_recipients`,
      formData,
      { headers: { 'Content-Type': 'multipart/form-data' } }
    );
  }

  exportCsv(id) {
    return axios.get(`${this.url}/${id}/export_csv`, { responseType: 'blob' });
  }
}

export default new WhatsappBulkCampaignsAPI();
