class Api::V1::Accounts::Whatsapp::BulkCampaignsController < Api::V1::Accounts::BaseController
  require 'csv'

  before_action :ensure_feature_enabled
  before_action :fetch_campaign, except: [:index, :create, :audience_preview]
  before_action :check_authorization

  def index
    @campaigns = Current.account.whatsapp_bulk_campaigns
                        .includes(:recipients)
                        .order(created_at: :desc)
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

  def pause
    @campaign.pause!
    head :ok
  end

  def resume
    @campaign.resume!
    head :ok
  end

  def cancel
    @campaign.cancel!
    head :ok
  end

  def export_csv
    recipients = @campaign.recipients.order(:id)
    csv = CSV.generate(headers: true) do |rows|
      rows << ['Phone', 'Name', 'Status', 'Attempts', 'Sent At', 'Delivered At', 'Read At', 'Replied At', 'Failed At', 'Error Code', 'Failure Message', 'Provider Message ID']
      recipients.find_each do |r|
        rows << [
          r.phone_number,
          r.consent_snapshot&.dig('original_name') || r.recipient_key,
          r.status,
          r.attempts_count || 0,
          r.sent_at,
          r.delivered_at,
          r.read_at,
          r.replied_at,
          r.failed_at,
          r.error_code,
          r.failure_message,
          r.provider_message_id
        ]
      end
    end

    send_data csv, filename: "campaign_#{@campaign.id}_recipients.csv", type: 'text/csv'
  end

  def request_export
    Whatsapp::Bulk::ExportJob.perform_later(@campaign.id)
    render json: { message: 'Export enqueued. It will be available shortly.' }, status: :accepted
  end

  def download_export
    export = @campaign.metadata&.dig('export')
    unless export && File.exist?(export['path'].to_s)
      render json: { error: 'No export available. Request one first via POST /export.' }, status: :not_found
      return
    end

    if Time.parse(export['expires_at']) < Time.current
      render json: { error: 'Export has expired. Request a new one.' }, status: :gone
      return
    end

    send_file export['path'], filename: export['filename'], type: 'text/csv'
  end

  def audience_preview
    definition = params.permit(audience_definition: {})[:audience_definition] || {}
    service = Whatsapp::Bulk::AudienceSnapshotService.new(
      account: Current.account,
      audience_definition: definition
    )
    preview = service.perform
    render json: { audience: preview }, status: :ok
  end

  def import_recipients
    file = params[:file]
    unless file
      render json: { error: 'No CSV file provided' }, status: :unprocessable_entity
      return
    end

    validation_error = Whatsapp::Bulk::CsvImportService.validate_file(file)
    if validation_error
      render json: validation_error, status: validation_error[:status]
      return
    end

    result = Whatsapp::Bulk::CsvImportService.new(
      campaign: @campaign,
      csv_content: file.read,
      account: Current.account,
      file: file
    ).perform

    render json: { imported: result[:imported], skipped: result[:skipped], errors: result[:errors] }, status: :ok
  end

  def import_errors_csv
    file = params[:file]
    unless file
      render json: { error: 'No CSV file provided' }, status: :unprocessable_entity
      return
    end

    validation_error = Whatsapp::Bulk::CsvImportService.validate_file(file)
    if validation_error
      render json: validation_error, status: validation_error[:status]
      return
    end

    result = Whatsapp::Bulk::CsvImportService.new(
      campaign: @campaign,
      csv_content: file.read,
      account: Current.account
    ).perform

    if result[:errors].empty?
      render json: { message: 'No errors found' }, status: :ok
      return
    end

    csv = CSV.generate(headers: true) do |rows|
      rows << ['Row', 'Error']
      result[:errors].each do |err|
        rows << [err[:row], err[:error]]
      end
    end

    send_data csv, filename: "campaign_#{@campaign.id}_import_errors.csv", type: 'text/csv'
  end

  private

  def ensure_feature_enabled
    head :not_found unless Current.account.feature_enabled?('whatsapp_campaign')
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
      :provider_template_namespace, :provider_template_language, :provider_template_category,
      :scheduled_at, :rate_limit_per_minute, :batch_size, :max_retry_attempts,
      :send_window_enabled, :send_window_start, :send_window_end, :send_window_timezone,
      template_snapshot: {}, variable_mapping: {}, audience_definition: {},
      consent_confirmation: {}, metadata: {}
    )
  end
end
