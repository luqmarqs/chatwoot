module Whatsapp
  class BulkCampaign < ApplicationRecord
    STATUSES = %w[draft validating scheduled queued running paused completed completed_with_errors cancelled failed].freeze
    IMMUTABLE_AFTER_QUEUE = %w[inbox_id provider_template_name provider_template_language provider_template_category template_snapshot variable_mapping audience_definition consent_confirmation].freeze

    belongs_to :account
    belongs_to :inbox
    belongs_to :created_by, class_name: 'User', optional: true
    belongs_to :updated_by, class_name: 'User', optional: true

    has_many :recipients, class_name: '::Whatsapp::BulkCampaignRecipient', dependent: :destroy_async,
                          foreign_key: :whatsapp_bulk_campaign_id
    has_many :events, class_name: '::Whatsapp::BulkCampaignEvent', dependent: :destroy_async,
                      foreign_key: :whatsapp_bulk_campaign_id

    enum :status, STATUSES.index_with(&:itself), validate: true

    validates :name, presence: true, length: { maximum: 255 }
    validates :timezone, presence: true
    validate :inbox_belongs_to_campaign_account
    validate :inbox_is_whatsapp_cloud
    validate :queued_campaign_attributes_are_immutable, on: :update

    def validate!
      raise 'Campaign must be draft or validating' unless status.in?(%w[draft validating])
      raise 'Template name is required' if provider_template_name.blank?
      raise 'No recipients' if recipients.none?
      raise 'Inbox is not WhatsApp Cloud' unless whatsapp_cloud?

      validating!
    end

    def total_recipients
      recipients.size
    end

    def pending_count
      recipients_count_by_status('pending')
    end

    def queued_count
      recipients_count_by_status('queued')
    end

    def processing_count
      recipients_count_by_status('processing')
    end

    def sent_count
      recipients_count_by_status('sent')
    end

    def delivered_count
      recipients_count_by_status('delivered')
    end

    def read_count
      recipients_count_by_status('read')
    end

    def replied_count
      recipients_count_by_status('replied')
    end

    def failed_count
      recipients_count_by_status('failed')
    end

    def skipped_count
      recipients_count_by_status('skipped')
    end

    def cancelled_count
      recipients_count_by_status('cancelled')
    end

    def succeeded_count
      sent_count + delivered_count + read_count + replied_count
    end

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

    def whatsapp_cloud?
      return false if inbox.blank?

      channel = inbox.channel
      channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'
    end

    private

    def recipients_count_by_status(status)
      recipients.count { |r| r.status == status }
    end
  end
end
