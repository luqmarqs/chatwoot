class AddProviderTemplateNamespaceToWhatsappBulkCampaigns < ActiveRecord::Migration[7.1]
  def change
    add_column :whatsapp_bulk_campaigns, :provider_template_namespace, :string
  end
end
