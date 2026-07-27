class Api::V1::Accounts::Whatsapp::BulkCampaigns::BulkCampaignRecipientsController < Api::V1::Accounts::BaseController
  before_action :ensure_feature_enabled
  before_action :fetch_campaign

  def index
    @recipients = @campaign.recipients.order(:id)
  end

  def create
    recipients_data = params.require(:recipients)
    inserted = 0
    skipped = 0

    recipients_data.each do |entry|
      key = entry[:recipient_key].to_s.strip
      phone = entry[:phone_number].to_s.strip
      next if key.blank? || phone.blank?

      recipient = @campaign.recipients.find_or_initialize_by(recipient_key: key)
      if recipient.persisted? && recipient.status.in?(%w[sent delivered read])
        skipped += 1
        next
      end

      recipient.assign_attributes(
        account: Current.account,
        phone_number: phone,
        status: :pending,
        template_parameters: (entry[:template_parameters] || {}).transform_values(&:to_s),
        consent_snapshot: entry[:consent_snapshot] || {}
      )
      recipient.save!
      inserted += 1
    end

    render json: { inserted: inserted, skipped: skipped, total: @campaign.recipients.count }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def ensure_feature_enabled
    head :not_found unless ::Feature.enabled?(:whatsapp_campaign, Current.account)
  end

  def fetch_campaign
    @campaign = Current.account.whatsapp_bulk_campaigns.find(params[:bulk_campaign_id])
  end
end
