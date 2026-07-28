class AddSucceededCountToWhatsappBulkCampaigns < ActiveRecord::Migration[7.1]
  def change
    add_column :whatsapp_bulk_campaigns, :succeeded_count, :integer, null: false, default: 0
  end
end
