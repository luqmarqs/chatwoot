module Whatsapp
  module Bulk
    class WebhookStatusService
      pattr_initialize [:params!]

      def perform
        statuses.each { |status| process_status(status) }
      end

      private

      def statuses
        entries = params.dig(:entry) || []
        entries.flat_map do |entry|
          changes = entry.dig(:changes) || []
          changes.flat_map do |change|
            next [] unless change.dig(:field) == 'messages'

            value = change.dig(:value) || {}
            statuses = value.dig(:statuses) || []
            statuses.map { |s| s.merge(metadata: value[:metadata] || {}) }
          end
        end
      end

      def process_status(status)
        message_id = status[:id]
        return if message_id.blank?

        recipient = find_recipient(message_id)
        return unless recipient

        new_status = map_status(status[:status])
        return unless new_status

        update_recipient(recipient, new_status, status)
      end

      def find_recipient(message_id)
        Whatsapp::BulkCampaignRecipient.find_by(provider_message_id: message_id)
      end

      def map_status(meta_status)
        case meta_status
        when 'sent' then :sent
        when 'delivered' then :delivered
        when 'read' then :read
        when 'failed' then :failed
        end
      end

      def update_recipient(recipient, new_status, status)
        timestamp = Time.at(status[:timestamp].to_i) if status[:timestamp]

        attrs = { status: new_status }
        attrs[:"#{new_status}_at"] = timestamp if timestamp

        if new_status == :failed
          error = status.dig(:errors, 0) || {}
          attrs[:failure_code] = error[:code]&.to_s
          attrs[:failure_message] = error[:title] || error[:message]
          attrs[:failed_at] = timestamp || Time.current
        end

        recipient.update!(attrs)

        recipient.whatsapp_bulk_campaign.events.create!(
          account: recipient.account,
          event_type: new_status,
          whatsapp_bulk_campaign_recipient: recipient,
          provider_message_id: status[:id],
          occurred_at: timestamp || Time.current,
          payload: status
        )
      end
    end
  end
end
