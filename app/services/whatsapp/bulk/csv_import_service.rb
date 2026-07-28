require 'csv'

module Whatsapp
  module Bulk
    class CsvImportService
      MAX_FILE_SIZE = 10.megabytes
      ALLOWED_MIME_TYPES = %w[text/csv text/plain application/csv application/vnd.ms-excel].freeze

      pattr_initialize [:campaign!, :csv_content!, :account!, { file: nil }]

      def perform
        imported = 0
        skipped  = 0
        errors   = []

        rows = CSV.parse(csv_content, headers: true)
        rows.each_with_index do |row, idx|
          phone = normalize_phone(row['phone'] || row['phone_number'] || row['telefone'] || row['celular'] || '')
          name  = sanitize_cell(row['name'] || row['nome'] || row['contact_name'] || '')
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
        Whatsapp::Bulk::ReconcileStatsJob.perform_later(campaign.id)

        { imported: imported, skipped: skipped, errors: errors }
      end

      # Validate file before parsing. Returns nil on success, or an error hash.
      def self.validate_file(file)
        unless file
          return { error: 'No file provided', status: :unprocessable_entity }
        end

        if file.size > MAX_FILE_SIZE
          return { error: "File too large (max #{MAX_FILE_SIZE / 1.megabyte}MB)", status: :unprocessable_entity }
        end

        content_type = file.content_type.to_s.split(';').first.strip.downcase
        unless ALLOWED_MIME_TYPES.include?(content_type)
          return { error: "Invalid file type '#{content_type}'. Accepted: CSV", status: :unsupported_media_type }
        end

        nil
      end

      private

      FORMULA_TRIGGERS = %w[= + - @].freeze

      # Neutralize CSV formula injection by prefixing dangerous chars with a single quote
      def sanitize_cell(value)
        str = value.to_s.strip
        return str if str.empty?

        if FORMULA_TRIGGERS.include?(str[0])
          "'#{str}"
        else
          str
        end
      end

      def normalize_phone(raw)
        return nil if raw.blank?

        digits = raw.to_s.gsub(/[^\d+]/, '')
        # Formula injection protection for phone
        digits = sanitize_cell(digits)
        digits = "+#{digits}" unless digits.start_with?('+')
        digits
      end

      def parse_params(raw)
        return {} if raw.blank?

        JSON.parse(raw)
      rescue JSON::ParserError
        { text: sanitize_cell(raw.to_s) }
      end
    end
  end
end
