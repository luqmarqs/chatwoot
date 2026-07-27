module Whatsapp
  module Bulk
    class TemplateSyncService
      pattr_initialize [:account!]

      def perform
        channels = account.whatsapp_channels.where(provider: 'whatsapp_cloud')
        return [] if channels.empty?

        templates = []
        channels.find_each do |channel|
          access_token = channel.provider_config&.dig('api_key')
          next if access_token.blank?

          business_account_id = channel.provider_config&.dig('business_account_id')
          next if business_account_id.blank?

          api_templates = fetch_provider_templates(access_token, business_account_id)
          next if api_templates.blank?

          api_templates.each do |t|
            template = upsert_template(t)
            templates << template if template.persisted?
          end
        end

        templates
      end

      private

      def fetch_provider_templates(access_token, waba_id)
        client = Whatsapp::FacebookApiClient.new(access_token)
        response = client.fetch_templates(waba_id)
        response&.dig('data') || []
      rescue StandardError => e
        Rails.logger.error "TemplateSyncService fetch error: #{e.message}"
        []
      end

      def upsert_template(api_template)
        provider_id   = api_template['id']
        name          = api_template['name']
        language      = api_template['language']
        category      = api_template['category']
        status        = api_template['status']&.downcase
        components    = api_template['components'] || []

        header_text, body_text, footer_text = extract_texts(components)
        button_labels = extract_buttons(components)

        template = account.whatsapp_bulk_templates.find_or_initialize_by(
          provider_template_id: provider_id
        )

        template.assign_attributes(
          name: name.presence || template.name || provider_id,
          provider_template_name: name,
          provider_template_namespace: api_template['namespace'],
          language: language,
          category: category,
          status: map_status(status),
          components: components,
          header_text: header_text,
          body_text: body_text,
          footer_text: footer_text,
          button_labels: button_labels,
          last_synced_at: Time.current,
          content_snapshot: {
            name: name,
            language: language,
            category: category,
            components: components,
            header_text: header_text,
            body_text: body_text,
            footer_text: footer_text,
            button_labels: button_labels
          }
        )

        template.approved_at = Time.current if template.status == 'approved'
        template.save!
        template
      end

      def extract_texts(components)
        header = find_component_text(components, 'HEADER')
        body   = find_component_text(components, 'BODY')
        footer = find_component_text(components, 'FOOTER')
        [header, body, footer]
      end

      def find_component_text(components, type)
        component = components.find { |c| c['type'] == type }
        return nil unless component

        component['text'] || component.dig('example', 'body_text', 0)
      end

      def extract_buttons(components)
        buttons = components.find { |c| c['type'] == 'BUTTONS' }
        return [] unless buttons

        (buttons['buttons'] || []).map { |b| b['text'] }.compact
      end

      def map_status(api_status)
        case api_status
        when 'approved' then 'approved'
        when 'rejected' then 'rejected'
        when 'pending', 'in_review' then 'pending'
        else 'draft'
        end
      end
    end
  end
end
