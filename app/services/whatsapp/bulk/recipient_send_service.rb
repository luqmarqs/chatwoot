module Whatsapp
  module Bulk
    class RecipientSendService
      pattr_initialize [:recipient!]

      def perform
        return if skip_recipient?

        recipient.update!(queued_at: Time.current)

        message_id = channel.send_template(
          recipient.phone_number,
          template_payload,
          nil
        )

        if message_id.blank?
          raise 'send_template returned empty message_id'
        end

        recipient.update!(
          status: :sent,
          sent_at: Time.current,
          provider_message_id: message_id,
          attempt_count: recipient.attempt_count + 1
        )

        campaign.events.create!(
          account: campaign.account,
          event_type: :queued,
          whatsapp_bulk_campaign_recipient: recipient,
          provider_message_id: message_id,
          occurred_at: Time.current
        )

        message_id
      rescue StandardError => e
        Rails.logger.error "BulkCampaign #{campaign.id} recipient #{recipient.recipient_key}: #{e.message}"
        recipient.update!(status: :failed, attempt_count: recipient.attempt_count + 1, failure_message: e.message, failed_at: Time.current)
        nil
      end

      private

      delegate :campaign, to: :recipient

      def skip_recipient?
        recipient.status.in?(%w[sent delivered read replied])
      end

      def channel
        @channel ||= campaign.inbox.channel
      end

      def template_payload
        params = recipient.template_parameters
        components = []

        if params.present?
          components << {
            type: 'body',
            parameters: params.map { |key, value|
              { type: 'text', parameter_name: key.to_s, text: value.to_s }
            }
          }
        end

        {
          name: campaign.provider_template_name,
          namespace: campaign.provider_template_namespace,
          lang_code: campaign.provider_template_language,
          parameters: components
        }
      end
    end
  end
end
