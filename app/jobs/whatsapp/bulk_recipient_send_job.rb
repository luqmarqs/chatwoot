class Whatsapp::BulkRecipientSendJob < ApplicationJob
  queue_as :high

  def perform(recipient_id)
    recipient = Whatsapp::BulkCampaignRecipient.find_by(id: recipient_id)
    return unless recipient
    return if recipient.sent? || recipient.delivered? || recipient.read?

    Whatsapp::Bulk::RecipientSendService.new(recipient: recipient).perform
  end
end
