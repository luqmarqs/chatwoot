class Whatsapp::BulkCampaignSendJob < ApplicationJob
  queue_as :high

  def perform(campaign_id)
    campaign = Whatsapp::BulkCampaign.find_by(id: campaign_id)
    return unless campaign
    return unless campaign.draft? || campaign.validating? || campaign.scheduled?

    campaign.running!

    Whatsapp::Bulk::CampaignSendService.new(campaign: campaign).perform
  rescue StandardError => e
    Rails.logger.error "BulkCampaignSendJob ##{campaign_id} failed: #{e.message}"
    campaign&.failed!
    raise e
  end
end
