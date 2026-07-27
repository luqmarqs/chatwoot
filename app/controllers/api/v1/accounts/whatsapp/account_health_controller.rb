class Api::V1::Accounts::Whatsapp::AccountHealthController < Api::V1::Accounts::BaseController
  before_action :ensure_feature_enabled

  def show
    service = Whatsapp::Bulk::AccountHealthService.new(account: Current.account)
    render json: { inboxes: service.perform }, status: :ok
  end

  private

  def ensure_feature_enabled
    head :not_found unless Current.account.feature_enabled?('whatsapp_bulk_campaigns')
  end
end
