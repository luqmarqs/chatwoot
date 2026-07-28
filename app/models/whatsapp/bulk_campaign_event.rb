module Whatsapp
  class BulkCampaignEvent < ApplicationRecord
    self.table_name = 'whatsapp_bulk_campaign_events'
    EVENT_TYPES = %w[queued sent delivered read replied failed skipped cancelled].freeze

    belongs_to :whatsapp_bulk_campaign, class_name: '::Whatsapp::BulkCampaign'
    belongs_to :whatsapp_bulk_campaign_recipient, class_name: '::Whatsapp::BulkCampaignRecipient', optional: true
    belongs_to :account

    validates :event_type, inclusion: { in: EVENT_TYPES }
    validates :occurred_at, presence: true
  end
end
