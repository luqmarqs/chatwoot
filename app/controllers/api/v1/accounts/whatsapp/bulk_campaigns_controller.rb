class Api::V1::Accounts::Whatsapp::BulkCampaignsController < Api::V1::Accounts::BaseController
  before_action :ensure_feature_enabled
  before_action :fetch_campaign, except: [:index, :create]
  before_action :check_authorization

  def index
    @campaigns = Current.account.whatsapp_bulk_campaigns.order(created_at: :desc)
  end

  def show; end

  def create
    @campaign = Current.account.whatsapp_bulk_campaigns.create!(campaign_params.merge(created_by: Current.user, updated_by: Current.user))
  end

  def update
    @campaign.update!(campaign_params.merge(updated_by: Current.user))
  end

  def destroy
    @campaign.destroy!
    head :ok
  end

  def send_campaign
    @campaign.validate! if @campaign.draft?
    Whatsapp::BulkCampaignSendJob.perform_later(@campaign.id)
    head :accepted
  end

  private

  def ensure_feature_enabled
    head :not_found unless Current.account.feature_enabled?('whatsapp_bulk_campaigns')
  end

  def fetch_campaign
    @campaign = Current.account.whatsapp_bulk_campaigns.find(params[:id])
  end

  def check_authorization
    authorize(@campaign || ::Whatsapp::BulkCampaign)
  end

  def campaign_params
    params.require(:campaign).permit(
      :name, :description, :inbox_id, :timezone, :provider_template_name,
      :provider_template_language, :provider_template_category, :scheduled_at,
      :rate_limit_per_minute, :batch_size, :max_retry_attempts, :send_window_enabled,
      :send_window_start, :send_window_end, :send_window_timezone,
      template_snapshot: {}, variable_mapping: {}, audience_definition: {},
      consent_confirmation: {}, metadata: {}
    )
  end
end
