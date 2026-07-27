class CreateWhatsappBulkTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_bulk_templates do |t|
      t.references :account, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :provider_template_id
      t.string :provider_template_name
      t.string :provider_template_namespace
      t.string :language, null: false, default: 'pt_BR'
      t.string :category
      t.string :status, null: false, default: 'draft'
      t.jsonb :content_snapshot, null: false, default: {}
      t.jsonb :components, null: false, default: []
      t.text :header_text
      t.text :body_text
      t.text :footer_text
      t.jsonb :button_labels, null: false, default: []
      t.datetime :last_synced_at
      t.datetime :approved_at
      t.text :rejected_reason
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :whatsapp_bulk_templates, [:account_id, :provider_template_id],
              unique: true, where: 'provider_template_id IS NOT NULL',
              name: 'index_bulk_templates_on_account_and_provider_template'
    add_index :whatsapp_bulk_templates, [:account_id, :status],
              name: 'index_bulk_templates_on_account_and_status'
  end
end
