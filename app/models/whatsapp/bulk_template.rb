module Whatsapp
  class BulkTemplate < ApplicationRecord
    STATUSES = %w[draft pending approved rejected].freeze

    belongs_to :account
    belongs_to :created_by, class_name: 'User', optional: true
    belongs_to :updated_by, class_name: 'User', optional: true

    enum :status, STATUSES.index_with(&:itself), validate: true

    validates :name, presence: true, length: { maximum: 255 }
    validates :language, presence: true
    validates :provider_template_name, length: { maximum: 255 }, allow_nil: true
    validates :provider_template_id, uniqueness: { scope: :account_id, allow_nil: true }

    scope :approved, -> { where(status: :approved) }
    scope :by_language, ->(lang) { where(language: lang) }

    def approved?
      status == 'approved'
    end

    def syncable?
      provider_template_id.present?
    end

    def snapshot!
      update!(content_snapshot: {
        name: provider_template_name,
        language: language,
        category: category,
        components: components,
        header_text: header_text,
        body_text: body_text,
        footer_text: footer_text,
        button_labels: button_labels
      })
    end
  end
end
