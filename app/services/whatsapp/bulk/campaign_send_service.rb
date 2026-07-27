module Whatsapp
  module Bulk
    class CampaignSendService
      pattr_initialize [:campaign!]

      def perform
        resolve_audience!
        validate!
        campaign.queued!

        if campaign.rate_limit_per_minute&.positive? && campaign.recipients.count > 10
          throttled_send
        else
          direct_send
        end

        finalize_campaign
      end

      private

      def resolve_audience!
        return if campaign.audience_definition.blank?
        return if campaign.recipients.exists?

        contacts = Whatsapp::Bulk::AudienceSnapshotService.new(
          account: campaign.account,
          audience_definition: campaign.audience_definition
        ).resolve_contacts

        contacts.find_each do |contact|
          next if contact.phone_number.blank?

          template_params = {}
          if campaign.template_snapshot.present?
            body_text = campaign.template_snapshot['body_text'] || campaign.template_snapshot['body'] || ''
            param_names = body_text.scan(/\{\{(\w+)\}\}/).flatten
            param_names.each do |pname|
              if pname =~ /nome|name|first/i && contact.name.present?
                template_params[pname] = contact.name.split.first
              end
            end
          end

          campaign.recipients.create!(
            account: campaign.account,
            phone_number: contact.phone_number,
            recipient_key: contact.phone_number,
            status: :pending,
            contact_id: contact.id,
            template_parameters: template_params,
            consent_snapshot: { source: 'contact_sync', synced_at: Time.current.iso8601 }
          )
        end

        Whatsapp::Bulk::ReconcileStatsJob.perform_later(campaign.id)
      end

      def throttled_send
        Whatsapp::Bulk::RateLimiterService.new(campaign).throttle
      end

      def direct_send
        recipients.find_each do |recipient|
          Whatsapp::Bulk::RecipientSendService.new(recipient: recipient).perform
        end
      end

      def validate!
        raise 'Campaign not in valid state' unless campaign.draft? || campaign.validating? || campaign.running? || campaign.queued?
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
        Whatsapp::Bulk::ReconcileStatsJob.perform_now(campaign.id)

        failed = campaign.reload.failed_count

        campaign.completed! if failed.zero?
        campaign.completed_with_errors! if failed.positive?
      rescue StandardError => e
        Rails.logger.error "BulkCampaign #{campaign.id} finalize error: #{e.message}"
        campaign.failed!
      end
    end
  end
end
