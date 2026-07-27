module Whatsapp
  module Bulk
    class ReplyAttributionService
      pattr_initialize [:contact!, :inbox!]

      # Detects if this contact is a bulk campaign recipient and updates status to "replied"
      def perform
        phone = normalize_phone(contact.phone_number)
        return unless phone

        recipients = find_pending_recipients(phone)
        return if recipients.empty?

        recipients.each do |recipient|
          recipient.update!(status: :replied, replied_at: Time.current)

          recipient.whatsapp_bulk_campaign.events.create!(
            account: recipient.account,
            event_type: :replied,
            whatsapp_bulk_campaign_recipient: recipient,
            occurred_at: Time.current,
            payload: { contact_id: contact.id, phone: phone }
          )

          Whatsapp::Bulk::ReconcileStatsJob.perform_later(recipient.whatsapp_bulk_campaign_id)
        end
      end

      private

      def find_pending_recipients(phone)
        Whatsapp::BulkCampaignRecipient
          .joins(:whatsapp_bulk_campaign)
          .where(phone_number: phone)
          .where(status: %w[sent delivered read])
          .where(whatsapp_bulk_campaign: { inbox_id: inbox.id })
      end

      def normalize_phone(raw)
        return nil if raw.blank?

        digits = raw.to_s.gsub(/[^\d+]/, '')
        digits = "+#{digits}" unless digits.start_with?('+')
        digits
      end
    end
  end
end
