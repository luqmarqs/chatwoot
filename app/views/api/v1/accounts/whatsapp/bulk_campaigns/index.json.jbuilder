json.array! @campaigns do |campaign|
  json.partial! 'api/v1/accounts/whatsapp/bulk_campaigns/bulk_campaign', bulk_campaign: campaign
end
