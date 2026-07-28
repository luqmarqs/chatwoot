module Whatsapp
  module Bulk
    class RateLimiterService
      attr_reader :campaign

      # WhatsApp Cloud rate limits (per phone number ID):
      # - Business: 250 messages/second for marketing
      # - Marketing: 250 msgs/sec, daily limit varies by quality
      # We default to conservative rates.
      DEFAULT_PER_MINUTE = 60
      DEFAULT_BATCH_SIZE = 10
      DEFAULT_MAX_RETRIES = 3
      MIN_DELAY_BETWEEN_BATCHES = 2 # seconds

      def initialize(campaign)
        @campaign = campaign
      end

      def throttle
        rpm = campaign.rate_limit_per_minute&.positive? ? campaign.rate_limit_per_minute : DEFAULT_PER_MINUTE
        batch = campaign.batch_size&.positive? ? campaign.batch_size : DEFAULT_BATCH_SIZE
        delay_per_batch = (60.0 / rpm) * batch

        remaining = campaign.recipients.where(status: %w[pending failed])
        return if remaining.none?

        max_retries = campaign.max_retry_attempts&.positive? ? campaign.max_retry_attempts : DEFAULT_MAX_RETRIES

        remaining.find_each.with_index do |recipient, index|
          next if recipient.attempt_count >= max_retries

          Whatsapp::Bulk::RecipientSendService.new(recipient: recipient).perform

          if (index + 1) % batch == 0
            sleep [delay_per_batch, MIN_DELAY_BETWEEN_BATCHES].max
          end
        end
      end

      def within_send_window?
        return true unless campaign.send_window_enabled?

        tz = campaign.send_window_timezone.presence || campaign.timezone
        now = Time.current.in_time_zone(tz)
        current_minutes = now.hour * 60 + now.min

        start_minutes = parse_time_string(campaign.send_window_start)
        end_minutes = parse_time_string(campaign.send_window_end)

        return true if start_minutes.nil? || end_minutes.nil?

        current_minutes >= start_minutes && current_minutes < end_minutes
      end

      private

      def parse_time_string(str)
        parts = str.to_s.split(':')
        return nil if parts.length != 2

        hours = parts[0].to_i
        minutes = parts[1].to_i
        hours * 60 + minutes
      end
    end
  end
end
