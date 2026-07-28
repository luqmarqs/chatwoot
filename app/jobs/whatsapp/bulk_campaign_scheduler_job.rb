class Whatsapp::BulkCampaignSchedulerJob < ApplicationJob
  queue_as :low

  def perform
    scheduled_campaigns.find_each do |campaign|
      next unless campaign.scheduled?
      next if campaign.scheduled_at.nil? || campaign.scheduled_at > Time.current
      next unless send_window_open?(campaign)

      campaign.running!
      Whatsapp::BulkCampaignSendJob.perform_later(campaign.id)
    end
  end

  private

  def scheduled_campaigns
    Whatsapp::BulkCampaign.where(status: :scheduled)
                          .where('scheduled_at <= ?', Time.current)
  end

  def send_window_open?(campaign)
    Whatsapp::Bulk::RateLimiterService.new(campaign).within_send_window?
  end
end
