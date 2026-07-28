module Api
  module V1
    module Accounts
      module Whatsapp
        class CampaignSettingsController < Api::V1::Accounts::BaseController
          before_action :ensure_feature_enabled

          DEFAULTS = {
            'rate_limit_per_minute' => 10,
            'batch_size' => 20,
            'max_retry_attempts' => 3,
            'send_window_start' => '08:00',
            'send_window_end' => '20:00',
            'send_window_enabled' => false,
            'default_timezone' => 'America/Sao_Paulo'
          }.freeze

          def show
            settings = Current.account.whatsapp_campaign_settings
            render json: { settings: DEFAULTS.merge(settings || {}) }, status: :ok
          end

          def update
            new_settings = params.require(:settings).permit(
              :rate_limit_per_minute, :batch_size, :max_retry_attempts,
              :send_window_enabled, :send_window_start, :send_window_end,
              :default_timezone
            ).to_h.transform_values { |v| v.is_a?(String) ? v.strip : v }

            existing = Current.account.whatsapp_campaign_settings || {}
            Current.account.update!(
              custom_attributes: Current.account.custom_attributes.merge(
                'whatsapp_campaign_settings' => existing.merge(new_settings.stringify_keys)
              )
            )

            render json: { settings: DEFAULTS.merge(existing.merge(new_settings.stringify_keys)) }, status: :ok
          end

          private

          def ensure_feature_enabled
            head :not_found unless Current.account.feature_enabled?('whatsapp_campaign')
          end
        end
      end
    end
  end
end
