/* global axios */
import ApiClient from './ApiClient';

class CampaignSettingsAPI extends ApiClient {
  constructor() {
    super('whatsapp/campaign_settings', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  update(settings) {
    return axios.patch(this.url, { settings });
  }
}

export default new CampaignSettingsAPI();
