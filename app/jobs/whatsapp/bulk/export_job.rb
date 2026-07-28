require 'csv'
require 'fileutils'

module Whatsapp
  module Bulk
    class ExportJob < ApplicationJob
      queue_as :campaign_exports

      EXPORT_DIR = Rails.root.join('tmp', 'whatsapp_exports')
      EXPIRY_HOURS = 24

      def perform(campaign_id)
        campaign = ::Whatsapp::BulkCampaign.find_by(id: campaign_id)
        return unless campaign

        recipients = campaign.recipients.order(:id)

        FileUtils.mkdir_p(EXPORT_DIR)

        filename = "campaign_#{campaign.id}_#{Time.current.strftime('%Y%m%d%H%M%S')}.csv"
        filepath = EXPORT_DIR.join(filename)

        CSV.open(filepath, 'w', headers: true, write_headers: true) do |csv|
          csv << [
            'Phone', 'Name', 'Status', 'Attempts',
            'Sent At', 'Delivered At', 'Read At', 'Replied At',
            'Failed At', 'Error Code', 'Failure Message',
            'Provider Message ID'
          ]

          recipients.find_each do |r|
            next if r.phone_number.blank?

            csv << [
              r.phone_number,
              r.consent_snapshot&.dig('original_name') || r.recipient_key || '',
              r.status,
              r.attempts_count || 0,
              r.sent_at&.iso8601,
              r.delivered_at&.iso8601,
              r.read_at&.iso8601,
              r.replied_at&.iso8601,
              r.failed_at&.iso8601,
              r.error_code,
              r.failure_message,
              r.provider_message_id
            ]
          end
        end

        campaign.update!(metadata: campaign.metadata.merge(
          export: {
            path: filepath.to_s,
            filename: filename,
            recipients_count: recipients.count,
            generated_at: Time.current.iso8601,
            expires_at: (Time.current + EXPIRY_HOURS.hours).iso8601
          }
        ))
      end
    end
  end
end
