class CreateWhatsappBulkCampaignRecipients < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_bulk_campaign_recipients do |t|
      t.references :whatsapp_bulk_campaign, null: false, foreign_key: true, index: { name: 'index_bulk_recipients_on_campaign' }
      t.references :account, null: false, foreign_key: true
      t.references :contact, foreign_key: true
      t.references :contact_inbox, foreign_key: true
      t.string :recipient_key, null: false
      t.string :phone_number, null: false
      t.string :status, null: false, default: 'pending'
      t.jsonb :template_parameters, null: false, default: {}
      t.jsonb :consent_snapshot, null: false, default: {}
      t.string :provider_message_id
      t.integer :attempt_count, null: false, default: 0
      t.datetime :queued_at
      t.datetime :sent_at
      t.datetime :delivered_at
      t.datetime :read_at
      t.datetime :replied_at
      t.datetime :failed_at
      t.text :failure_code
      t.text :failure_message
      t.timestamps
    end

    add_index :whatsapp_bulk_campaign_recipients, [:whatsapp_bulk_campaign_id, :recipient_key], unique: true,
                                                                                              name: 'index_bulk_recipients_on_campaign_and_key'
    add_index :whatsapp_bulk_campaign_recipients, [:whatsapp_bulk_campaign_id, :status],
              name: 'index_bulk_recipients_on_campaign_and_status'
    add_index :whatsapp_bulk_campaign_recipients, :provider_message_id, unique: true,
                                                              where: 'provider_message_id IS NOT NULL',
                                                              name: 'index_bulk_recipients_on_provider_message_id'
  end
end
