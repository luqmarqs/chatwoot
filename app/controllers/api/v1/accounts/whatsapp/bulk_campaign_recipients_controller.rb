class Api::V1::Accounts::Whatsapp::BulkCampaignRecipientsController < Api::V1::Accounts::BaseController
  before_action :ensure_feature_enabled
  before_action :fetch_campaign

  def index
    @recipients = @campaign.recipients.order(:id)
  end

  private

  def ensure_feature_enabled
    head :not_found unless Feature.enabled?(:whatsapp_bulk_campaigns, Current.account)
  end

  def fetch_campaign
    @campaign = Current.account.whatsapp_bulk_campaigns.find(params[:bulk_campaign_id])
  end
end
