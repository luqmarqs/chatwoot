module Whatsapp
  module Bulk
    class CampaignSendService
      pattr_initialize [:campaign!]

      def perform
        validate!
        campaign.queued!

        recipients.find_each do |recipient|
          Whatsapp::Bulk::RecipientSendService.new(recipient: recipient).perform
        end

        finalize_campaign
      end

      private

      def validate!
        raise 'Campaign is not in draft state' unless campaign.draft?
        raise 'Inbox is not WhatsApp Cloud' unless whatsapp_cloud?
        raise 'No recipients' if campaign.recipients.none?
      end

      def recipients
        campaign.recipients.where(status: %w[pending failed])
      end

      def whatsapp_cloud?
        channel = campaign.inbox.channel
        channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'
      end

      def finalize_campaign
        failed = campaign.recipients.where(status: :failed).count

        campaign.completed! if failed.zero?
        campaign.completed_with_errors! if failed.positive?
      rescue StandardError => e
        Rails.logger.error "BulkCampaign #{campaign.id} finalize error: #{e.message}"
        campaign.failed!
      end
    end
  end
end
