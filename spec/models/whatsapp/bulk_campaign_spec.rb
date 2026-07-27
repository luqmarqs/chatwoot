require 'rails_helper'

RSpec.describe Whatsapp::BulkCampaign do
  describe 'inbox validation' do
    it 'accepts a WhatsApp Cloud inbox belonging to its account' do
      account = create(:account)
      channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
      inbox = create(:inbox, account: account, channel: channel)

      campaign = described_class.new(account: account, inbox: inbox, name: 'Mobilização')

      expect(campaign).to be_valid
    end
  end
end
