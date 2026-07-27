module Whatsapp
  module Bulk
    class AudienceSnapshotService
      pattr_initialize [:account!, :audience_definition!]

      def perform
        contacts = resolve_contacts
        {
          total: contacts.size,
          resolved_at: Time.current.iso8601,
          filters: audience_definition,
          sample: contacts.limit(5).pluck(:id, :name, :phone_number).map do |id, name, phone|
            { id: id, name: name, phone: phone }
          end
        }
      end

      def preview_count
        resolve_contacts.size
      end

      private

      def resolve_contacts
        scope = account.contacts

        if audience_definition['contact_ids'].present?
          scope = scope.where(id: audience_definition['contact_ids'])
        end

        if audience_definition['labels'].present?
          scope = scope.joins(:labels).where(labels: { title: audience_definition['labels'] })
        end

        if audience_definition['tags'].present?
          tag_ids = audience_definition['tags']
          scope = scope.joins(:taggings).where(taggings: { tag_id: tag_ids })
        end

        if audience_definition['custom_filters'].present? && audience_definition['custom_filters']['phone_has_value'] == true
          scope = scope.where.not(phone_number: [nil, ''])
        end

        scope.distinct
      end
    end
  end
end
