module Whatsapp
  class BulkCampaign < ApplicationRecord
    STATUSES = %w[draft validating scheduled queued running paused completed completed_with_errors cancelled failed].freeze
    IMMUTABLE_AFTER_QUEUE = %w[inbox_id provider_template_name provider_template_language provider_template_category template_snapshot variable_mapping audience_definition consent_confirmation].freeze

    belongs_to :account
    belongs_to :inbox
    belongs_to :created_by, class_name: 'User', optional: true
    belongs_to :updated_by, class_name: 'User', optional: true

    enum :status, STATUSES.index_with(&:itself), validate: true

    validates :name, presence: true, length: { maximum: 255 }
    validates :timezone, presence: true
    validate :inbox_belongs_to_campaign_account
    validate :inbox_is_whatsapp_cloud
    validate :queued_campaign_attributes_are_immutable, on: :update

    private

    def inbox_belongs_to_campaign_account
      return if inbox.blank? || account_id.blank? || inbox.account_id == account_id

      errors.add(:inbox, 'must belong to the campaign account')
    end

    def inbox_is_whatsapp_cloud
      return if inbox.blank?

      channel = inbox.channel
      return if channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'

      errors.add(:inbox, 'must be a WhatsApp Cloud inbox')
    end

    def queued_campaign_attributes_are_immutable
      return unless status_before_last_save.in?(%w[queued running paused completed completed_with_errors cancelled failed])
      return if (changes.keys & IMMUTABLE_AFTER_QUEUE).empty?

      errors.add(:base, 'campaign configuration cannot change after queueing')
    end
  end
end
