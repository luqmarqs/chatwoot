module Whatsapp
  class BulkCampaignRecipient < ApplicationRecord
    self.table_name = 'whatsapp_bulk_campaign_recipients'
    STATUSES = %w[pending queued processing sent delivered read replied failed skipped cancelled].freeze

    belongs_to :whatsapp_bulk_campaign, class_name: '::Whatsapp::BulkCampaign'
    belongs_to :account
    belongs_to :contact, optional: true
    belongs_to :contact_inbox, optional: true

    validates :recipient_key, :phone_number, :status, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :recipient_key, uniqueness: { scope: :whatsapp_bulk_campaign_id }
  end
end
