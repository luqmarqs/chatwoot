class Whatsapp::Bulk::ReconcileStatsJob < ApplicationJob
  queue_as :low

  def perform(campaign_id)
    campaign = Whatsapp::BulkCampaign.find_by(id: campaign_id)
    return unless campaign

    stats = campaign.recipients.group(:status).count

    campaign.update_columns(
      total_recipients: stats.values.sum,
      pending_count: stats['pending'] || 0,
      queued_count: stats['queued'] || 0,
      processing_count: stats['processing'] || 0,
      sent_count: stats['sent'] || 0,
      delivered_count: stats['delivered'] || 0,
      read_count: stats['read'] || 0,
      replied_count: stats['replied'] || 0,
      failed_count: stats['failed'] || 0,
      skipped_count: stats['skipped'] || 0,
      cancelled_count: stats['cancelled'] || 0,
      succeeded_count: (stats['sent'] || 0) + (stats['delivered'] || 0) + (stats['read'] || 0) + (stats['replied'] || 0)
    )
  end
end
