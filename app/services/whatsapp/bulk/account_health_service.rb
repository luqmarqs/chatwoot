module Whatsapp
  module Bulk
    class AccountHealthService
      pattr_initialize [:account!]

      def perform
        inboxes = account.inboxes.joins(:channel)
                         .where(channel: { type: 'Channel::Whatsapp' })
                         .where("channel->>'provider' = ?", 'whatsapp_cloud')

        inboxes.map do |inbox|
          channel = inbox.channel
          health = fetch_health(channel)
          {
            inbox_id: inbox.id,
            inbox_name: inbox.name,
            phone_number: channel.phone_number,
            phone_number_id: channel.provider_config&.dig('phone_number_id'),
            quality_rating: health[:quality_rating],
            status: health[:status],
            message_limit: health[:message_limit],
            last_checked: Time.current.iso8601
          }
        end
      end

      private

      def fetch_health(channel)
        access_token = channel.provider_config&.dig('api_key')
        phone_id = channel.provider_config&.dig('phone_number_id')
        return {} if access_token.blank? || phone_id.blank?

        client = Whatsapp::FacebookApiClient.new(access_token)
        response = client.debug_token(access_token)
        {
          quality_rating: 'UNKNOWN',
          status: response&.dig('data', 'is_valid') ? 'CONNECTED' : 'ERROR',
          message_limit: nil
        }
      rescue StandardError => e
        Rails.logger.error "AccountHealthService: #{e.message}"
        { quality_rating: 'UNKNOWN', status: 'ERROR', message_limit: nil }
      end
    end
  end
end
