class CreateWhatsappBulkCampaignEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_bulk_campaign_events do |t|
      t.references :whatsapp_bulk_campaign, null: false, foreign_key: true, index: { name: 'index_bulk_events_on_campaign' }
      t.references :whatsapp_bulk_campaign_recipient, foreign_key: true, index: { name: 'index_bulk_events_on_recipient' }
      t.references :account, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :provider_message_id
      t.jsonb :payload, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_index :whatsapp_bulk_campaign_events, [:whatsapp_bulk_campaign_id, :event_type, :occurred_at],
              name: 'index_bulk_events_on_campaign_type_occurred_at'
    add_index :whatsapp_bulk_campaign_events, :provider_message_id,
              name: 'index_bulk_events_on_provider_message_id'
  end
end
