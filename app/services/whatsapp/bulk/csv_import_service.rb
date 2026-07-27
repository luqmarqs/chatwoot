require 'csv'

module Whatsapp
  module Bulk
    class CsvImportService
      pattr_initialize [:campaign!, :csv_content!, :account!]

      def perform
        imported = 0
        skipped  = 0
        errors   = []

        rows = CSV.parse(csv_content, headers: true)
        rows.each_with_index do |row, idx|
          phone = normalize_phone(row['phone'] || row['phone_number'] || row['telefone'] || row['celular'] || '')
          name  = row['name'] || row['nome'] || row['contact_name'] || ''
          params_json = parse_params(row['params'] || row['template_params'] || row['parameters'] || '{}')

          if phone.blank?
            skipped += 1
            errors << { row: idx + 2, error: 'Missing phone number' }
            next
          end

          recipient_key = "csv:#{phone}:#{idx}"
          existing = campaign.recipients.find_by(recipient_key: recipient_key)
          if existing
            skipped += 1
            next
          end

          campaign.recipients.create!(
            account: account,
            phone_number: phone,
            recipient_key: recipient_key,
            template_parameters: params_json,
            consent_snapshot: { source: 'csv_import', imported_at: Time.current.iso8601, original_name: name }
          )
          imported += 1
        rescue StandardError => e
          skipped += 1
          errors << { row: idx + 2, error: e.message }
        end

        campaign.update!(total_recipients: campaign.recipients.count)

        { imported: imported, skipped: skipped, errors: errors }
      end

      private

      def normalize_phone(raw)
        return nil if raw.blank?

        digits = raw.to_s.gsub(/[^\d+]/, '')
        digits = "+#{digits}" unless digits.start_with?('+')
        digits
      end

      def parse_params(raw)
        return {} if raw.blank?

        JSON.parse(raw)
      rescue JSON::ParserError
        { text: raw.to_s }
      end
    end
  end
end
