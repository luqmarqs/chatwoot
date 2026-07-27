class CreateWhatsappBulkCampaigns < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_bulk_campaigns do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: 'draft'
      t.string :timezone, null: false, default: 'UTC'
      t.string :provider_template_name
      t.string :provider_template_language
      t.string :provider_template_category
      t.jsonb :template_snapshot, null: false, default: {}
      t.jsonb :variable_mapping, null: false, default: {}
      t.jsonb :audience_definition, null: false, default: {}
      t.jsonb :consent_confirmation, null: false, default: {}
      t.datetime :scheduled_at
      t.datetime :started_at
      t.datetime :paused_at
      t.datetime :finished_at
      t.datetime :cancelled_at
      t.integer :rate_limit_per_minute
      t.integer :batch_size
      t.integer :max_retry_attempts
      t.boolean :send_window_enabled, null: false, default: false
      t.time :send_window_start
      t.time :send_window_end
      t.string :send_window_timezone
      t.integer :total_recipients, null: false, default: 0
      t.integer :pending_count, null: false, default: 0
      t.integer :queued_count, null: false, default: 0
      t.integer :processing_count, null: false, default: 0
      t.integer :sent_count, null: false, default: 0
      t.integer :delivered_count, null: false, default: 0
      t.integer :read_count, null: false, default: 0
      t.integer :replied_count, null: false, default: 0
      t.integer :failed_count, null: false, default: 0
      t.integer :skipped_count, null: false, default: 0
      t.integer :cancelled_count, null: false, default: 0
      t.integer :lock_version, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :whatsapp_bulk_campaigns, [:account_id, :status]
    add_index :whatsapp_bulk_campaigns, [:account_id, :scheduled_at]
  end
end
