class Api::V1::Accounts::Whatsapp::BulkTemplatesController < Api::V1::Accounts::BaseController
  before_action :ensure_feature_enabled
  before_action :fetch_template, except: [:index, :create, :sync_from_provider]
  before_action :check_authorization

  def index
    @templates = Current.account.whatsapp_bulk_templates
                       .order(updated_at: :desc)
  end

  def show; end

  def create
    @template = Current.account.whatsapp_bulk_templates.create!(
      template_params.merge(created_by: Current.user, updated_by: Current.user)
    )
  end

  def update
    @template.update!(template_params.merge(updated_by: Current.user))
  end

  def destroy
    @template.destroy!
    head :ok
  end

  def sync_from_provider
    templates = Whatsapp::Bulk::TemplateSyncService.new(account: Current.account).perform
    render json: { templates: templates }, status: :ok
  end

  private

  def ensure_feature_enabled
    head :not_found unless Current.account.feature_enabled?('whatsapp_bulk_campaigns')
  end

  def fetch_template
    @template = Current.account.whatsapp_bulk_templates.find(params[:id])
  end

  def check_authorization
    authorize(@template || ::Whatsapp::BulkTemplate)
  end

  def template_params
    params.require(:template).permit(
      :name, :provider_template_id, :provider_template_name,
      :provider_template_namespace, :language, :category, :status,
      :header_text, :body_text, :footer_text,
      :approved_at, :rejected_reason,
      components: [], content_snapshot: {}, button_labels: [], metadata: {}
    )
  end
end
